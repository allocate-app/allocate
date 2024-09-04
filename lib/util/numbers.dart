import "dart:math";

num remap(
        {num x = 0,
        num inMin = 0,
        num inMax = 1,
        num outMin = 0,
        num outMax = 1}) =>
    (outMax - outMin) * (x - inMin) / (inMax - inMin) + outMin;

num lerp({num v0 = 0, num v1 = 1, num t = 0}) => (1 - t) * v0 + t * v1;

num clamp({num x = 0, num ll = 0, num ul = 1}) => (x < ll)
    ? ll
    : (x > ul)
        ? ul
        : x;

// I did not realize dart had a built-in clamp
num smoothstep({num x = 0, num v0 = 0, num v1 = 1}) {
  x = ((x - v0) / (v1 - v0)).clamp(0, 1);
  // x = clamp(x: (x - v0) / (v1 - v0));
  return pow(x, 3) * (3 * x * (2 * x - 5) + 10);
}

// I am borrowing this from the recommended implementation from ISAR.
int fastHash(String string) {
  int hash = 0xcbf29ce484222325;

  int i = 0;
  while (i < string.length) {
    final codeUnit = string.codeUnitAt(i++);
    hash ^= codeUnit >> 8;
    hash *= 0x100000001b3;
    hash ^= codeUnit & 0xFF;
    hash *= 0x100000001b3;
  }

  return hash;
}

int fast32Hash(String string) {
  return fastHash(string).toSigned(32);
}
