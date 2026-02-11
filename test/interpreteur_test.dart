import 'package:flutter_test/flutter_test.dart';
import 'package:pseudo_code/interpreteur/interpreteur.dart';
import 'package:pseudo_code/providers/debug_provider.dart';

void main() {
  group('Interpreteur - Base', () {
    late DebugProvider debugProvider;
    late List<String> output;

    setUp(() {
      debugProvider = DebugProvider();
      output = [];
    });

    test('Calcul simple et affichage', () async {
      const code = '''
Algorithme Test
Variables
  x : entier
Début
  x <- 10 + 5 * 2
  Ecrire(x)
Fin
''';
      await Interpreteur.executer(
        code,
        provider: debugProvider,
        onInput: () async => "",
        onOutput: (text) => output.add(text),
      );

      expect(output, contains('20'));
    });

    test('Conditions Si/Sinon', () async {
      const code = '''
Algorithme TestSi
Variables
  age : entier
Début
  age <- 18
  Si age >= 18 Alors
    Ecrire("Majeur")
  Sinon
    Ecrire("Mineur")
  FinSi
Fin
''';
      await Interpreteur.executer(
        code,
        provider: debugProvider,
        onInput: () async => "",
        onOutput: (text) => output.add(text),
      );

      expect(output, contains('Majeur'));
    });
  });

  group('Interpreteur - Boucles', () {
    late DebugProvider debugProvider;
    late List<String> output;

    setUp(() {
      debugProvider = DebugProvider();
      output = [];
    });

    test('Boucle Pour', () async {
      const code = '''
Algorithme TestPour
Variables
  i : entier
Début
  Pour i de 1 à 3 faire
    Ecrire(i)
  FinPour
Fin
''';
      await Interpreteur.executer(
        code,
        provider: debugProvider,
        onInput: () async => "",
        onOutput: (text) => output.add(text),
      );

      expect(output, equals(['1', '2', '3']));
    });

    test('Boucle TantQue', () async {
      const code = '''
Algorithme TestTantQue
Variables
  i : entier
Début
  i <- 1
  TantQue i <= 3 faire
    Ecrire(i)
    i <- i + 1
  FinTantQue
Fin
''';
      await Interpreteur.executer(
        code,
        provider: debugProvider,
        onInput: () async => "",
        onOutput: (text) => output.add(text),
      );

      expect(output, equals(['1', '2', '3']));
    });
  });

  group('Interpreteur - Sous-programmes', () {
    late DebugProvider debugProvider;
    late List<String> output;

    setUp(() {
      debugProvider = DebugProvider();
      output = [];
    });

    test('Fonction simple', () async {
      const code = '''
Algorithme TestFonction

Fonction Carre(n : entier) : entier
Début
  Retourner n * n
FinFonction

Variables
  res : entier
Début
  res <- Carre(5)
  Ecrire(res)
Fin
''';
      await Interpreteur.executer(
        code,
        provider: debugProvider,
        onInput: () async => "",
        onOutput: (text) => output.add(text),
      );

      expect(output, contains('25'));
    });
  });
}
