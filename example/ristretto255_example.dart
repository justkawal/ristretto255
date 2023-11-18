import 'dart:convert';
import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:cryptography/dart.dart';
import 'package:ristretto255/ristretto255.dart';

void main() {
  final inputs = <String>[
    'Ristretto is traditionally a short shot of espresso coffee',
    'made with the normal amount of ground coffee but extracted with',
    'about half the amount of water in the same amount of time',
    'by using a finer grind.',
    'This produces a concentrated shot of coffee per volume.',
    'Just pulling a normal shot short will produce a weaker shot',
    'and is not a Ristretto as some believe.',
  ];
  final results = <String>[
    '3066f82a1a747d45120d1740f14358531a8f04bbffe6a819f86dfe50f44a0a46',
    'f26e5b6f7d362d2d2a94c5d0e7602cb4773c95a2e5c31a64f133189fa76ed61b',
    '006ccd2a9e6867e6a2c5cea83d3302cc9de128dd2a9a57dd8ee7b9d7ffe02826',
    'f8f0c87cf237953c5890aec3998169005dae3eca1fbb04548c635953c817f92a',
    'ae81e7dedf20a497e10c304a765c1767a42d6e06029758d2d7e8ef7cc4c41179',
    'e2705652ff9f5e44d3e841bf1c251cf7dddb77d140870d1ab2ed64f1a9ce8628',
    '80bd07262511cdde4863f8a7434cef696750681cb9510eea557088f76d9e5065',
  ];

  for (int i = 0; i < inputs.length; i++) {
    final bytes = utf8.encode(inputs[i]);

    final hashedBytes = const DartSha512().hashSync(bytes).bytes;

    final Element element = Element.newElement();
    element.fromUniformBytes(Uint8List.fromList(hashedBytes));

    final encoding = hex.encode(element.encode());
    assert(encoding == results[i]);
  }
}
