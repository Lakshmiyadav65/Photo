// 6-letter join code generator.
//
// Excludes ambiguous characters (I/L/O/1/0) to make codes easier to read out
// loud and type. With 26 - 3 = 23 letters + 8 digits we'd still get >10^9
// 6-codes; with letters-only-minus-ambiguous (21 letters), 6^21 ≈ 86M codes.
// Uniqueness is enforced at the Firestore layer via [/codes/{code}] doc
// existence check, not here.

import 'dart:math';

class CodeGenerator {
  CodeGenerator._();

  // Letters only — easier to communicate verbally. Excludes I, L, O.
  static const String _alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ';
  static final _random = Random.secure();

  /// Generates a random 6-letter code from the unambiguous alphabet.
  /// Caller must check Firestore for uniqueness before persisting.
  static String generate({int length = 6}) {
    final buf = StringBuffer();
    for (var i = 0; i < length; i++) {
      buf.write(_alphabet[_random.nextInt(_alphabet.length)]);
    }
    return buf.toString();
  }

  /// True if [code] could be a valid gang.roll join code (right length and
  /// all chars from the allowed alphabet).
  static bool isValidShape(String code) {
    if (code.length != 6) return false;
    for (final c in code.toUpperCase().runes) {
      if (!_alphabet.contains(String.fromCharCode(c))) return false;
    }
    return true;
  }
}
