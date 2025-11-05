import 'dart:math';


class SecureRandomGenerator {
  static late Random _random;
  static const String defaultCharset =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#%^&*()';

  static const String alphaNum =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  /// Constructor
  SecureRandomGenerator() {
    _random = Random.secure();
  }

  /// Generate a strong random string.
  static String generateString({required int length, String charset = defaultCharset}) {
    _random = Random.secure();

    String ret = '';

    for (var i = 0; i < length; ++i) {
      int random = _random.nextInt(charset.length);
      ret += charset[random];
    }

    return ret;
  }

  /// Generate a strong random string for deeplinks to Furnaces and Circles.
  static String generateFurnaceLink() {
     
    return generateString(length: 25, charset: alphaNum);
  }

  static String generateFileName() {

    return generateString(length: 20, charset: alphaNum);
  }

  /// Generate a strong random integer.
  static int generateInt({required int max}) {
    _random = Random.secure();

    String slice = '';

    for (var i = 0; i < max; i++) {

      int digit = _random.nextInt(9);

      ///remove leading zeros
      if (i==0 && digit == 0)
        digit +=1;

      slice += digit.toString();
    }

    return int.parse(slice);

  }

  /// Generate a strong random integer.
  int nextInt({required int max}) {
    return _random.nextInt(max);
  }
}

