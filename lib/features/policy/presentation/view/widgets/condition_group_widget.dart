import 'package:flutter/material.dart';

import '../../../../../core/design/widgets/app_button.dart';
import '../../../../../core/design/widgets/app_dropdown_field.dart';
import '../../../domain/entities/condition_tree_entity.dart';
import '../../../domain/entities/field_definition_entity.dart';
import 'condition_rule_widget.dart';

class ConditionGroupWidget extends StatelessWidget {
  final ConditionGroupEntity node;
  final List<FieldDefinitionEntity> fields;
  final String permissionCode;
  final ValueChanged<ConditionGroupEntity> onChange;
  final VoidCallback? onRemove;
  final bool isRoot;

  const ConditionGroupWidget({
    super.key,
    required this.node,
    required this.fields,
    required this.permissionCode,
    required this.onChange,
    this.onRemove,
    this.isRoot = true,
  });

  void _handleChildChange(int index, ConditionNodeEntity newChild) {
    final newChildren = List<ConditionNodeEntity>.from(node.children);
    newChildren[index] = newChild;
    onChange(node.copyWith(children: newChildren));
  }

  void _handleRemoveChild(int index) {
    final newChildren = List<ConditionNodeEntity>.from(node.children)
      ..removeAt(index);
    onChange(node.copyWith(children: newChildren));
  }

  void _addRule() {
    final defaultField = fields.isNotEmpty ? fields.first : null;
    dynamic defaultValue = '';
    if (defaultField?.fieldType == 'BOOLEAN') {
      defaultValue = true;
    } else if (defaultField?.allowedValues != null &&
        defaultField!.allowedValues!.isNotEmpty) {
      defaultValue = defaultField.allowedValues!.first;
    }

    final newRule = ConditionRuleEntity(
      field: defaultField?.fieldName ?? '',
      comparison: '==',
      value: defaultValue,
      valueType: 'VALUE',
    );

    final newChildren = List<ConditionNodeEntity>.from(node.children)
      ..add(newRule);
    onChange(node.copyWith(children: newChildren));
  }

  void _addGroup(String op) {
    final newGroup = ConditionGroupEntity(operator: op, children: const []);
    final newChildren = List<ConditionNodeEntity>.from(node.children)
      ..add(newGroup);
    onChange(node.copyWith(children: newChildren));
  }

  @override
  Widget build(BuildContext context) {
    final rules = <MapEntry<int, ConditionRuleEntity>>[];
    final groups = <MapEntry<int, ConditionGroupEntity>>[];

    for (int i = 0; i < node.children.length; i++) {
      final child = node.children[i];
      if (child is ConditionRuleEntity) {
        rules.add(MapEntry(i, child));
      } else if (child is ConditionGroupEntity) {
        groups.add(MapEntry(i, child));
      }
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: isRoot ? 0 : 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Match',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 140,
                child: Semantics(
                  identifier: 'condition_group_operator_dropdown',
                  label: 'Match operator: ALL (AND), ANY (OR), or NONE (NOT)',
                  button: true,
                  child: AppDropdownField<String>(
                    value: node.operator,
                    items: const [
                      DropdownMenuItem(
                        value: 'AND',
                        child: Text(
                          'ALL (AND)',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'OR',
                        child: Text('ANY (OR)', style: TextStyle(fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: 'NOT',
                        child: Text(
                          'NONE (NOT)',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) onChange(node.copyWith(operator: val));
                    },
                  ),
                ),
              ),
              const Spacer(),
              if (!isRoot && onRemove != null)
                Semantics(
                  identifier: 'remove_condition_group_button',
                  button: true,
                  label: 'Remove condition group',
                  child: TextButton.icon(
                    onPressed: onRemove,
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: Colors.redAccent,
                    ),
                    label: const Text(
                      'Remove Group',
                      style: TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
          if (node.operator == 'NOT' && node.children.length > 1) ...[
            const SizedBox(height: 6),
            const Text(
              'Warning: NOT group should ideally have only one condition.',
              style: TextStyle(color: Colors.amber, fontSize: 11),
            ),
          ],
          const SizedBox(height: 12),

          // Render Rules
          for (final item in rules)
            ConditionRuleWidget(
              rule: item.value,
              fields: fields,
              permissionCode: permissionCode,
              onChange: (newRule) => _handleChildChange(item.key, newRule),
              onRemove: () => _handleRemoveChild(item.key),
            ),

          // Render Groups
          for (int gIdx = 0; gIdx < groups.length; gIdx++) ...[
            if (gIdx > 0 || rules.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        node.operator,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
              ),
            ],
            ConditionGroupWidget(
              node: groups[gIdx].value,
              fields: fields,
              permissionCode: permissionCode,
              onChange: (newGroup) =>
                  _handleChildChange(groups[gIdx].key, newGroup),
              onRemove: () => _handleRemoveChild(groups[gIdx].key),
              isRoot: false,
            ),
          ],

          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Semantics(
                identifier: 'add_rule_button',
                button: true,
                label: 'Add rule to condition group',
                child: AppOutlinedButton(
                  text: '+ Add Rule',
                  onPressed: _addRule,
                ),
              ),
              Semantics(
                identifier: 'add_group_button',
                button: true,
                label: 'Add nested condition group',
                child: AppOutlinedButton(
                  text: '+ Add Group',
                  onPressed: () => _addGroup('AND'),
                ),
              ),
              Semantics(
                identifier: 'add_not_group_button',
                button: true,
                label: 'Add nested NOT condition group',
                child: AppOutlinedButton(
                  text: '+ Add NOT Group',
                  onPressed: () => _addGroup('NOT'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
