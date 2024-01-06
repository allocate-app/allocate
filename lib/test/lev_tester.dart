import "package:test/test.dart";

import "../util/strings.dart";

void main() {
  group("Levenshtein Distance Test", () {
    test("kitten, sitting", () {
      expect(levenshteinDistance(s1: "kitten", s2: "sitting"), 3);
    });

    test("Saturday, Sunday", () {
      expect(levenshteinDistance(s1: "Saturday", s2: "Sunday"), 3);
    });

    test("book, back", () {
      expect(levenshteinDistance(s1: "book", s2: "back"), 2);
    });

    test("elephant, relevant", () {
      expect(levenshteinDistance(s1: "elephant", s2: "relevant"), 3);
    });

    test("Google, Facebook", () {
      expect(levenshteinDistance(s1: "Google", s2: "Facebook"), 8);
    });
    test("Google, google", () {
      expect(
          levenshteinDistance(s1: "Google", s2: "google", caseSensitive: true),
          1);
    });

    test("ab, abcd", () {
      expect(levenshteinDistance(s1: "ab", s2: "abcd"), 2);
    });

    test("abcd, ab", () {
      expect(
          levenshteinDistance(
            s1: "abcd",
            s2: "ab",
          ),
          2);
    });
  });
}
