// Update-check version logic: parsing tolerant tags and ordering them per
// semver (never as raw strings — "1.0.10" must beat "1.0.9").

import 'package:flutter_test/flutter_test.dart';

import 'package:gang_roll/features/updates/domain/semantic_version.dart';

void main() {
  group('SemanticVersion.tryParse', () {
    test('strips a leading v and parses', () {
      final v = SemanticVersion.tryParse('v1.0.3');
      expect(v, isNotNull);
      expect(v!.major, 1);
      expect(v.minor, 0);
      expect(v.patch, 3);
      expect(v.preRelease, isEmpty);
    });

    test('parses a bare version identically to a v-prefixed one', () {
      expect(SemanticVersion.tryParse('1.0.3'),
          equals(SemanticVersion.tryParse('v1.0.3')));
    });

    test('defaults missing minor/patch to 0', () {
      expect(SemanticVersion.tryParse('2'), equals(const SemanticVersion(2, 0, 0)));
      expect(SemanticVersion.tryParse('2.5'),
          equals(const SemanticVersion(2, 5, 0)));
    });

    test('drops build metadata after +', () {
      expect(SemanticVersion.tryParse('1.0.3+47'),
          equals(const SemanticVersion(1, 0, 3)));
    });

    test('captures pre-release identifiers', () {
      final v = SemanticVersion.tryParse('1.2.0-beta.1');
      expect(v!.preRelease, ['beta', '1']);
      expect(v.normalized, '1.2.0-beta.1');
    });

    test('returns null for non-versions / empty', () {
      expect(SemanticVersion.tryParse('latest'), isNull);
      expect(SemanticVersion.tryParse(''), isNull);
      expect(SemanticVersion.tryParse('   '), isNull);
      expect(SemanticVersion.tryParse(null), isNull);
      expect(SemanticVersion.tryParse('v.x.y'), isNull);
    });
  });

  group('SemanticVersion ordering', () {
    SemanticVersion p(String s) => SemanticVersion.tryParse(s)!;

    test('numeric, not lexical, patch comparison', () {
      expect(p('1.0.10') > p('1.0.9'), isTrue);
    });

    test('minor and major dominate', () {
      expect(p('1.2.0') > p('1.1.99'), isTrue);
      expect(p('2.0.0') > p('1.99.99'), isTrue);
    });

    test('equal versions compare equal regardless of v-prefix', () {
      expect(p('v1.0.0').compareTo(p('1.0.0')), 0);
      expect(p('1.0.0') <= p('1.0.0'), isTrue);
      expect(p('1.0.0') >= p('1.0.0'), isTrue);
    });

    test('a pre-release ranks below its stable release', () {
      expect(p('1.0.0-rc.1') < p('1.0.0'), isTrue);
      expect(p('1.0.0') > p('1.0.0-rc.1'), isTrue);
    });

    test('pre-release identifiers order numerically then alphabetically', () {
      expect(p('1.0.0-alpha.1') < p('1.0.0-alpha.2'), isTrue);
      expect(p('1.0.0-alpha') < p('1.0.0-beta'), isTrue);
      // A larger identifier set has higher precedence when prefixes match.
      expect(p('1.0.0-alpha') < p('1.0.0-alpha.1'), isTrue);
    });

    test('typical update check: latest release beats installed', () {
      final installed = p('1.0.0');
      final latest = p('v1.0.4');
      expect(latest > installed, isTrue);
    });

    test('same version is NOT treated as an update', () {
      expect(p('v1.0.0') > p('1.0.0'), isFalse);
    });
  });

  group('normalized', () {
    test('is the stable dismissal key (no v, no build metadata)', () {
      expect(SemanticVersion.tryParse('v1.0.3+9')!.normalized, '1.0.3');
    });
  });
}
