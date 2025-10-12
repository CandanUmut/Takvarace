class Validators {
  static bool isValidAlias(String alias) {
    final regex = RegExp('^[A-Za-z0-9_]{3,24}\\$');
    return regex.hasMatch(alias);
  }
}
