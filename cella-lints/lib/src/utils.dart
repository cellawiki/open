extension Brackets on String {
  bool get hasParenthesis => startsWith('(') && endsWith(')');

  String get removeParenthesis {
    int start = 0;
    int end = length;
    if (startsWith('(')) start++;
    if (endsWith(')')) end--;
    return substring(start, end);
  }
}
