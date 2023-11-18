part of ristretto255;

class Element {
  edwards25519.Point r = edwards25519.Point.zero();

  Element._();

  // NewElement returns a new Element set to the identity value.
  //
  // Deprecated: use NewIdentityElement. This API will be removed before v1.0.0.
  factory Element.newElement() {
    return Element.newIdentityElement();
  }

  // NewIdentityElement returns a new Element set to the identity value.
  factory Element.newIdentityElement() {
    final e = Element._();
    e.r.set(edwards25519.Point.newIdentityPoint());
    return e;
  }

  // NewGeneratorElement returns a new Element set to the canonical generator.
  factory Element.newGeneratorElement() {
    final e = Element._();
    e.r.set(edwards25519.Point.newGeneratorPoint());
    return e;
  }

  // Set sets the value of this to x
  void set(Element x) {
    r.set(x.r);
  }

  // Equal returns 1 if e is equivalent to ee, and 0 otherwise.
  //
  // Note that Elements must not be compared in any other way.
  int equal(Element ee) {
    var (X1, Y1, _, _) = r.ExtendedCoordinates();
    var (X2, Y2, _, _) = ee.r.ExtendedCoordinates();

    edwards25519.Element f0 = edwards25519.Element.feZero()
      ..multiply(X1, Y2); // x1 * y2
    edwards25519.Element f1 = edwards25519.Element.feZero()
      ..multiply(Y1, X2); // y1 * x2

    var out = f0.equal(f1);

    f0.multiply(Y1, Y2); // y1 * y2
    f1.multiply(X1, X2); // x1 * x2
    out = out | f0.equal(f1);

    return out;
  }

  // FromUniformBytes maps the 64-byte slice b to e uniformly and
  // deterministically, and returns e. This can be used for hash-to-group
  // operations or to obtain a random element.
  //
  // Deprecated: use SetUniformBytes. This API will be removed before v1.0.0.
  void fromUniformBytes(Uint8List b) {
    setUniformBytes(b);
  }

  // setUniformBytes deterministically sets e to an uniformly distributed value
  // given 64 uniformly distributed random bytes.
  //
  // This can be used for hash-to-group operations or to obtain a random element.
  void setUniformBytes(Uint8List b) {
    if (b.length != 64) {
      throw Exception(
          "ristretto255: setUniformBytes input is not 64 bytes long");
    }

    final f = edwards25519.Element.feZero();

    f.setBytes(Uint8List.fromList(b.sublist(0, 32)));
    final point1 = Element._();
    mapToPoint(point1.r, f);

    //f.setBytes(b[32:]);
    f.setBytes(Uint8List.fromList(b.sublist(32)));
    final point2 = Element._();
    mapToPoint(point2.r, f);

    add(point1, point2);
  }

  // mapToPoint implements MAP from Section 3.2.4 of draft-hdevalence-cfrg-ristretto-00.
  void mapToPoint(edwards25519.Point out, edwards25519.Element t) {
    // r = SQRT_M1 * t^2
    final r1 = edwards25519.Element.feZero();
    r1.multiply(sqrtM1, r1..square(t));

    // u = (r + 1) * ONE_MINUS_D_SQ
    final u = edwards25519.Element.feZero();
    u.multiply(u..add(r1, one), oneMinusDSQ);

    // c = -1
    final c = edwards25519.Element.feZero();
    c.set(minusOne);

    // v = (c - r*D) * (r + D)
    final rPlusD = edwards25519.Element.feZero();
    rPlusD.add(r1, d);
    final v = edwards25519.Element.feZero();
    v.multiply(v..subtract(c, v..multiply(r1, d)), rPlusD);

    // (was_square, s) = SQRT_RATIO_M1(u, v)
    final s = edwards25519.Element.feZero();
    final (_, wasSquare) = s.sqrtRatio(u, v);

    // s_prime = -CT_ABS(s*t)
    final sPrime = edwards25519.Element.feZero();
    sPrime.negate(sPrime..absolute(sPrime..multiply(s, t)));

    // s = CT_SELECT(s IF was_square ELSE s_prime)
    s.select(s, sPrime, wasSquare);
    // c = CT_SELECT(c IF was_square ELSE r)
    c.select(c, r1, wasSquare);

    // N = c * (r - 1) * D_MINUS_ONE_SQ - v
    final N = edwards25519.Element.feZero();
    N.multiply(c, N..subtract(r1, one));
    N.subtract(N..multiply(N, dMinusOneSQ), v);

    final s2 = edwards25519.Element.feZero();
    s2.square(s);

    // w0 = 2 * s * v
    final w0 = edwards25519.Element.feZero();
    w0.add(w0, w0..multiply(s, v));
    // w1 = N * SQRT_AD_MINUS_ONE
    final w1 = edwards25519.Element.feZero();
    w1.multiply(N, sqrtADMinusOne);
    // w2 = 1 - s^2
    final w2 = edwards25519.Element.feZero();
    w2.subtract(one, s2);
    // w3 = 1 + s^2
    final w3 = edwards25519.Element.feZero();
    w3.add(one, s2);

    // return (w0*w3, w2*w1, w1*w3, w0*w2)
    edwards25519.Element X = edwards25519.Element.feZero()..multiply(w0, w3);
    edwards25519.Element Y = edwards25519.Element.feZero()..multiply(w2, w1);
    edwards25519.Element Z = edwards25519.Element.feZero()..multiply(w1, w3);
    edwards25519.Element T = edwards25519.Element.feZero()..multiply(w0, w2);
    out.setExtendedCoordinates(X, Y, Z, T);
  }

  // Encode appends the 32 bytes canonical encoding of e to b
  // and returns the result.
  List<int> encode([List<int>? bytes]) {
    return Bytes(bytes);
  }

// Bytes returns the 32 bytes canonical encoding of e.
  List<int> Bytes([List<int>? b]) {
    // Bytes is outlined to let the allocation happen on the stack of the caller.
    b ??= List.filled(32, 0);
    bytes(b);
    return b;
  }

  void bytes(List<int> b) {
    final (X, Y, Z, T) = r.ExtendedCoordinates();
    final tmp = edwards25519.Element.feZero();

    // u1 = (z0 + y0) * (z0 - y0)
    final u1 = edwards25519.Element.feZero();
    u1
      ..add(Z, Y)
      ..multiply(u1, tmp..subtract(Z, Y));

    // u2 = x0 * y0
    final u2 = edwards25519.Element.feZero();
    u2.multiply(X, Y);

    // Ignore was_square since this is always square
    // (_, invsqrt) = SQRT_RATIO_M1(1, u1 * u2^2)
    final invSqrt = edwards25519.Element.feZero();
    invSqrt.sqrtRatio(
        one,
        tmp
          ..square(u2)
          ..multiply(tmp, u1));

    // den1 = invsqrt * u1
    // den2 = invsqrt * u2
    final (den1, den2) =
        (edwards25519.Element.feZero(), edwards25519.Element.feZero());
    den1.multiply(invSqrt, u1);
    den2.multiply(invSqrt, u2);
    // z_inv = den1 * den2 * t0
    final zInv = edwards25519.Element.feZero();
    zInv
      ..multiply(den1, den2)
      ..multiply(zInv, T);

    // ix0 = x0 * SQRT_M1
    // iy0 = y0 * SQRT_M1
    final (ix0, iy0) =
        (edwards25519.Element.feZero(), edwards25519.Element.feZero());
    ix0.multiply(X, sqrtM1);
    iy0.multiply(Y, sqrtM1);

    // enchanted_denominator = den1 * INVSQRT_A_MINUS_D
    final enchantedDenominator = edwards25519.Element.feZero();
    enchantedDenominator.multiply(den1, invSqrtAMinusD);

    // rotate = IS_NEGATIVE(t0 * z_inv)
    final rotate = (tmp..multiply(T, zInv)).isNegative();

    // x = CT_SELECT(iy0 IF rotate ELSE x0)
    // y = CT_SELECT(ix0 IF rotate ELSE y0)
    final (x, y) =
        (edwards25519.Element.feZero(), edwards25519.Element.feZero());
    x.select(iy0, X, rotate);
    y.select(ix0, Y, rotate);
    // z = z0
    final z = edwards25519.Element.feZero()..set(Z);
    // den_inv = CT_SELECT(enchanted_denominator IF rotate ELSE den2)
    final denInv = edwards25519.Element.feZero();
    denInv.select(enchantedDenominator, den2, rotate);

    // y = CT_NEG(y, IS_NEGATIVE(x * z_inv))
    final isNegative = (tmp..multiply(x, zInv)).isNegative();
    y.select(tmp..negate(y), y, isNegative);

    // s = CT_ABS(den_inv * (z - y))
    final s = tmp
      ..subtract(z, y)
      ..multiply(tmp, denInv)
      ..absolute(tmp);

    // Return the canonical little-endian encoding of s.
    b.setAll(0, s.Bytes());
  }

  // Decode sets e to the decoded value of in. If in is not a 32 byte canonical
  // encoding, Decode returns an error, and the receiver is unchanged.
  void decode(Uint8List list) {
    setCanonicalBytes(list);
  }

  // SetCanonicalBytes sets e to the decoded value of in. If in is not a canonical
  // encoding of s, SetCanonicalBytes returns nil and an error and the receiver is
  // unchanged.
  void setCanonicalBytes(Uint8List list) {
    if (list.length != 32) {
      throw ArgumentError('ristretto255: invalid element encoding');
    }

    // First, interpret the string as an integer s in little-endian representation.
    final s = edwards25519.Element.feZero();
    s.setBytes(list);

    // If IS_NEGATIVE(s) returns TRUE, decoding fails.
    if (s.isNegative() == 1) {
      throw ArgumentError('ristretto255: invalid element encoding');
    }

    // If the resulting value is >= p, decoding fails.
    if (collection.ListEquality().equals(s.Bytes(), list) == false) {
      throw ArgumentError('ristretto255: invalid element encoding');
    }

    // ss = s^2
    final sSqr = edwards25519.Element.feZero()..square(s);

    // u1 = 1 - ss
    final u1 = edwards25519.Element.feZero()..subtract(one, sSqr);

    // u2 = 1 + ss
    final u2 = edwards25519.Element.feZero()..add(one, sSqr);

    // u2_sqr = u2^2
    final u2Sqr = edwards25519.Element.feZero()..square(u2);

    // v = -(D * u1^2) - u2_sqr
    final v = edwards25519.Element.feZero()..square(u1);
    v
      ..multiply(v, d)
      ..negate(v)
      ..subtract(v, u2Sqr);

    // (was_square, invsqrt) = SQRT_RATIO_M1(1, v * u2_sqr)
    final invSqrt = edwards25519.Element.feZero();
    final (_, wasSquare) = invSqrt.sqrtRatio(
        one, edwards25519.Element.feZero()..multiply(v, u2Sqr));

    // den_x = invsqrt * u2
    // den_y = invsqrt * den_x * v
    final (denX, denY) =
        (edwards25519.Element.feZero(), edwards25519.Element.feZero());
    denX.multiply(invSqrt, u2);
    denY
      ..multiply(invSqrt, denX)
      ..multiply(denY, v);

    // x = CT_ABS(2 * s * den_x)
    // y = u1 * den_y
    // t = x * y
    final edwards25519.Element X = edwards25519.Element.feZero();
    final edwards25519.Element Y = edwards25519.Element.feZero();
    final edwards25519.Element Z = edwards25519.Element.feZero();
    final edwards25519.Element T = edwards25519.Element.feZero();
    X
      ..multiply(two, s)
      ..multiply(X, denX)
      ..absolute(X);
    Y.multiply(u1, denY);
    Z.one();
    T.multiply(X, Y);

    // If was_square is FALSE, or IS_NEGATIVE(t) returns TRUE, or y = 0, decoding fails.
    if (wasSquare == 0 || T.isNegative() == 1 || Y.equal(zeroRistretto) == 1) {
      throw ArgumentError('ristretto255: invalid element encoding');
    }

    // Otherwise, return the internal representation in extended coordinates (x, y, 1, t).
    r.setExtendedCoordinates(X, Y, Z, T);
  }

  // ScalarBaseMult sets e = s * B, where B is the canonical generator, and returns e.
  void scalarBaseMult(Scalar s) {
    r.scalarBaseMult(s.s);
  }

  // ScalarMult sets e = s * p, and returns e.
  void scalarMult(Scalar s, Element p) {
    r.scalarMult(s.s, p.r);
  }

  // MultiScalarMult sets e = sum(s[i] * p[i]), and returns e.
  //
  // Execution time depends only on the lengths of the two slices, which must match.
  void multiScalarMult(List<Scalar> s, List<Element> p) {
    if (p.length != s.length) {
      throw ArgumentError(
          "ristretto255: MultiScalarMult invoked with mismatched slice lengths");
    }

    final points = List<edwards25519.Point>.generate(
        p.length, (_) => edwards25519.Point.zero());
    final scalars = List<edwards25519.Scalar>.generate(
        s.length, (_) => edwards25519.Scalar());

    for (var i = 0; i < s.length; i++) {
      points[i] = p[i].r;
      scalars[i] = s[i].s;
    }
    r.multiScalarMult(scalars, points);
  }

  // VarTimeMultiScalarMult sets e = sum(s[i] * p[i]), and returns e.
  //
  // Execution time depends on the inputs.
  void varTimeMultiScalarMult(List<Scalar> s, List<Element> p) {
    if (p.length != s.length) {
      throw ArgumentError(
          "ristretto255: varTimeMultiScalarMult invoked with mismatched slice lengths");
    }

    final points = List<edwards25519.Point>.generate(
        p.length, (_) => edwards25519.Point.zero());
    final scalars = List<edwards25519.Scalar>.generate(
        s.length, (_) => edwards25519.Scalar());

    for (var i = 0; i < s.length; i++) {
      points[i] = p[i].r;
      scalars[i] = s[i].s;
    }
    r.varTimeMultiScalarMult(scalars, points);
  }

  // VarTimeDoubleScalarBaseMult sets e = a * A + b * B, where B is the canonical
  // generator, and returns e.
  //
  // Execution time depends on the inputs.
  void varTimeDoubleScalarBaseMult(Scalar a, Element A, Scalar b) {
    r.varTimeDoubleScalarBaseMult(a.s, A.r, b.s);
  }

  // Add sets e = p + q, and returns e.
  void add(Element p, Element q) {
    r.add(p.r, q.r);
  }

  // Subtract sets e = p - q, and returns e.
  void subtract(Element p, Element q) {
    r.subtract(p.r, q.r);
  }

  // Negate sets e = -p, and returns e.
  void negate(Element p) {
    r.negate(p.r);
  }

  // Zero sets e to the identity element of the group, and returns e.
  //
  // Deprecated: use NewIdentityElement and Set. This API will be removed before v1.0.0.
  void zero() {
    set(Element.newIdentityElement());
  }

  // Base sets e to the canonical generator specified in
  // draft-hdevalence-cfrg-ristretto-01, Section 3, and returns e.
  //
  // Deprecated: use NewGeneratorElement and Set. This API will be removed before v1.0.0.
  factory Element.base() {
    return Element.newGeneratorElement();
  }

  // MarshalText implements encoding/TextMarshaler interface
  String marshalText() {
    return base64.encode(Bytes());
  }

  // UnmarshalText implements encoding/TextMarshaler interface
  List<int> unmarshalText(String text) {
    final eb = base64.decode(text);
    decode(eb);
    return eb;
  }

  // String implements the Stringer interface
  @override
  String toString() {
    return marshalText();
  }
}
