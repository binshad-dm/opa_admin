class PolicyValidators {
  static final RegExp _fieldPathRegex = RegExp(
    r'^[a-zA-Z_][a-zA-Z0-9_]*(\.[a-zA-Z_][a-zA-Z0-9_]*)*$',
  );

  /// Validates that a string value is not empty or pure whitespace.
  static String? validateRequired(String? value, [String fieldName = 'Value']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates dot-separated field paths like `user.location` or `resource.department`.
  static String? validateFieldPath(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Field path is required';
    }
    final trimmed = value.trim();
    if (!_fieldPathRegex.hasMatch(trimmed)) {
      return 'Enter a valid field path (e.g. user.department)';
    }
    return null;
  }

  /// Validates comma-separated array items for `in` and `not_in` comparisons.
  static String? validateArrayValues(String? value, {bool isNumeric = false}) {
    if (value == null || value.trim().isEmpty) {
      return 'At least one value is required';
    }
    final items = value
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (items.isEmpty) {
      return 'At least one non-empty value is required';
    }

    if (isNumeric) {
      for (final item in items) {
        if (num.tryParse(item) == null) {
          return 'All values must be valid numbers (e.g. 10, 20)';
        }
      }
    }
    return null;
  }

  /// Validates numeric inputs.
  static String? validateNumber(String? value, [String fieldName = 'Number']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName value is required';
    }
    if (num.tryParse(value.trim()) == null) {
      return 'Enter a valid number';
    }
    return null;
  }

  /// Validates custom Rego code snippets for non-emptiness and balanced brackets/quotes.
  static String? validateRegoSnippet(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Rego code snippet is required';
    }

    final trimmed = value.trim();
    final stack = <String>[];
    bool inQuote = false;
    bool isEscaped = false;

    for (int i = 0; i < trimmed.length; i++) {
      final char = trimmed[i];

      if (isEscaped) {
        isEscaped = false;
        continue;
      }

      if (char == r'\') {
        isEscaped = true;
        continue;
      }

      if (char == '"') {
        inQuote = !inQuote;
        continue;
      }

      // Ignore bracket matching within string literals
      if (inQuote) continue;

      // Ignore single-line comments in Rego starting with #
      if (char == '#') {
        while (i < trimmed.length && trimmed[i] != '\n') {
          i++;
        }
        continue;
      }

      if (char == '{' || char == '[' || char == '(') {
        stack.add(char);
      } else if (char == '}' || char == ']' || char == ')') {
        if (stack.isEmpty) {
          return 'Unexpected closing bracket "$char"';
        }
        final top = stack.removeLast();
        if ((char == '}' && top != '{') ||
            (char == ']' && top != '[') ||
            (char == ')' && top != '(')) {
          return 'Mismatched brackets: expected matching pair for "$top"';
        }
      }
    }

    if (inQuote) {
      return 'Unterminated string literal in Rego snippet';
    }

    if (stack.isNotEmpty) {
      return 'Unclosed bracket "${stack.last}"';
    }

    return null;
  }
}
