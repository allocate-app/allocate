import 'dart:math';

int levenshteinDistance(
    {required String s1, required String s2, bool caseSensitive = false}) {
  if (!caseSensitive) {
    s1 = s1.toLowerCase();
    s2 = s2.toLowerCase();
  }

  if (s1 == s2) {
    return 0;
  }
  if (s1.isEmpty) {
    return s2.length;
  }
  if (s2.isEmpty) {
    return s1.length;
  }

  List<int> v0 = List.generate(s2.length + 1, (i) => i);
  List<int> v1 = List.filled(s2.length + 1, 0);

  for (int i = 0; i < s1.length; i++) {
    v1[0] = i + 1;
    for (int j = 0; j < s2.length; j++) {
      int deletionCost = v0[j + 1] + 1;
      int insertionCost = v1[j] + 1;

      int substitutionCost = (s1[i] == s2[j]) ? v0[j] : v0[j] + 1;
      v1[j + 1] = min(min(deletionCost, insertionCost), substitutionCost);
    }

    List<int> tmp = v0;
    v0 = v1;
    v1 = tmp;
  }

  return v0[s2.length];
}
