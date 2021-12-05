String truncateFromCenter(String s, int maxLength) {
  if (s.length <= maxLength) return s;
  final start = maxLength ~/ 2;
  final shift = maxLength.isEven ? 1 : 0;
  final end = s.length - start + shift;
  final result = s.replaceRange(start, end, '…');
  return result;
}
