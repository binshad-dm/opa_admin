import 'package:flutter/material.dart';

import '../../../../../core/design/widgets/app_dropdown_field.dart';
import '../../../../../core/design/widgets/app_text_form_field.dart';
import '../../../domain/entities/condition_tree_entity.dart';
import '../../../domain/entities/field_definition_entity.dart';
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

  Widget _buildValueInput() {
    final isArrayOp = rule.comparison == 'in' || rule.comparison == 'not_in';

    if (isArrayOp) {
      final displayValue = rule.value is List
          ? (rule.value as List).join(', ')
          : (rule.value?.toString() ?? '');
      return Expanded(
        child: AppTextFormField(
          hintText: 'value1, value2...',
          initialValue: displayValue,
          onChanged: (val) {
            final arr = val.split(',').map((s) => s.trimLeft()).toList();
            onChange(rule.copyWith(value: arr));
          },
        ),
      );
    }

    final field = selectedField;
    if (field == null) {
      return Expanded(
        child: AppTextFormField(
          hintText: 'Value...',
          initialValue: rule.value?.toString() ?? '',
          onChanged: (val) => onChange(rule.copyWith(value: val)),
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
        child: AppDropdownField<String>(
          value: currentVal,
          hintText: 'Select value...',
          items: items,
          onChanged: (val) => onChange(rule.copyWith(value: val)),
        ),
      );
    }

    if (field.fieldType == 'BOOLEAN') {
      final valStr = rule.value != null ? rule.value.toString() : null;
      return SizedBox(
        width: 140,
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
          onChanged: (val) => onChange(rule.copyWith(value: val == 'true')),
        ),
      );
    }

    if (field.fieldType == 'NUMBER') {
      return Expanded(
        child: AppTextFormField(
          keyboardType: TextInputType.number,
          hintText: 'Value...',
          initialValue: rule.value?.toString() ?? '',
          onChanged: (val) =>
              onChange(rule.copyWith(value: num.tryParse(val) ?? val)),
        ),
      );
    }

    return Expanded(
      child: AppTextFormField(
        hintText: 'Value...',
        initialValue: rule.value?.toString() ?? '',
        onChanged: (val) => onChange(rule.copyWith(value: val)),
      ),
    );
  }

  void _handleFieldChange(String? newFieldName) {
    if (newFieldName == null) return;
    FieldDefinitionEntity? newField;
    try {
      newField = fields.firstWhere((f) => f.fieldName == newFieldName);
    } catch (_) {}

    dynamic defaultValue = '';
    if (newField?.fieldType == 'BOOLEAN') {
      defaultValue = true;
    } else if (newField?.allowedValues != null &&
        newField!.allowedValues!.isNotEmpty) {
      defaultValue = newField.allowedValues!.first;
    }

    onChange(rule.copyWith(field: newFieldName, value: defaultValue));
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 170,
            child: AppDropdownField<String>(
              value: currentField,
              items: fieldItems,
              onChanged: _handleFieldChange,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: AppDropdownField<String>(
              value: compOptions.contains(rule.comparison)
                  ? rule.comparison
                  : '==',
              items: compOptions
                  .map(
                    (c) => DropdownMenuItem<String>(
                      value: c,
                      child: Text(c, style: const TextStyle(fontSize: 13)),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val == null) return;
                final isArray = val == 'in' || val == 'not_in';
                dynamic newVal = rule.value;
                if (isArray && newVal is! List) {
                  newVal = newVal != null ? [newVal.toString()] : [];
                }
                if (!isArray && newVal is List) {
                  newVal = newVal.isNotEmpty ? newVal.first : '';
                }
                onChange(rule.copyWith(comparison: val, value: newVal));
              },
            ),
          ),
          const SizedBox(width: 8),
          _buildValueInput(),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.redAccent),
            tooltip: 'Remove rule',
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
