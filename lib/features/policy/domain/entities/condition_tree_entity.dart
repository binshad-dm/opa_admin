import 'package:equatable/equatable.dart';

abstract class ConditionNodeEntity extends Equatable {
  const ConditionNodeEntity();

  Map<String, dynamic> toJson();

  static ConditionNodeEntity fromJson(Map<String, dynamic> json) {
    if (json.containsKey('operator')) {
      final childrenList = json['children'] as List<dynamic>? ?? [];
      return ConditionGroupEntity(
        operator: json['operator'] as String? ?? 'AND',
        children: childrenList
            .map((c) => ConditionNodeEntity.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
    } else {
      return ConditionRuleEntity(
        field: json['field'] as String? ?? '',
        comparison: json['comparison'] as String? ?? '==',
        value: json['value'],
      );
    }
  }
}

class ConditionRuleEntity extends ConditionNodeEntity {
  final String field;
  final String comparison;
  final dynamic value;

  const ConditionRuleEntity({
    required this.field,
    this.comparison = '==',
    this.value,
  });

  ConditionRuleEntity copyWith({
    String? field,
    String? comparison,
    dynamic value,
  }) {
    return ConditionRuleEntity(
      field: field ?? this.field,
      comparison: comparison ?? this.comparison,
      value: value ?? this.value,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'field': field,
      'comparison': comparison,
      'value': value,
    };
  }

  @override
  List<Object?> get props => [field, comparison, value];
}

class ConditionGroupEntity extends ConditionNodeEntity {
  final String operator; // AND, OR, NOT
  final List<ConditionNodeEntity> children;

  const ConditionGroupEntity({
    this.operator = 'AND',
    this.children = const [],
  });

  ConditionGroupEntity copyWith({
    String? operator,
    List<ConditionNodeEntity>? children,
  }) {
    return ConditionGroupEntity(
      operator: operator ?? this.operator,
      children: children ?? this.children,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'operator': operator,
      'children': children.map((c) => c.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [operator, children];
}
