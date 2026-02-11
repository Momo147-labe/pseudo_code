import 'dart:math';

class MathService {
  // Arithmétique
  static double arithmetic(double a, double b, String op) {
    switch (op) {
      case '+':
        return a + b;
      case '-':
        return a - b;
      case '*':
        return a * b;
      case '/':
        return b != 0 ? a / b : 0;
      case '%':
        return a % b;
      case '^':
        return pow(a, b).toDouble();
      default:
        return 0;
    }
  }

  static double sqrtValue(double n) => n >= 0 ? sqrt(n) : 0;

  // Factorielle
  static BigInt factorial(int n) {
    if (n < 0) return BigInt.from(0);
    BigInt result = BigInt.from(1);
    for (int i = 1; i <= n; i++) {
      result *= BigInt.from(i);
    }
    return result;
  }

  // PGCD / PPCM
  static int gcd(int a, int b) {
    while (b != 0) {
      int t = b;
      b = a % b;
      a = t;
    }
    return a.abs();
  }

  static int lcm(int a, int b) {
    if (a == 0 || b == 0) return 0;
    return ((a * b) / gcd(a, b)).abs().toInt();
  }

  // Équations Degré 2: ax^2 + bx + c = 0
  static List<String> solveQuadratic(double a, double b, double c) {
    if (a == 0) {
      if (b == 0) return ["Pas de solution"];
      return ["x = ${-c / b}"];
    }
    double delta = b * b - 4 * a * c;
    if (delta > 0) {
      double x1 = (-b + sqrt(delta)) / (2 * a);
      double x2 = (-b - sqrt(delta)) / (2 * a);
      return ["x1 = $x1", "x2 = $x2"];
    } else if (delta == 0) {
      return ["x = ${-b / (2 * a)}"];
    } else {
      return ["Pas de racine réelle (Δ < 0)"];
    }
  }

  // Systèmes 2x2: a1x + b1y = c1, a2x + b2y = c2
  static Map<String, double>? solveSystem2x2(
    double a1,
    double b1,
    double c1,
    double a2,
    double b2,
    double c2,
  ) {
    double det = a1 * b2 - a2 * b1;
    if (det == 0) return null;
    double x = (c1 * b2 - c2 * b1) / det;
    double y = (a1 * c2 - a2 * c1) / det;
    return {"x": x, "y": y};
  }

  // Matrices 2x2: Det
  static double determinant2x2(List<List<double>> m) {
    return m[0][0] * m[1][1] - m[0][1] * m[1][0];
  }

  // Matrices 3x3: Det
  static double determinant3x3(List<List<double>> m) {
    return m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) -
        m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0]) +
        m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0]);
  }

  // Trigonométrie
  static double sinDeg(double deg) => sin(deg * pi / 180);
  static double cosDeg(double deg) => cos(deg * pi / 180);
  static double tanDeg(double deg) => tan(deg * pi / 180);
}
