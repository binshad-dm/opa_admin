import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/design/widgets/app_dropdown_field.dart';
import '../../../../../core/design/widgets/app_text_form_field.dart';
import '../../../domain/entities/condition_tree_entity.dart';
import '../../../domain/entities/field_definition_entity.dart';
import '../../../domain/utils/policy_validators.dart';
import 'dynamic_dropdown_widget.dart';
import 'math_expression_widget.dart';

class ConditionRuleWidget extends StatefulWidget {
  final ConditionRuleEntity rule;
  final List<FieldDefinitionEntity> fields;
  final String permissionCode;
  final ValueChanged<ConditionRuleEntity> onChange;
  final VoidCallback onRemove;

  const ConditionRuleWidget({
    super.key,
    required this.rule,
    required this.fields,
    required this.permissionCode,
    required this.onChange,
    required this.onRemove,
  });

  @override
  State<ConditionRuleWidget> createState() => _ConditionRuleWidgetState();
}

class _ConditionRuleWidgetState extends State<ConditionRuleWidget> {
  late final TextEditingController _textController;
  late final FocusNode _textFocusNode;

  FieldDefinitionEntity? get selectedField {
    try {
      return widget.fields.firstWhere((f) => f.fieldName == widget.rule.field);
    } catch (_) {
      return null;
    }
  }

  bool get isAgeField {
    final name = (selectedField?.fieldName ?? widget.rule.field).toLowerCase();
    final display = (selectedField?.displayName ?? '').toLowerCase();
    return name.contains('age') || display.contains('age');
  }

  List<String> get userFieldSuggestions => const [];

  List<String> get resourceFieldSuggestions => widget.fields
      .map(
        (f) => f.fieldName.startsWith('resource.')
            ? f.fieldName
            : 'resource.${f.fieldName}',
      )
      .toList();

  List<String> get allSuggestions => [
    ...userFieldSuggestions,
    ...resourceFieldSuggestions,
  ];

  String _formatValueForText(dynamic val, [ConditionRuleEntity? currentRule]) {
    final r = currentRule ?? widget.rule;
    if (r.valueType == 'FIELD' || r.valueType == 'FIELD_LIST') {
      return val is String ? val : '';
    }
    if (r.valueType == 'MATH_EXPRESSION') {
      return val?.toString() ?? '';
    }
    final isArray = r.comparison == 'in' || r.comparison == 'not_in';
    if (isArray) {
      if (val is List) {
        return val.join(', ');
      }
      return val?.toString() ?? '';
    }
    return val?.toString() ?? '';
  }

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: _formatValueForText(widget.rule.value),
    );
    _textFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(ConditionRuleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final typeChanged = oldWidget.rule.valueType != widget.rule.valueType;
    final fieldChanged = oldWidget.rule.field != widget.rule.field;
    final compChanged = oldWidget.rule.comparison != widget.rule.comparison;

    if (typeChanged || fieldChanged || compChanged) {
      final newText = _formatValueForText(widget.rule.value);
      if (_textController.text != newText) {
        _textController.text = newText;
        _textController.selection = TextSelection.collapsed(
          offset: newText.length,
        );
      }
    } else {
      final expectedText = _formatValueForText(widget.rule.value);
      if (!_textFocusNode.hasFocus && _textController.text != expectedText) {
        _textController.text = expectedText;
        _textController.selection = TextSelection.collapsed(
          offset: expectedText.length,
        );
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  void _handleValueTypeChange(String? newType) {
    if (newType == null || newType == widget.rule.valueType) return;
    dynamic newVal = '';
    final isArray =
        widget.rule.comparison == 'in' || widget.rule.comparison == 'not_in';

    if (newType == 'MATH_EXPRESSION') {
      final updatedRule = widget.rule.copyWith(
        valueType: newType,
        value: widget.rule.value is String ? widget.rule.value : '',
        compareTo: widget.rule.compareTo ?? 'VALUE',
        mathOperations: widget.rule.mathOperations ?? [],
      );
      final newText = _formatValueForText(updatedRule.value, updatedRule);
      _textController.text = newText;
      _textController.selection = TextSelection.collapsed(
        offset: newText.length,
      );
      widget.onChange(updatedRule);
      return;
    }

    if (newType == 'FIELD' || newType == 'FIELD_LIST') {
      if (widget.rule.valueType == 'FIELD' ||
          widget.rule.valueType == 'FIELD_LIST') {
        newVal = widget.rule.value is String ? widget.rule.value : '';
      } else {
        // Reset when switching from Static Value to Field/Field List
        newVal = '';
      }
    } else if (newType == 'VALUE') {
      // Switching to Static Value: reset to clear any field path (e.g. resource.allowedDepartments)
      if (isArray) {
        newVal = <String>[];
      } else if (selectedField?.fieldType == 'BOOLEAN') {
        newVal = true;
      } else if (selectedField?.allowedValues != null &&
          selectedField!.allowedValues!.isNotEmpty) {
        newVal = selectedField!.allowedValues!.first;
      } else {
        newVal = '';
      }
    }

    final updatedRule = widget.rule.copyWith(valueType: newType, value: newVal);
    final newText = _formatValueForText(newVal, updatedRule);
    _textController.text = newText;
    _textController.selection = TextSelection.collapsed(offset: newText.length);
    widget.onChange(updatedRule);
  }

  void _handleFieldChange(String? newFieldName) {
    if (newFieldName == null) return;
    FieldDefinitionEntity? newField;
    try {
      newField = widget.fields.firstWhere((f) => f.fieldName == newFieldName);
    } catch (_) {}

    dynamic defaultValue = widget.rule.value;
    if (widget.rule.valueType == 'VALUE') {
      final isArray =
          widget.rule.comparison == 'in' || widget.rule.comparison == 'not_in';
      if (isArray) {
        defaultValue = <String>[];
      } else if (newField?.fieldType == 'BOOLEAN') {
        defaultValue = true;
      } else if (newField?.allowedValues != null &&
          newField!.allowedValues!.isNotEmpty) {
        defaultValue = newField.allowedValues!.first;
      } else {
        defaultValue = '';
      }
    }

    final updatedRule = widget.rule.copyWith(
      field: newFieldName,
      value: defaultValue,
      valueType: widget.rule.valueType,
    );
    final newText = _formatValueForText(defaultValue, updatedRule);
    _textController.text = newText;
    _textController.selection = TextSelection.collapsed(offset: newText.length);
    widget.onChange(updatedRule);
  }

  void _handleComparisonChange(String? val) {
    if (val == null) return;
    final isArray =
        (val == 'in' || val == 'not_in') && widget.rule.valueType == 'VALUE';
    dynamic newVal = widget.rule.value;
    if (isArray && newVal is! List) {
      newVal = newVal != null && newVal.toString().isNotEmpty
          ? [newVal.toString()]
          : [];
    }
    if (!isArray && newVal is List) {
      newVal = newVal.isNotEmpty ? newVal.first : '';
    }
    final updatedRule = widget.rule.copyWith(
      comparison: val,
      value: newVal,
      valueType: widget.rule.valueType,
    );
    final newText = _formatValueForText(newVal, updatedRule);
    _textController.text = newText;
    _textController.selection = TextSelection.collapsed(offset: newText.length);
    widget.onChange(updatedRule);
  }

  Widget _buildFieldDropdown(
    String? currentField,
    List<DropdownMenuItem<String>> fieldItems,
  ) {
    return Semantics(
      identifier: 'condition_rule_field_dropdown',
      label: 'Rule field',
      button: true,
      child: AppDropdownField<String>(
        value: currentField,
        items: fieldItems,
        onChanged: _handleFieldChange,
      ),
    );
  }

  Widget _buildComparisonDropdown(
    List<String> compOptions,
    List<DropdownMenuItem<String>> compDropdownItems,
  ) {
    return Semantics(
      identifier: 'condition_rule_operator_dropdown',
      label: 'Rule comparison operator',
      button: true,
      child: AppDropdownField<String>(
        value: compOptions.contains(widget.rule.comparison)
            ? widget.rule.comparison
            : '==',
        items: compDropdownItems,
        onChanged: _handleComparisonChange,
      ),
    );
  }

  Widget _buildValueTypeDropdown(
    List<DropdownMenuItem<String>> valueTypeDropdownItems,
  ) {
    return Semantics(
      identifier: 'condition_rule_value_type_dropdown',
      label: 'Rule value type',
      button: true,
      child: AppDropdownField<String>(
        value: widget.rule.valueType,
        items: valueTypeDropdownItems,
        onChanged: _handleValueTypeChange,
      ),
    );
  }

  Widget _buildRemoveButton() {
    return Semantics(
      identifier: 'remove_condition_rule_button',
      label: 'Remove rule',
      button: true,
      tooltip: 'Remove rule',
      child: IconButton(
        icon: const Icon(Icons.close, size: 18, color: Colors.redAccent),
        tooltip: 'Remove rule',
        onPressed: widget.onRemove,
      ),
    );
  }

  Widget _buildValueInput() {
    if (widget.rule.valueType == 'MATH_EXPRESSION') {
      return Expanded(
        child: MathExpressionWidget(
          rule: widget.rule,
          fields: widget.fields,
          onChange: widget.onChange,
        ),
      );
    }

    if (widget.rule.valueType == 'FIELD' ||
        widget.rule.valueType == 'FIELD_LIST') {
      final suggestions = allSuggestions;
      final currentStr = widget.rule.value is String
          ? widget.rule.value as String
          : '';
      final isKnown = suggestions.contains(currentStr);
      final dropdownVal = isKnown
          ? currentStr
          : (currentStr.isNotEmpty ? '__custom__' : null);

      return Expanded(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 360;

            final dropdown = Semantics(
              identifier: 'condition_rule_field_suggestion_dropdown',
              label: 'Select field path suggestion',
              button: true,
              child: AppDropdownField<String>(
                value: dropdownVal,
                hintText: 'Select Field...',
                items: [
                  ...userFieldSuggestions.map(
                    (sf) => DropdownMenuItem<String>(
                      value: sf,
                      child: Text(
                        '$sf (User)',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  ...resourceFieldSuggestions.map(
                    (rf) => DropdownMenuItem<String>(
                      value: rf,
                      child: Text(
                        '$rf (Resource)',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const DropdownMenuItem<String>(
                    value: '__custom__',
                    child: Text(
                      'Custom path...',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val != null && val != '__custom__') {
                    _textController.text = val;
                    _textController.selection = TextSelection.collapsed(
                      offset: val.length,
                    );
                    widget.onChange(widget.rule.copyWith(value: val));
                  }
                },
              ),
            );

            final textField = Semantics(
              identifier: 'condition_rule_field_path_text_field',
              label: 'Field path',
              textField: true,
              child: AppTextFormField(
                key: ValueKey(
                  'field_path_${widget.rule.field}_${widget.rule.valueType}',
                ),
                controller: _textController,
                focusNode: _textFocusNode,
                hintText: widget.rule.valueType == 'FIELD'
                    ? 'e.g. user.location'
                    : 'e.g. resource.allowedDepartments',
                validator: (val) => PolicyValidators.validateFieldPath(val),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: (val) =>
                    widget.onChange(widget.rule.copyWith(value: val)),
              ),
            );

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [dropdown, const SizedBox(height: 8), textField],
              );
            }

            return Row(
              children: [
                SizedBox(width: 175, child: dropdown),
                const SizedBox(width: 8),
                Expanded(child: textField),
              ],
            );
          },
        ),
      );
    }

    final isArrayOp =
        widget.rule.comparison == 'in' || widget.rule.comparison == 'not_in';

    if (isArrayOp) {
      return Expanded(
        child: Semantics(
          identifier: 'condition_rule_array_value_text_field',
          label: 'Comma-separated values',
          textField: true,
          child: AppTextFormField(
            key: ValueKey(
              'array_${widget.rule.field}_${widget.rule.valueType}',
            ),
            controller: _textController,
            focusNode: _textFocusNode,
            keyboardType: isAgeField
                ? TextInputType.number
                : (selectedField?.fieldType == 'NUMBER'
                      ? const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        )
                      : TextInputType.text),
            inputFormatters: isAgeField
                ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9,\s]'))]
                : null,
            hintText: isAgeField ? 'e.g. 18, 25, 60' : 'value1, value2...',
            validator: (val) => PolicyValidators.validateArrayValues(
              val,
              isNumeric: selectedField?.fieldType == 'NUMBER',
              isAge: isAgeField,
            ),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onChanged: (val) {
              final arr = val
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .map((s) => isAgeField ? (int.tryParse(s) ?? s) : s)
                  .toList();
              widget.onChange(widget.rule.copyWith(value: arr));
            },
          ),
        ),
      );
    }

    final field = selectedField;
    if (field == null) {
      return Expanded(
        child: Semantics(
          identifier: 'condition_rule_value_text_field',
          label: 'Rule value',
          textField: true,
          child: AppTextFormField(
            key: ValueKey('val_${widget.rule.field}_${widget.rule.valueType}'),
            controller: _textController,
            focusNode: _textFocusNode,
            hintText: 'Value...',
            validator: (val) => PolicyValidators.validateRequired(val, 'Value'),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onChanged: (val) =>
                widget.onChange(widget.rule.copyWith(value: val)),
          ),
        ),
      );
    }

    if (field.optionsEndpoint != null && field.optionsEndpoint!.isNotEmpty) {
      return DynamicDropdownWidget(
        endpoint: field.optionsEndpoint!,
        permissionCode: widget.permissionCode,
        value: widget.rule.value,
        onChange: (val) {
          _textController.text = val;
          widget.onChange(widget.rule.copyWith(value: val));
        },
      );
    }

    if (field.allowedValues != null && field.allowedValues!.isNotEmpty) {
      final items = field.allowedValues!
          .map(
            (v) => DropdownMenuItem<String>(
              value: v,
              child: Text(v, style: const TextStyle(fontSize: 13)),
            ),
          )
          .toList();
      final currentVal =
          items.any((i) => i.value == widget.rule.value?.toString())
          ? widget.rule.value?.toString()
          : null;

      return Expanded(
        child: Semantics(
          identifier: 'condition_rule_allowed_values_dropdown',
          label: 'Select value for ${field.displayName}',
          button: true,
          child: AppDropdownField<String>(
            value: currentVal,
            hintText: 'Select value...',
            items: items,
            onChanged: (val) {
              if (val != null) {
                _textController.text = val;
                widget.onChange(widget.rule.copyWith(value: val));
              }
            },
          ),
        ),
      );
    }

    if (field.fieldType == 'BOOLEAN') {
      final valStr = widget.rule.value?.toString();
      return Expanded(
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 140,
            child: Semantics(
              identifier: 'condition_rule_boolean_dropdown',
              label: 'Select boolean value for ${field.displayName}',
              button: true,
              child: AppDropdownField<String>(
                value: (valStr == 'true' || valStr == 'false') ? valStr : null,
                hintText: 'Select...',
                items: const [
                  DropdownMenuItem(
                    value: 'true',
                    child: Text('True', style: TextStyle(fontSize: 13)),
                  ),
                  DropdownMenuItem(
                    value: 'false',
                    child: Text('False', style: TextStyle(fontSize: 13)),
                  ),
                ],
                onChanged: (val) {
                  _textController.text = val ?? '';
                  widget.onChange(widget.rule.copyWith(value: val == 'true'));
                },
              ),
            ),
          ),
        ),
      );
    }

    if (field.fieldType == 'NUMBER') {
      return Expanded(
        child: Semantics(
          identifier: 'condition_rule_number_text_field',
          label: 'Numeric value for ${field.displayName}',
          textField: true,
          child: AppTextFormField(
            key: ValueKey('num_${widget.rule.field}_${widget.rule.valueType}'),
            controller: _textController,
            focusNode: _textFocusNode,
            keyboardType: isAgeField
                ? TextInputType.number
                : const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
            inputFormatters: isAgeField
                ? [FilteringTextInputFormatter.digitsOnly]
                : [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^-?[0-9]*\.?[0-9]*'),
                    ),
                  ],
            hintText: isAgeField ? 'e.g. 25' : 'Value...',
            validator: (val) {
              if (isAgeField) {
                return PolicyValidators.validateAge(val, field.displayName);
              }
              return PolicyValidators.validateNumber(val, field.displayName);
            },
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onChanged: (val) {
              if (isAgeField) {
                final parsed = int.tryParse(val);
                widget.onChange(widget.rule.copyWith(value: parsed ?? val));
              } else {
                widget.onChange(
                  widget.rule.copyWith(value: num.tryParse(val) ?? val),
                );
              }
            },
          ),
        ),
      );
    }

    return Expanded(
      child: Semantics(
        identifier: 'condition_rule_value_fallback_text_field',
        label: 'Value for ${field.displayName}',
        textField: true,
        child: AppTextFormField(
          key: ValueKey('text_${widget.rule.field}_${widget.rule.valueType}'),
          controller: _textController,
          focusNode: _textFocusNode,
          hintText: 'Value...',
          validator: (val) =>
              PolicyValidators.validateRequired(val, field.displayName),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: (val) => widget.onChange(widget.rule.copyWith(value: val)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fieldItems = widget.fields
        .map(
          (f) => DropdownMenuItem<String>(
            value: f.fieldName,
            child: Text(
              f.displayName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        )
        .toList();

    final currentField = fieldItems.any((i) => i.value == widget.rule.field)
        ? widget.rule.field
        : (fieldItems.isNotEmpty ? fieldItems.first.value : null);

    const compOptions = [
      '==',
      '!=',
      'in',
      'not_in',
      'contains',
      '<=',
      '>=',
      '<',
      '>',
    ];

    final compDropdownItems = compOptions
        .map(
          (c) => DropdownMenuItem<String>(
            value: c,
            child: Text(c, style: const TextStyle(fontSize: 13)),
          ),
        )
        .toList();

    const valueTypeOptions = [
      MapEntry('VALUE', 'Static Value'),
      MapEntry('FIELD', 'Field Comparison'),
      MapEntry('FIELD_LIST', 'Field List'),
      MapEntry('MATH_EXPRESSION', 'Math Expression'),
    ];

    final valueTypeDropdownItems = valueTypeOptions
        .map(
          (e) => DropdownMenuItem<String>(
            value: e.key,
            child: Text(
              e.value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        )
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 460;
        final isTablet = constraints.maxWidth < 750;

        // Mobile Layout (< 460px)
        if (isMobile) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildFieldDropdown(currentField, fieldItems),
                      ),
                      const SizedBox(width: 4),
                      _buildRemoveButton(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: _buildComparisonDropdown(
                          compOptions,
                          compDropdownItems,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 5,
                        child: _buildValueTypeDropdown(valueTypeDropdownItems),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(children: [_buildValueInput()]),
                ],
              ),
            ),
          );
        }

        // Tablet / Compact Layout (460px - 749px)
        if (isTablet) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildFieldDropdown(currentField, fieldItems),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 95,
                        child: _buildComparisonDropdown(
                          compOptions,
                          compDropdownItems,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 140,
                        child: _buildValueTypeDropdown(valueTypeDropdownItems),
                      ),
                      const SizedBox(width: 4),
                      _buildRemoveButton(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(children: [_buildValueInput()]),
                ],
              ),
            ),
          );
        }

        // Desktop / Web Layout (>= 750px)
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: widget.rule.valueType == 'MATH_EXPRESSION'
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 160,
                child: _buildFieldDropdown(currentField, fieldItems),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 95,
                child: _buildComparisonDropdown(compOptions, compDropdownItems),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 140,
                child: _buildValueTypeDropdown(valueTypeDropdownItems),
              ),
              const SizedBox(width: 8),
              _buildValueInput(),
              const SizedBox(width: 4),
              _buildRemoveButton(),
            ],
          ),
        );
      },
    );
  }
}
