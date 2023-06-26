import "dart:math";
/// Utility class to handle remapping and interpolation.
num remap({num x = 0, num inMin = 0, num inMax = 1, num outMin = 0, num outMax = 1}) =>
    x * (outMax - outMin) / (inMax - inMin) + outMin;

num lerp({num v0 = 0, num v1 = 1, num t = 0}) => (1 - t) * v0 + t * v1;

num clamp({num x = 0, num ll = 0, num ul = 1}) => (x < ll) ? ll : (x > ul)? ul : x;

// TODO: check this. The clamping seems off.
num smoothstep({num x = 0, num v0 = 0, num v1 = 1}){
  x = clamp(x: (x - v0)/(v1-v0));
  return pow(x, 3) * (3 * x * (2 * x - 5) + 10);
}