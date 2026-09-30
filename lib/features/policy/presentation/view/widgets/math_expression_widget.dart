import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/design/widgets/app_button.dart';
import '../../../../../core/design/widgets/app_dropdown_field.dart';
import '../../../../../core/design/widgets/app_text_form_field.dart';
import '../../../domain/entities/condition_tree_entity.dart';
import '../../../domain/entities/field_definition_entity.dart';
import '../../../domain/utils/policy_validators.dart';

class MathExpressionWidget extends StatelessWidget {
  final ConditionRuleEntity rule;
  final List<FieldDefinitionEntity> fields;
  final ValueChanged<ConditionRuleEntity> onChange;

  const MathExpressionWidget({
    super.key,
    required this.rule,
    required this.fields,
    required this.onChange,
  });

  List<String> get userFieldSuggestions => const [
        'user.location',
        'user.department',
        'user.id',
        'user.email',
        'user.roles',
      ];

  List<String> get numericResourceSuggestions {
    const numericTypes = {
      'NUMBER',
      'INTEGER',
      'DECIMAL',
      'LONG',
      'FLOAT',
      'DOUBLE',
      'BIGDECIMAL',
    };
    final numFields = fields
        .where((f) => numericTypes.contains(f.fieldType.toUpperCase()))
        .toList();
    final targetFields = numFields.isNotEmpty ? numFields : fields;
    return targetFields
        .map(
          (f) => f.fieldName.startsWith('resource.')
              ? f.fieldName
              : 'resource.${f.fieldName}',
        )
        .toList();
  }

  void _handleAddMathOp() {
    final ops = List<MathOperationEntity>.from(rule.mathOperations ?? []);
    ops.add(
      const MathOperationEntity(
        mathOperator: 'ADD',
        operandType: 'VALUE',
        value: '',
      ),
    );
    onChange(rule.copyWith(mathOperations: ops));
  }

  void _handleUpdateMathOp(int index, MathOperationEntity newOp) {
    final ops = List<MathOperationEntity>.from(rule.mathOperations ?? []);
    if (index >= 0 && index < ops.length) {
      ops[index] = newOp;
      onChange(rule.copyWith(mathOperations: ops));
    }
  }

  void _handleRemoveMathOp(int index) {
    final ops = List<MathOperationEntity>.from(rule.mathOperations ?? []);
    if (index >= 0 && index < ops.length) {
      ops.removeAt(index);
      onChange(rule.copyWith(mathOperations: ops));
    }
  }

  @override
  Widget build(BuildContext context) {
    final mathOps = rule.mathOperations ?? [];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Math Operations:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
                ),
              ),
              const Spacer(),
              if (mathOps.isNotEmpty)
                Text(
                  '${mathOps.length} op${mathOps.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).hintColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (mathOps.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                'No math operations added. Click "+ Add Math Op" below to append operations.',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).hintColor,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: mathOps.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, i) {
                return _MathOpRowWidget(
                  key: ValueKey('math_op_row_$i'),
                  index: i,
                  op: mathOps[i],
                  fields: fields,
                  userSuggestions: userFieldSuggestions,
                  resourceSuggestions: numericResourceSuggestions,
                  onChanged: (newOp) => _handleUpdateMathOp(i, newOp),
                  onRemove: () => _handleRemoveMathOp(i),
                );
              },
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Semantics(
              identifier: 'add_math_op_button',
              label: 'Add math operation',
              button: true,
              child: SizedBox(
                height: 30,
                child: AppOutlinedButton(
                  text: '+ Add Math Op',
                  onPressed: _handleAddMathOp,
                ),
              ),
            ),
          ),
          Divider(
            height: 20,
            thickness: 1,
            color: Theme.of(context).dividerColor.withOpacity(0.15),
          ),
          Text(
            'Compare Against:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
            ),
          ),
          const SizedBox(height: 8),
          _CompareAgainstWidget(
            rule: rule,
            fields: fields,
            userSuggestions: userFieldSuggestions,
            resourceSuggestions: numericResourceSuggestions,
            onChange: onChange,
          ),
        ],
      ),
    );
  }
}

class _MathOpRowWidget extends StatefulWidget {
  final int index;
  final MathOperationEntity op;
  final List<FieldDefinitionEntity> fields;
  final List<String> userSuggestions;
  final List<String> resourceSuggestions;
  final ValueChanged<MathOperationEntity> onChanged;
  final VoidCallback onRemove;

  const _MathOpRowWidget({
    super.key,
    required this.index,
    required this.op,
    required this.fields,
    required this.userSuggestions,
    required this.resourceSuggestions,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<_MathOpRowWidget> createState() => _MathOpRowWidgetState();
}

class _MathOpRowWidgetState extends State<_MathOpRowWidget> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.op.value);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(_MathOpRowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.op.value != widget.op.value &&
        !_focusNode.hasFocus &&
        _textController.text != widget.op.value) {
      _textController.text = widget.op.value;
      _textController.selection =
          TextSelection.collapsed(offset: widget.op.value.length);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _getFieldLabel(String fieldPath) {
    if (fieldPath.isEmpty) return '';
    if (fieldPath.startsWith('resource.')) {
      final rawName = fieldPath.substring(9);
      final matched = widget.fields.cast<FieldDefinitionEntity?>().firstWhere(
        (f) => f?.fieldName == rawName || f?.fieldName == fieldPath,
        orElse: () => null,
      );
      return matched?.displayName ?? rawName;
    }
    if (fieldPath.startsWith('user.')) {
      final rawName = fieldPath.substring(5);
      if (rawName.isEmpty) return fieldPath;
      return 'user${rawName[0].toUpperCase()}${rawName.substring(1)}';
    }
    final matched = widget.fields.cast<FieldDefinitionEntity?>().firstWhere(
      (f) => f?.fieldName == fieldPath,
      orElse: () => null,
    );
    return matched?.displayName ?? fieldPath;
  }

  Widget _buildFieldSelector() {
    final allSuggestions = [
      ...widget.userSuggestions,
      ...widget.resourceSuggestions,
    ];
    final currentVal = widget.op.value;
    final isKnown = allSuggestions.contains(currentVal);
    final dropdownVal = isKnown
        ? currentVal
        : (currentVal.isNotEmpty ? '__custom__' : null);

    final dropdown = Semantics(
      identifier: 'math_op_${widget.index}_field_dropdown',
      label: 'Select field for math op ${widget.index + 1}',
      button: true,
      child: AppDropdownField<String>(
        value: dropdownVal,
        hintText: 'Select Field...',
        items: [
          ...widget.userSuggestions.map(
            (sf) => DropdownMenuItem<String>(
              value: sf,
              child: Text(
                '${_getFieldLabel(sf)} (User)',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          ...widget.resourceSuggestions.map(
            (rf) => DropdownMenuItem<String>(
              value: rf,
              child: Text(
                '${_getFieldLabel(rf)} (Resource)',
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
            _textController.selection =
                TextSelection.collapsed(offset: val.length);
            widget.onChanged(widget.op.copyWith(value: val));
          } else if (val == '__custom__') {
            // Keep current value or let user edit custom path
            widget.onChanged(widget.op.copyWith(value: _textController.text));
          }
        },
      ),
    );

    if (dropdownVal == '__custom__') {
      return LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 280;
          final customFieldInput = Semantics(
            identifier: 'math_op_${widget.index}_custom_field_text_field',
            label: 'Custom field path for math op ${widget.index + 1}',
            textField: true,
            child: AppTextFormField(
              controller: _textController,
              focusNode: _focusNode,
              hintText: 'e.g. resource.taxRate',
              validator: (val) => PolicyValidators.validateFieldPath(val),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onChanged: (val) =>
                  widget.onChanged(widget.op.copyWith(value: val)),
            ),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                dropdown,
                const SizedBox(height: 6),
                customFieldInput,
              ],
            );
          }
          return Row(
            children: [
              SizedBox(width: 150, child: dropdown),
              const SizedBox(width: 6),
              Expanded(child: customFieldInput),
            ],
          );
        },
      );
    }

    return dropdown;
  }

  Widget _buildValueInput() {
    if (widget.op.operandType == 'FIELD') {
      return _buildFieldSelector();
    }

    return Semantics(
      identifier: 'math_op_${widget.index}_numeric_value_text_field',
      label: 'Number value for math op ${widget.index + 1}',
      textField: true,
      child: AppTextFormField(
        controller: _textController,
        focusNode: _focusNode,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*\.?[0-9]*')),
        ],
        hintText: 'Number',
        validator: (val) {
          if (val == null || val.trim().isEmpty) {
            return 'Value required';
          }
          if (num.tryParse(val.trim()) == null) {
            return 'Invalid number';
          }
          if (widget.op.mathOperator == 'DIVIDE' &&
              num.tryParse(val.trim()) == 0) {
            return 'Cannot divide by zero';
          }
          return null;
        },
        autovalidateMode: AutovalidateMode.onUserInteraction,
        onChanged: (val) => widget.onChanged(widget.op.copyWith(value: val)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const operatorItems = [
      DropdownMenuItem(value: 'ADD', child: Text('+')),
      DropdownMenuItem(value: 'SUBTRACT', child: Text('-')),
      DropdownMenuItem(value: 'MULTIPLY', child: Text('*')),
      DropdownMenuItem(value: 'DIVIDE', child: Text('/')),
    ];

    const operandTypeItems = [
      DropdownMenuItem(
        value: 'VALUE',
        child: Text('Static', style: TextStyle(fontSize: 12)),
      ),
      DropdownMenuItem(
        value: 'FIELD',
        child: Text('Field', style: TextStyle(fontSize: 12)),
      ),
    ];

    final operatorDropdown = Semantics(
      identifier: 'math_op_${widget.index}_operator_dropdown',
      label: 'Math operator',
      button: true,
      child: AppDropdownField<String>(
        value: widget.op.mathOperator,
        items: operatorItems,
        onChanged: (val) {
          if (val != null) {
            widget.onChanged(widget.op.copyWith(mathOperator: val));
          }
        },
      ),
    );

    final operandTypeDropdown = Semantics(
      identifier: 'math_op_${widget.index}_operand_type_dropdown',
      label: 'Operand type',
      button: true,
      child: AppDropdownField<String>(
        value: widget.op.operandType,
        items: operandTypeItems,
        onChanged: (val) {
          if (val != null) {
            _textController.clear();
            widget.onChanged(
              widget.op.copyWith(operandType: val, value: ''),
            );
          }
        },
      ),
    );

    final removeButton = Semantics(
      identifier: 'remove_math_op_${widget.index}_button',
      label: 'Remove math operation ${widget.index + 1}',
      button: true,
      tooltip: 'Remove math operation',
      child: IconButton(
        icon: const Icon(Icons.close, size: 16, color: Colors.redAccent),
        tooltip: 'Remove operation',
        onPressed: widget.onRemove,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 420;

        if (isCompact) {
          return Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withOpacity(0.03),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    SizedBox(width: 70, child: operatorDropdown),
                    const SizedBox(width: 6),
                    SizedBox(width: 95, child: operandTypeDropdown),
                    const Spacer(),
                    removeButton,
                  ],
                ),
                const SizedBox(height: 6),
                _buildValueInput(),
              ],
            ),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: 70, child: operatorDropdown),
            const SizedBox(width: 6),
            SizedBox(width: 95, child: operandTypeDropdown),
            const SizedBox(width: 6),
            Expanded(child: _buildValueInput()),
            const SizedBox(width: 4),
            removeButton,
          ],
        );
      },
    );
  }
}

class _CompareAgainstWidget extends StatefulWidget {
  final ConditionRuleEntity rule;
  final List<FieldDefinitionEntity> fields;
  final List<String> userSuggestions;
  final List<String> resourceSuggestions;
  final ValueChanged<ConditionRuleEntity> onChange;

  const _CompareAgainstWidget({
    required this.rule,
    required this.fields,
    required this.userSuggestions,
    required this.resourceSuggestions,
    required this.onChange,
  });

  @override
  State<_CompareAgainstWidget> createState() => _CompareAgainstWidgetState();
}

class _CompareAgainstWidgetState extends State<_CompareAgainstWidget> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController =
        TextEditingController(text: widget.rule.value?.toString() ?? '');
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(_CompareAgainstWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final valStr = widget.rule.value?.toString() ?? '';
    if (oldWidget.rule.value != widget.rule.value &&
        !_focusNode.hasFocus &&
        _textController.text != valStr) {
      _textController.text = valStr;
      _textController.selection =
          TextSelection.collapsed(offset: valStr.length);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _getFieldLabel(String fieldPath) {
    if (fieldPath.isEmpty) return '';
    if (fieldPath.startsWith('resource.')) {
      final rawName = fieldPath.substring(9);
      final matched = widget.fields.cast<FieldDefinitionEntity?>().firstWhere(
        (f) => f?.fieldName == rawName || f?.fieldName == fieldPath,
        orElse: () => null,
      );
      return matched?.displayName ?? rawName;
    }
    if (fieldPath.startsWith('user.')) {
      final rawName = fieldPath.substring(5);
      if (rawName.isEmpty) return fieldPath;
      return 'user${rawName[0].toUpperCase()}${rawName.substring(1)}';
    }
    final matched = widget.fields.cast<FieldDefinitionEntity?>().firstWhere(
      (f) => f?.fieldName == fieldPath,
      orElse: () => null,
    );
    return matched?.displayName ?? fieldPath;
  }

  Widget _buildFieldSelector() {
    final allSuggestions = [
      ...widget.userSuggestions,
      ...widget.resourceSuggestions,
    ];
    final currentVal = widget.rule.value?.toString() ?? '';
    final isKnown = allSuggestions.contains(currentVal);
    final dropdownVal = isKnown
        ? currentVal
        : (currentVal.isNotEmpty ? '__custom__' : null);

    final dropdown = Semantics(
      identifier: 'math_compare_to_field_dropdown',
      label: 'Select comparison target field',
      button: true,
      child: AppDropdownField<String>(
        value: dropdownVal,
        hintText: 'Select Field...',
        items: [
          ...widget.userSuggestions.map(
            (sf) => DropdownMenuItem<String>(
              value: sf,
              child: Text(
                '${_getFieldLabel(sf)} (User)',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          ...widget.resourceSuggestions.map(
            (rf) => DropdownMenuItem<String>(
              value: rf,
              child: Text(
                '${_getFieldLabel(rf)} (Resource)',
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
            _textController.selection =
                TextSelection.collapsed(offset: val.length);
            widget.onChange(widget.rule.copyWith(value: val));
          } else if (val == '__custom__') {
            widget.onChange(widget.rule.copyWith(value: _textController.text));
          }
        },
      ),
    );

    if (dropdownVal == '__custom__') {
      return LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 280;
          final customInput = Semantics(
            identifier: 'math_compare_to_custom_field_text_field',
            label: 'Custom target field path',
            textField: true,
            child: AppTextFormField(
              controller: _textController,
              focusNode: _focusNode,
              hintText: 'e.g. user.roles',
              validator: (val) => PolicyValidators.validateFieldPath(val),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onChanged: (val) => widget.onChange(widget.rule.copyWith(value: val)),
            ),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                dropdown,
                const SizedBox(height: 6),
                customInput,
              ],
            );
          }
          return Row(
            children: [
              SizedBox(width: 150, child: dropdown),
              const SizedBox(width: 6),
              Expanded(child: customInput),
            ],
          );
        },
      );
    }

    return dropdown;
  }

  Widget _buildValueInput() {
    if ((widget.rule.compareTo ?? 'VALUE') == 'FIELD') {
      return _buildFieldSelector();
    }

    return Semantics(
      identifier: 'math_compare_target_value_text_field',
      label: 'Comparison target value',
      textField: true,
      child: AppTextFormField(
        controller: _textController,
        focusNode: _focusNode,
        hintText: 'Target value',
        validator: (val) =>
            PolicyValidators.validateRequired(val, 'Target value'),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        onChanged: (val) => widget.onChange(widget.rule.copyWith(value: val)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const compareToItems = [
      DropdownMenuItem(
        value: 'VALUE',
        child: Text('Static Value', style: TextStyle(fontSize: 12)),
      ),
      DropdownMenuItem(
        value: 'FIELD',
        child: Text('Field', style: TextStyle(fontSize: 12)),
      ),
    ];

    final compareToDropdown = Semantics(
      identifier: 'math_compare_to_type_dropdown',
      label: 'Compare against type',
      button: true,
      child: AppDropdownField<String>(
        value: widget.rule.compareTo ?? 'VALUE',
        items: compareToItems,
        onChanged: (val) {
          if (val != null && val != widget.rule.compareTo) {
            _textController.clear();
            widget.onChange(
              widget.rule.copyWith(compareTo: val, value: ''),
            );
          }
        },
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 420;

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              compareToDropdown,
              const SizedBox(height: 6),
              _buildValueInput(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: 125, child: compareToDropdown),
            const SizedBox(width: 8),
            Expanded(child: _buildValueInput()),
          ],
        );
      },
    );
  }
}
