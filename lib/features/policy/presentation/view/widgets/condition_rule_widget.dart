import 'package:flutter/material.dart';

import '../../../../../core/design/widgets/app_dropdown_field.dart';
import '../../../../../core/design/widgets/app_text_form_field.dart';
import '../../../domain/entities/condition_tree_entity.dart';
import '../../../domain/entities/field_definition_entity.dart';
import '../../../domain/utils/policy_validators.dart';
import 'dynamic_dropdown_widget.dart';

class ConditionRuleWidget extends StatelessWidget {
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

  FieldDefinitionEntity? get selectedField {
    try {
      return fields.firstWhere((f) => f.fieldName == rule.field);
    } catch (_) {
      return null;
    }
  }

  List<String> get userFieldSuggestions => const [
        'user.location',
        'user.department',
        'user.id',
        'user.email',
        'user.roles',
      ];

  List<String> get resourceFieldSuggestions => fields
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

  void _handleValueTypeChange(String? newType) {
    if (newType == null || newType == rule.valueType) return;
    dynamic newVal = rule.value;
    if (newType == 'FIELD' || newType == 'FIELD_LIST') {
      newVal = rule.value is String ? rule.value : '';
    } else if (newType == 'VALUE') {
      final isArray = rule.comparison == 'in' || rule.comparison == 'not_in';
      if (isArray && newVal is! List) {
        newVal = (newVal != null && newVal.toString().isNotEmpty)
            ? [newVal.toString()]
            : [];
      } else if (!isArray && newVal is List) {
        newVal = newVal.isNotEmpty ? newVal.first : '';
      }
    }
    onChange(rule.copyWith(valueType: newType, value: newVal));
  }

  void _handleFieldChange(String? newFieldName) {
    if (newFieldName == null) return;
    FieldDefinitionEntity? newField;
    try {
      newField = fields.firstWhere((f) => f.fieldName == newFieldName);
    } catch (_) {}

    dynamic defaultValue = rule.value;
    if (rule.valueType == 'VALUE') {
      defaultValue = '';
      if (newField?.fieldType == 'BOOLEAN') {
        defaultValue = true;
      } else if (newField?.allowedValues != null &&
          newField!.allowedValues!.isNotEmpty) {
        defaultValue = newField.allowedValues!.first;
      }
    }

    onChange(
      rule.copyWith(
        field: newFieldName,
        value: defaultValue,
        valueType: rule.valueType,
      ),
    );
  }

  void _handleComparisonChange(String? val) {
    if (val == null) return;
    final isArray =
        (val == 'in' || val == 'not_in') && rule.valueType == 'VALUE';
    dynamic newVal = rule.value;
    if (isArray && newVal is! List) {
      newVal = newVal != null && newVal.toString().isNotEmpty
          ? [newVal.toString()]
          : [];
    }
    if (!isArray && newVal is List) {
      newVal = newVal.isNotEmpty ? newVal.first : '';
    }
    onChange(
      rule.copyWith(
        comparison: val,
        value: newVal,
        valueType: rule.valueType,
      ),
    );
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
        value: compOptions.contains(rule.comparison)
            ? rule.comparison
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
        value: rule.valueType,
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
        icon: const Icon(
          Icons.close,
          size: 18,
          color: Colors.redAccent,
        ),
        tooltip: 'Remove rule',
        onPressed: onRemove,
      ),
    );
  }

  Widget _buildValueInput() {
    if (rule.valueType == 'FIELD' || rule.valueType == 'FIELD_LIST') {
      final suggestions = allSuggestions;
      final currentStr = rule.value is String ? rule.value as String : '';
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
                    onChange(rule.copyWith(value: val));
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
                  'field_path_${rule.field}_${rule.valueType}_${rule.value}',
                ),
                hintText: rule.valueType == 'FIELD'
                    ? 'e.g. user.location'
                    : 'e.g. resource.allowedDepartments',
                initialValue: currentStr,
                validator: (val) => PolicyValidators.validateFieldPath(val),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: (val) => onChange(rule.copyWith(value: val)),
              ),
            );

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  dropdown,
                  const SizedBox(height: 8),
                  textField,
                ],
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

    final isArrayOp = rule.comparison == 'in' || rule.comparison == 'not_in';

    if (isArrayOp) {
      final displayValue = rule.value is List
          ? (rule.value as List).join(', ')
          : (rule.value?.toString() ?? '');
      return Expanded(
        child: Semantics(
          identifier: 'condition_rule_array_value_text_field',
          label: 'Comma-separated values',
          textField: true,
          child: AppTextFormField(
            key: ValueKey('array_${rule.field}_${rule.value}'),
            hintText: 'value1, value2...',
            initialValue: displayValue,
            validator: (val) => PolicyValidators.validateArrayValues(
              val,
              isNumeric: selectedField?.fieldType == 'NUMBER',
            ),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onChanged: (val) {
              final arr = val
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
              onChange(rule.copyWith(value: arr));
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
            key: ValueKey('val_${rule.field}_${rule.value}'),
            hintText: 'Value...',
            initialValue: rule.value?.toString() ?? '',
            validator: (val) => PolicyValidators.validateRequired(val, 'Value'),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onChanged: (val) => onChange(rule.copyWith(value: val)),
          ),
        ),
      );
    }

    if (field.optionsEndpoint != null && field.optionsEndpoint!.isNotEmpty) {
      return DynamicDropdownWidget(
        endpoint: field.optionsEndpoint!,
        permissionCode: permissionCode,
        value: rule.value,
        onChange: (val) => onChange(rule.copyWith(value: val)),
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
      final currentVal = items.any((i) => i.value == rule.value?.toString())
          ? rule.value?.toString()
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
            onChanged: (val) => onChange(rule.copyWith(value: val)),
          ),
        ),
      );
    }

    if (field.fieldType == 'BOOLEAN') {
      final valStr = rule.value?.toString();
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
                onChanged: (val) =>
                    onChange(rule.copyWith(value: val == 'true')),
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
            key: ValueKey('num_${rule.field}_${rule.value}'),
            keyboardType: TextInputType.number,
            hintText: 'Value...',
            initialValue: rule.value?.toString() ?? '',
            validator: (val) => PolicyValidators.validateNumber(
              val,
              field.displayName,
            ),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onChanged: (val) =>
                onChange(rule.copyWith(value: num.tryParse(val) ?? val)),
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
          key: ValueKey('text_${rule.field}_${rule.value}'),
          hintText: 'Value...',
          initialValue: rule.value?.toString() ?? '',
          validator: (val) => PolicyValidators.validateRequired(
            val,
            field.displayName,
          ),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: (val) => onChange(rule.copyWith(value: val)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fieldItems = fields
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

    final currentField = fieldItems.any((i) => i.value == rule.field)
        ? rule.field
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
                  Row(
                    children: [
                      _buildValueInput(),
                    ],
                  ),
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
                        width: 130,
                        child: _buildValueTypeDropdown(valueTypeDropdownItems),
                      ),
                      const SizedBox(width: 4),
                      _buildRemoveButton(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildValueInput(),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        // Desktop / Web Layout (>= 750px)
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 160,
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
                width: 135,
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
