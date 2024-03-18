abstract class StringUtils {
  StringUtils._();

  static bool isEmpty(String? text) {
    return text == null || text.isEmpty || text == "";
  }

  static String capitalize(String text) {
    if (isEmpty(text)) {
      return '';
    }
    return text[0].toUpperCase() + text.substring(1);
  }

  static String hpFormatting(String text) {
    if (isEmpty(text)) {
      return '';
    }
    if (text.length == 11) {
      return text.replaceAllMapped(RegExp(r'^(\d{3})(\d{4})(\d{4})$'), (Match m) => '${m[1]}-${m[2]}-${m[3]}');
    } else {
      return text.replaceAllMapped(RegExp(r'^(\d{3})(\d{3})(\d{4})$'), (Match m) => '${m[1]}-${m[2]}-${m[3]}');
    }
  }
}
