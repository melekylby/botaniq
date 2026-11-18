/**
 * BotanIQ Analiz Proxy'si — Cloudflare Worker
 *
 * Neden var? Gemini API anahtarı mobil uygulamanın içine gömülürse,
 * uygulamayı indiren herkes anahtarı çıkarıp kullanabilir. Bu küçük
 * sunucu anahtarı gizli tutar: uygulama fotoğrafı buraya gönderir,
 * burası Gemini'ye sorar ve sonucu uygulamaya döndürür.
 *
 * Gerekli ayarlar (Cloudflare panelinde "Variables and Secrets"):
 *   GEMINI_API_KEY  (Secret)  Google AI Studio'dan alınan anahtar
 *   APP_TOKEN       (Secret)  Uygulamayla paylaşılan basit erişim kodu
 *   GEMINI_MODEL    (isteğe bağlı) Varsayılan: gemini-flash-latest
 */

const DEFAULT_MODEL = 'gemini-flash-latest';

// Yaklaşık 3 MB'lık fotoğraf (base64 olarak ~4 milyon karakter).
const MAX_IMAGE_BASE64_LENGTH = 4_000_000;

const ALLOWED_MIME_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'image/heic'];

const PROMPT = `Sen deneyimli bir botanikçi ve bitki sağlığı uzmanısın.
Fotoğraftaki bitkiyi tanımla ve genel sağlık durumunu değerlendir.
Tüm metinleri Türkçe yaz.

Kurallar:
- Fotoğrafta bitki yoksa isPlant=false yap; diğer metin alanlarını boş bırak, listeleri boş ver.
- Emin değilsen confidence değerini düşük ver ve tahmin uydurma.
- commonName için bitkinin Türkiye'de bilinen yaygın adını yaz (yoksa en uygun Türkçe karşılığı).
- Sağlık değerlendirmesinde özellikle şunlara bak: yaprak sararması, yaprak kuruması,
  mantar hastalıkları, zararlı böcek belirtileri, aşırı veya yetersiz sulama, besin eksikliği.
- Belirgin bir sorun görmüyorsan health.status="healthy" ve issues boş liste olsun.
- En fazla 3 olası sorun yaz; en olası olan en başta olsun. likelihood 0 ile 1 arasında.
- careSteps kısa ve uygulanabilir adımlar olsun (en fazla 4 adım).
- warnings: dikkat edilmesi gerekenler (ör. evcil hayvanlar için zehirlilik, ilaç kullanırken eldiven).
- Kesin teşhis dili kullanma; "olası", "muhtemelen" gibi ifadeler kullan.
- Açıklamalar kısa olsun (1-2 cümle).`;

// Gemini'nin cevabı bu yapıda, geçerli JSON olarak vermesini zorunlu kılıyoruz.
const RESPONSE_SCHEMA = {
  type: 'OBJECT',
  properties: {
    isPlant: { type: 'BOOLEAN' },
    commonName: { type: 'STRING' },
    scientificName: { type: 'STRING' },
    confidence: { type: 'NUMBER' },
    description: { type: 'STRING' },
    care: {
      type: 'OBJECT',
      properties: {
        light: { type: 'STRING' },
        water: { type: 'STRING' },
        temperature: { type: 'STRING' },
        humidity: { type: 'STRING' },
      },
      required: ['light', 'water', 'temperature', 'humidity'],
    },
    careTips: { type: 'ARRAY', items: { type: 'STRING' } },
    health: {
      type: 'OBJECT',
      properties: {
        status: { type: 'STRING', enum: ['healthy', 'attention', 'unhealthy'] },
        summary: { type: 'STRING' },
        issues: {
          type: 'ARRAY',
          items: {
            type: 'OBJECT',
            properties: {
              name: { type: 'STRING' },
              likelihood: { type: 'NUMBER' },
              description: { type: 'STRING' },
              careSteps: { type: 'ARRAY', items: { type: 'STRING' } },
            },
            required: ['name', 'likelihood', 'description', 'careSteps'],
          },
        },
        warnings: { type: 'ARRAY', items: { type: 'STRING' } },
      },
      required: ['status', 'summary', 'issues', 'warnings'],
    },
  },
  required: [
    'isPlant', 'commonName', 'scientificName', 'confidence',
    'description', 'care', 'careTips', 'health',
  ],
};

export default {
  async fetch(request, env) {
    const { pathname } = new URL(request.url);

    if (request.method !== 'POST' || pathname !== '/analyze') {
      return json({ error: 'not_found' }, 404);
    }

    // Basit erişim kontrolü: yalnızca APP_TOKEN'ı bilen uygulama kullanabilir.
    if (!env.APP_TOKEN || request.headers.get('X-App-Token') !== env.APP_TOKEN) {
      return json({ error: 'unauthorized' }, 401);
    }

    if (!env.GEMINI_API_KEY) {
      return json({ error: 'server_not_configured' }, 500);
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return json({ error: 'invalid_json' }, 400);
    }

    const image = body?.image;
    const mimeType = body?.mimeType ?? 'image/jpeg';

    if (typeof image !== 'string' || image.length === 0) {
      return json({ error: 'missing_image' }, 400);
    }
    if (image.length > MAX_IMAGE_BASE64_LENGTH) {
      return json({ error: 'image_too_large' }, 413);
    }
    if (!ALLOWED_MIME_TYPES.includes(mimeType)) {
      return json({ error: 'unsupported_image_type' }, 415);
    }

    const model = env.GEMINI_MODEL || DEFAULT_MODEL;
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;

    let geminiResponse;
    try {
      geminiResponse = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': env.GEMINI_API_KEY,
        },
        body: JSON.stringify({
          contents: [
            {
              parts: [
                { inline_data: { mime_type: mimeType, data: image } },
                { text: PROMPT },
              ],
            },
          ],
          generationConfig: {
            responseMimeType: 'application/json',
            responseSchema: RESPONSE_SCHEMA,
            temperature: 0.2, // Daha tutarlı, daha az "yaratıcı" cevaplar.
          },
        }),
      });
    } catch (error) {
      console.log('Gemini erişilemedi:', error);
      return json({ error: 'upstream_unreachable' }, 502);
    }

    if (geminiResponse.status === 429) {
      return json({ error: 'rate_limited' }, 429);
    }
    if (!geminiResponse.ok) {
      console.log('Gemini hatası:', geminiResponse.status, await geminiResponse.text());
      return json({ error: 'upstream_error', status: geminiResponse.status }, 502);
    }

    const data = await geminiResponse.json();
    const text = (data?.candidates?.[0]?.content?.parts ?? [])
      .map((part) => part.text ?? '')
      .join('');

    if (!text) {
      return json({ error: 'empty_response' }, 502);
    }

    try {
      return json(JSON.parse(text), 200);
    } catch {
      console.log('Model geçersiz JSON döndürdü:', text);
      return json({ error: 'invalid_model_output' }, 502);
    }
  },
};

function json(payload, status) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { 'Content-Type': 'application/json; charset=utf-8' },
  });
}
