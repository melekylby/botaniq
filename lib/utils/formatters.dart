/// Tarihi "18.11.2026" biçiminde yazar.
String formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}

/// "az önce", "5 dk önce", "3 sa önce", "2 gün önce" ya da tarih.
String timeAgo(DateTime date, {DateTime? now}) {
  final difference = (now ?? DateTime.now()).difference(date);
  if (difference.inMinutes < 1) return 'az önce';
  if (difference.inMinutes < 60) return '${difference.inMinutes} dk önce';
  if (difference.inHours < 24) return '${difference.inHours} sa önce';
  if (difference.inDays < 7) return '${difference.inDays} gün önce';
  return formatDate(date);
}
