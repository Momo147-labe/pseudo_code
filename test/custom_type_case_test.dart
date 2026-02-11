import 'package:flutter_test/flutter_test.dart';
import 'package:pseudo_code/interpreteur/interpreteur.dart';
import 'package:pseudo_code/providers/debug_provider.dart';

void main() {
  test('Custom type case-sensitivity should be resolved', () async {
    final provider = DebugProvider();
    String output = "";

    const code = '''
Algorithme TestType
type Matrice = tableau[1..2, 1..2] de entier
Variables
  M : Matrice
Début
  M[1, 1] <- 10
  Afficher(M[1, 1])
Fin
''';

    await Interpreteur.executer(
      code,
      provider: provider,
      onInput: () async => "",
      onOutput: (msg) => output += msg,
    );

    expect(output, contains("10"));
    expect(output, isNot(contains("Type inconnu")));
  });
}
