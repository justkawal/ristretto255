import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:edwards25519/edwards25519.dart' as edwards25519;
import 'package:convert/convert.dart';
import 'package:cryptography/dart.dart';
import 'package:ristretto255/ristretto255.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  group('Ristretto255 Test', () {
    test('Test Ristretto Base point Round Trip', () {
      final decodedBasepoint = Element.newElement();
      decodedBasepoint.decode(compressedRistrettoBasepoint);

      final ristrettoBasepoint = Element.base();
      // decodedBasepoint should be equal to the basepoint
      expect(decodedBasepoint.equal(ristrettoBasepoint), 1);

      final roundtripBasepoint = decodedBasepoint.encode();
      // roundtripBasepoint should be equal to the compressed basepoint
      expect(
          ListEquality().equals(
              roundtripBasepoint, compressedRistrettoBasepoint.toList()),
          true);

      final encodedBasepoint = ristrettoBasepoint.encode();
      // encodedBasepoint should be equal to the compressed basepoint
      expect(
          ListEquality()
              .equals(encodedBasepoint, compressedRistrettoBasepoint.toList()),
          true);
    });

    test('Should fail on the bad test vectors', () {
      for (final testVector in failingTestVectors) {
        final badElement = Element.newElement();
        expect(
            () => badElement.decode(Uint8List.fromList(hex.decode(testVector))),
            throwsArgumentError);
      }
    });

    test('Ristretto From UniformBytes Test Vectors', () {
      final inputs = <String>[
        'Ristretto is traditionally a short shot of espresso coffee',
        'made with the normal amount of ground coffee but extracted with',
        'about half the amount of water in the same amount of time',
        'by using a finer grind.',
        'This produces a concentrated shot of coffee per volume.',
        'Just pulling a normal shot short will produce a weaker shot',
        'and is not a Ristretto as some believe.',
      ];
      final elements = <String>[
        '3066f82a1a747d45120d1740f14358531a8f04bbffe6a819f86dfe50f44a0a46',
        'f26e5b6f7d362d2d2a94c5d0e7602cb4773c95a2e5c31a64f133189fa76ed61b',
        '006ccd2a9e6867e6a2c5cea83d3302cc9de128dd2a9a57dd8ee7b9d7ffe02826',
        'f8f0c87cf237953c5890aec3998169005dae3eca1fbb04548c635953c817f92a',
        'ae81e7dedf20a497e10c304a765c1767a42d6e06029758d2d7e8ef7cc4c41179',
        'e2705652ff9f5e44d3e841bf1c251cf7dddb77d140870d1ab2ed64f1a9ce8628',
        '80bd07262511cdde4863f8a7434cef696750681cb9510eea557088f76d9e5065',
      ];

      final Element element = Element.newElement();
      for (int i = 0; i < inputs.length; i++) {
        element.fromUniformBytes(Uint8List.fromList(
            const DartSha512().hashSync(utf8.encode(inputs[i])).bytes));

        final encoding = hex.encode(element.encode());
        expect(encoding, elements[i]);
      }
    });

    test('Equivalent From Uniform Bytes', () {
      final inputs = <String>[
        'edffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff'
            '1200000000000000000000000000000000000000000000000000000000000000',
        'edffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7f'
            'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff',
        '0000000000000000000000000000000000000000000000000000000000000080'
            'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7f',
        '0000000000000000000000000000000000000000000000000000000000000000'
            '1200000000000000000000000000000000000000000000000000000000000080',
      ];
      final expected =
          '304282791023b73128d277bdcb5c7746ef2eac08dde9f2983379cb8e5ef0517f';

      final element = Element.newElement();
      for (int i = 0; i < inputs.length; i++) {
        final h = Uint8List.fromList(hex.decode(inputs[i]));

        element.fromUniformBytes(h);
        final encoding = hex.encode(element.encode());
        expect(encoding, expected);
      }
    });

    test('Marshal and UnMarshal Element', () {
      final x = Element.newElement();
      // generate an arbitrary element
      x.fromUniformBytes(Uint8List.fromList(
          const DartSha512().hashSync(utf8.encode('Hello World')).bytes));

      final text = x.marshalText();
      final y = Element.newElement();
      y.decode(Uint8List.fromList(y.unmarshalText(text)));
      expect(y.equal(x), 1);
    });

    test('Element Set', () {
      final el1 = Element.newIdentityElement();
      final el2 = Element.newGeneratorElement();

      expect(el1.equal(el2), 0);

      el1.set(el2);
      expect(el1.equal(el2), 1);

      el2.add(el2, el2);
      expect(el1.equal(el2), 0);
    });

    test('Scalar Set', () {
      final scOne = Uint8List(32);
      scOne[0] = 0x01;

      final sc1 = Scalar();
      final sc2 = Scalar();

      sc1.setCanonicalBytes(scOne);
      expect(sc1.equal(sc2), 0);

      sc2.set(sc1);
      expect(sc1.equal(sc2), 1);

      sc1.add(sc1, sc1);
      expect(sc1.equal(sc2), 0);
    });
  });
  group('Contant Test:', () {
    test('d', () {
      testConstant(d,
          '37095705934669439343138083508754565189542113879843219016388785533085940283555');
    });
    test('sqrtM1', () {
      testConstant(sqrtM1,
          '19681161376707505956807079304988542015446066515923890162744021073123829784752');
    });
    test('sqrtADMinusOne', () {
      testConstant(sqrtADMinusOne,
          '25063068953384623474111414158702152701244531502492656460079210482610430750235');
    });
    test('invSqrtAMinusD', () {
      testConstant(invSqrtAMinusD,
          '54469307008909316920995813868745141605393597292927456921205312896311721017578');
    });
    test('oneMinusDSQ', () {
      testConstant(oneMinusDSQ,
          '1159843021668779879193775521855586647937357759715417654439879720876111806838');
    });
    test('dMinusOneSQ', () {
      testConstant(dMinusOneSQ,
          '40440834346308536858101042469323190826248399146238708352240133220865137265952');
    });
  });
}

void testConstant(edwards25519.Element f, String decimal) {
  //b, ok := new(big.Int).SetString(decimal, 10);
  final b = BigInt.parse(decimal, radix: 10);
  /* if !ok {
		t.Fatal("invalid decimal")
	} */
  final buf = List<int>.filled(32, 0);
  ListIntExtension(buf).fillBytes(b);

  for (int i = 0; i < (buf.length) / 2; i++) {
    //buf[i], buf[len(buf)-i-1] = buf[len(buf)-i-1], buf[i]
    final temp = buf[i];
    final position = buf.length - i - 1;
    buf[i] = buf[position];
    buf[position] = temp;
  }
  expect(const ListEquality<int>().equals(f.Bytes(), buf), true);
}
