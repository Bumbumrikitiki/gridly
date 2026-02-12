import 'package:flutter/services.dart';

class TechnicalLabelGuard {
  static final RegExp _allowedCharacters = RegExp(
    r"[0-9A-Za-zĄĆĘŁŃÓŚŹŻąćęłńóśźż _\-\./#]",
  );

  static final RegExp _allowedFullValue = RegExp(
    r"^[0-9A-Za-zĄĆĘŁŃÓŚŹŻąćęłńóśźż _\-\./#]+$",
  );

  static final RegExp _emailPattern = RegExp(
    r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}",
  );

  static final RegExp _phonePattern = RegExp(
    r"(?:\+?\d[\d\s\-()]{7,}\d)",
  );

  static final RegExp _peselPattern = RegExp(r"\b\d{11}\b");
  static final RegExp _nipPattern = RegExp(r"\b\d{10}\b");

  static final List<String> _addressKeywords = [
    'ul.',
    'ulica',
    'aleja',
    'al.',
    'os.',
    'lok.',
    'mieszkanie',
  ];

  static String normalize(String value) {
    return value.trim().replaceAll(RegExp(r"\s+"), ' ');
  }

  static List<TextInputFormatter> inputFormatters({int maxLength = 48}) {
    return [
      FilteringTextInputFormatter.allow(_allowedCharacters),
      LengthLimitingTextInputFormatter(maxLength),
    ];
  }

  static String? validateTechnicalLabel(String rawValue) {
    final value = normalize(rawValue);

    if (value.isEmpty) {
      return 'Pole nie może być puste.';
    }

    if (value.length < 3) {
      return 'Wpisz co najmniej 3 znaki.';
    }

    if (!_allowedFullValue.hasMatch(value)) {
      return 'Użyj tylko znaków technicznych (litery, cyfry, -, _, ., /, #).';
    }

    if (_looksLikePersonalData(value)) {
      return 'Wykryto możliwe dane osobowe. Użyj nazwy technicznej.';
    }

    return null;
  }

  static bool _looksLikePersonalData(String value) {
    final normalized = normalize(value);
    final lower = normalized.toLowerCase();

    if (_emailPattern.hasMatch(normalized)) {
      return true;
    }

    if (_phonePattern.hasMatch(normalized)) {
      return true;
    }

    if (_peselPattern.hasMatch(normalized) || _nipPattern.hasMatch(normalized)) {
      return true;
    }

    return _addressKeywords.any(lower.contains);
  }
}
