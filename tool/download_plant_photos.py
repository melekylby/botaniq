#!/usr/bin/env python3
"""
Kütüphanedeki bitkilerin fotoğraflarını Wikipedia / Wikimedia Commons'tan indirir.

Kullanım (proje klasöründe):
    python3 tool/download_plant_photos.py

- Fotoğraflar assets/images/plants/<bitki_id>.jpg olarak kaydedilir.
- Yalnızca serbest lisanslı fotoğraflar kullanılır.
- Lisanslar atıf gerektirdiği için fotoğrafçı ve lisans bilgileri
  assets/images/plants/CREDITS.md dosyasına yazılır.
"""

import json
import re
import subprocess
import time
import urllib.parse
from pathlib import Path

USER_AGENT = "BotanIQ-student-project/1.0 (https://github.com/melekylby/botaniq)"
OUTPUT_DIR = Path(__file__).resolve().parent.parent / "assets" / "images" / "plants"
IMAGE_WIDTH = 800

# Bitki id'si → İngilizce Wikipedia makale adı
PLANTS = {
    "pasa_kilici": "Dracaena trifasciata",
    "deve_tabani": "Monstera deliciosa",
    "potos": "Epipremnum aureum",
    "zamia": "Zamioculcas",
    "kaucuk": "Ficus elastica",
    "aloe_vera": "Aloe vera",
    "para_agaci": "Crassula ovata",
    "ekeverya": "Echeveria elegans",
    "altin_fici": "Echinocactus grusonii",
    "orkide": "Phalaenopsis",
    "antoryum": "Anthurium andraeanum",
    "baris_cicegi": "Spathiphyllum wallisii",
    "afrika_menekse": "Saintpaulia ionantha",
    "lavanta": "Lavandula angustifolia",
    "biberiye": "Rosemary",
    "begonvil": "Bougainvillea glabra",
    "sardunya": "Pelargonium × hortorum",
}


def curl(args):
    result = subprocess.run(
        ["curl", "-sSL", "--fail", "-A", USER_AGENT, *args],
        capture_output=True,
        text=True,
        timeout=120,
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or "indirme başarısız")
    return result.stdout


def api(base_url, **params):
    params.update(format="json", formatversion="2")
    return json.loads(curl([base_url + "?" + urllib.parse.urlencode(params)]))


def strip_html(text):
    return re.sub(r"\s+", " ", re.sub(r"<[^>]+>", "", text or "")).strip()


def find_photo(title):
    """Makalenin ana fotoğrafını (serbest lisanslı) bulur."""
    data = api(
        "https://en.wikipedia.org/w/api.php",
        action="query",
        titles=title,
        redirects=1,
        prop="pageimages",
        piprop="name",
    )
    pages = data.get("query", {}).get("pages", [])
    name = pages[0].get("pageimage") if pages else None
    if not name or name.lower().endswith(".svg"):
        return None

    info = api(
        "https://commons.wikimedia.org/w/api.php",
        action="query",
        titles=f"File:{name}",
        prop="imageinfo",
        iiprop="url|extmetadata",
        iiurlwidth=IMAGE_WIDTH,
    )
    file_pages = info.get("query", {}).get("pages", [])
    if not file_pages or "imageinfo" not in file_pages[0]:
        return None

    image = file_pages[0]["imageinfo"][0]
    meta = image.get("extmetadata", {})
    return {
        "url": image.get("thumburl") or image["url"],
        "page": image.get("descriptionurl", ""),
        "artist": strip_html(meta.get("Artist", {}).get("value")) or "Bilinmiyor",
        "license": strip_html(meta.get("LicenseShortName", {}).get("value")) or "Bilinmiyor",
    }


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    credits = []
    missing = []

    for plant_id, title in PLANTS.items():
        target = OUTPUT_DIR / f"{plant_id}.jpg"
        try:
            photo = find_photo(title)
            if photo is None:
                missing.append(plant_id)
                print(f"  -  {plant_id}: uygun fotoğraf bulunamadı")
                continue
            curl(["-o", str(target), photo["url"]])
            credits.append(
                f"| {plant_id}.jpg | {photo['artist']} | {photo['license']} | {photo['page']} |"
            )
            print(f"  ✓  {plant_id}")
        except Exception as error:  # noqa: BLE001
            missing.append(plant_id)
            print(f"  -  {plant_id}: hata ({error})")
        time.sleep(0.5)  # Wikimedia sunucularını yormamak için

    credits_file = OUTPUT_DIR / "CREDITS.md"
    credits_file.write_text(
        "# Fotoğraf Kaynakları\n\n"
        "Bitki fotoğrafları Wikimedia Commons'tan alınmıştır.\n\n"
        "| Dosya | Fotoğrafçı | Lisans | Kaynak |\n"
        "|---|---|---|---|\n" + "\n".join(credits) + "\n",
        encoding="utf-8",
    )

    print(f"\n{len(credits)} fotoğraf indirildi → {OUTPUT_DIR}")
    if missing:
        print("Fotoğrafı bulunamayanlar (yer tutucu görünecek): " + ", ".join(missing))


if __name__ == "__main__":
    main()
