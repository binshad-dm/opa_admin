import '../entities/field_definition_entity.dart';

class PolicyValidators {
  static final RegExp _fieldPathRegex = RegExp(
    r'^[a-zA-Z_][a-zA-Z0-9_]*(\.[a-zA-Z_][a-zA-Z0-9_]*)*$',
  );

  static const Set<String> numericFieldTypes = {
    'NUMBER',
    'INTEGER',
    'INT',
    'DECIMAL',
    'LONG',
    'FLOAT',
    'DOUBLE',
    'BIGDECIMAL',
  };

  /// Checks if a field is numeric based on its entity definition or field name (e.g. contains 'age').
  static bool isNumericField(
    FieldDefinitionEntity? field, [
    String? fallbackFieldName,
  ]) {
    final name = (field?.fieldName ?? fallbackFieldName ?? '').toLowerCase();
    final display = (field?.displayName ?? '').toLowerCase();
    if (name.contains('age') || display.contains('age')) {
      return true;
    }
    final type = field?.fieldType.toUpperCase().trim() ?? '';
    return numericFieldTypes.contains(type);
  }

  /// Checks if a field is boolean.
  static bool isBooleanField(FieldDefinitionEntity? field) {
    final type = field?.fieldType.toUpperCase().trim() ?? '';
    return type == 'BOOLEAN' || type == 'BOOL';
  }

  /// Returns allowed comparison operators for the field based on its type:
  /// - Boolean: ['==', '!=']
  /// - Numeric: ['==', '!=', '<=', '>=', '<', '>', 'in', 'not_in'] (no 'contains')
  /// - String / other: ['==', '!=', 'contains', 'in', 'not_in'] (no '<', '<=', '>', '>=')
  static List<String> getAllowedOperators(
    FieldDefinitionEntity? field, [
    String? fallbackFieldName,
  ]) {
    if (isBooleanField(field)) {
      return const ['==', '!='];
    }
    if (isNumericField(field, fallbackFieldName)) {
      return const ['==', '!=', '<=', '>=', '<', '>', 'in', 'not_in'];
    }
    // String & default
    return const ['==', '!=', 'contains', 'in', 'not_in'];
  }

  /// Returns allowed value types for the field:
  /// - Numeric: ['VALUE', 'FIELD', 'FIELD_LIST', 'MATH_EXPRESSION']
  /// - Boolean: ['VALUE', 'FIELD']
  /// - String / other: ['VALUE', 'FIELD', 'FIELD_LIST'] (no 'MATH_EXPRESSION')
  static List<MapEntry<String, String>> getAllowedValueTypes(
    FieldDefinitionEntity? field, [
    String? fallbackFieldName,
  ]) {
    if (isNumericField(field, fallbackFieldName)) {
      return const [
        MapEntry('VALUE', 'Static Value'),
        MapEntry('FIELD', 'Field Comparison'),
        MapEntry('FIELD_LIST', 'Field List'),
        MapEntry('MATH_EXPRESSION', 'Math Expression'),
      ];
    }
    if (isBooleanField(field)) {
      return const [
        MapEntry('VALUE', 'Static Value'),
        MapEntry('FIELD', 'Field Comparison'),
      ];
    }
    return const [
      MapEntry('VALUE', 'Static Value'),
      MapEntry('FIELD', 'Field Comparison'),
      MapEntry('FIELD_LIST', 'Field List'),
    ];
  }

  /// Validates whether an operator is permitted for a given field type.
  static String? validateRuleOperator(
    String operator,
    FieldDefinitionEntity? field, [
    String? fallbackFieldName,
  ]) {
    final allowed = getAllowedOperators(field, fallbackFieldName);
    if (!allowed.contains(operator)) {
      final displayName = field?.displayName ?? fallbackFieldName ?? 'Field';
      if (isBooleanField(field)) {
        return 'Operator "$operator" is not supported for boolean field "$displayName".';
      } else if (isNumericField(field, fallbackFieldName)) {
        return 'Operator "$operator" is not supported for numeric field "$displayName".';
      } else {
        return 'Operator "$operator" is not supported for string field "$displayName".';
      }
    }
    return null;
  }

  /// Validates whether a value type is permitted for a given field type.
  static String? validateRuleValueType(
    String valueType,
    FieldDefinitionEntity? field, [
    String? fallbackFieldName,
  ]) {
    final allowed = getAllowedValueTypes(field, fallbackFieldName);
    if (!allowed.any((e) => e.key == valueType)) {
      final displayName = field?.displayName ?? fallbackFieldName ?? 'Field';
      if (valueType == 'MATH_EXPRESSION') {
        return 'Math expression is only supported for numeric fields.';
      }
      return 'Value type "$valueType" is not supported for field "$displayName".';
    }
    return null;
  }

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
  static String? validateArrayValues(
    String? value, {
    bool isNumeric = false,
    bool isAge = false,
  }) {
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

    if (isAge) {
      for (final item in items) {
        final ageErr = validateAge(item, 'All age values');
        if (ageErr != null) return ageErr;
      }
    } else if (isNumeric) {
      for (final item in items) {
        if (num.tryParse(item) == null) {
          return 'All values must be valid numbers (e.g. 10, 20)';
        }
      }
    }
    return null;
  }

  /// Validates age inputs (positive whole numbers / integers, no negatives, no decimals).
  static String? validateAge(String? value, [String fieldName = 'Age']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName value is required';
    }
    final trimmed = value.trim();
    if (trimmed.startsWith('-') || trimmed.contains('-')) {
      return '$fieldName cannot be negative';
    }
    if (trimmed.contains('.')) {
      return '$fieldName cannot contain decimals';
    }
    final parsed = int.tryParse(trimmed);
    if (parsed == null || parsed < 0) {
      return '$fieldName must be a valid non-negative whole number';
    }
    return null;
  }

  /// Validates numeric inputs.
  static String? validateNumber(
    String? value, [
    String fieldName = 'Number',
    bool allowNegative = true,
    bool allowDecimal = true,
  ]) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName value is required';
    }
    final trimmed = value.trim();
    if (!allowNegative && (trimmed.startsWith('-') || trimmed.contains('-'))) {
      return '$fieldName cannot be negative';
    }
    if (!allowDecimal && trimmed.contains('.')) {
      return '$fieldName cannot contain decimals';
    }
    if (num.tryParse(trimmed) == null) {
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
