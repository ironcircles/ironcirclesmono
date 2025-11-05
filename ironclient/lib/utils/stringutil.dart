import 'dart:math';

class StringUtil {
// Define a reusable function
  static String generateRandomString(int length) {
    final _random = Random();
    const _availableChars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    final randomString = List.generate(length,
            (index) => _availableChars[_random.nextInt(_availableChars.length)])
        .join();

    return randomString;
  }

  static String substring(int maxLength, String string) {
    if (string.length < maxLength)
      return string;
    else
      return string.substring(0, maxLength - 1);
  }
}
