// ignore_for_file: non_constant_identifier_names

part of ristretto255;

/// A Scalar is an element of the ristretto255 scalar field, as specified in
/// draft-hdevalence-cfrg-ristretto-01, Section 3.4. That is, an integer modulo
///
///     l = 2^252 + 27742317777372353535851937790883648493
///
/// The zero value is a valid zero element.
class Scalar {
  final edwards25519.Scalar s = edwards25519.Scalar();

  /// NewScalar returns a Scalar set to the value 0.
  Scalar();

  /// Set sets the value of s to x and returns s.
  void set(Scalar x) {
    s.copyFrom(x.s);
  }

  /// Add sets s = x + y mod l and returns s.
  void add(Scalar x, Scalar y) {
    s.add(x.s, y.s);
  }

  /// Subtract sets s = x - y mod l and returns s.
  void subtract(Scalar x, Scalar y) {
    s.subtract(x.s, y.s);
  }

  /// Negate sets s = -x mod l and returns s.
  void negate(Scalar x) {
    s.negate(x.s);
  }

  /// Multiply sets s = x * y mod l and returns s.
  void multiply(Scalar x, Scalar y) {
    s.multiply(x.s, y.s);
  }

  /// Invert sets s = 1 / x such that s * x = 1 mod l and returns s.
  ///
  /// If x is 0, the result is undefined.
  void invert(Scalar x) {
    s.Invert(x.s);
  }

  /// FromUniformBytes sets s to an uniformly distributed value given 64 uniformly
  /// distributed random bytes.
  ///
  /// Deprecated: use SetUniformBytes. This API will be removed before v1.0.0.
  void fromUniformBytes(List<int> x) {
    setUniformBytes(x);
  }

  /// SetUniformBytes sets s to an uniformly distributed value given 64 uniformly
  /// distributed random bytes. If x is not of the right length, SetUniformBytes
  /// returns nil and an error, and the receiver is unchanged.
  void setUniformBytes(List<int> x) {
    try {
      s.setUniformBytes(x);
    } catch (_) {
      throw ArgumentError(
          "ristretto255: setUniformBytes input is not 64 bytes long");
    }
  }

  /// Decode sets s = x, where x is a 32 bytes little-endian encoding of s. If x is
  /// not a canonical encoding of s, Decode returns an error and the receiver is
  /// unchanged.
  ///
  /// Deprecated: use SetCanonicalBytes. This API will be removed before v1.0.0.
  void decode(List<int> x) {
    try {
      s.setCanonicalBytes(x);
    } catch (_) {
      rethrow;
    }
  }

  /// SetCanonicalBytes sets s = x, where x is a 32 bytes little-endian encoding of
  /// s. If x is not a canonical encoding of s, SetCanonicalBytes returns nil and
  /// an error and the receiver is unchanged.
  void setCanonicalBytes(List<int> x) {
    try {
      s.setCanonicalBytes(x);
    } catch (error) {
      throw ArgumentError("ristretto255: $error");
    }
  }

  /// Encode and returns the 32 bytes little-endian encoding of s.
  List<int> encode() {
    return s.Bytes();
  }

  /// equal returns 1 if v and u are equal, and 0 otherwise.
  int equal(Scalar u) {
    return s.equal(u.s);
  }

  /// Zero sets s = 0.
  void zero() {
    s.set(edwards25519.Scalar());
  }

  /// MarshalText implements encoding/TextMarshaler interface
  String marshalText() {
    return base64.encode(encode());
  }

  /// UnmarshalText implements encoding/TextMarshaler interface
  List<int> unmarshalText(String text) {
    final sb = base64.decode(text).toList();
    decode(sb);
    return sb;
  }

  /// String implements the Stringer interface
  @override
  String toString() {
    return marshalText();
  }
}
