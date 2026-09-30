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
      List<MathOperationEntity>? mathOps;
      if (json['mathOperations'] is List) {
        mathOps = (json['mathOperations'] as List)
            .where((op) => op is Map)
            .map((op) => MathOperationEntity.fromJson(
                  Map<String, dynamic>.from(op as Map),
                ))
            .toList();
      }
      return ConditionRuleEntity(
        field: json['field'] as String? ?? '',
        comparison: json['comparison'] as String? ?? '==',
        value: json['value'],
        valueType: json['valueType'] as String? ?? 'VALUE',
        compareTo: json['compareTo'] as String?,
        mathOperations: mathOps,
      );
    }
  }
}

class MathOperationEntity extends Equatable {
  final String mathOperator; // ADD, SUBTRACT, MULTIPLY, DIVIDE
  final String operandType; // VALUE, FIELD
  final String value;

  const MathOperationEntity({
    this.mathOperator = 'ADD',
    this.operandType = 'VALUE',
    this.value = '',
  });

  MathOperationEntity copyWith({
    String? mathOperator,
    String? operandType,
    String? value,
  }) {
    return MathOperationEntity(
      mathOperator: mathOperator ?? this.mathOperator,
      operandType: operandType ?? this.operandType,
      value: value ?? this.value,
    );
  }

  factory MathOperationEntity.fromJson(Map<String, dynamic> json) {
    return MathOperationEntity(
      mathOperator: json['mathOperator'] as String? ?? 'ADD',
      operandType: json['operandType'] as String? ?? 'VALUE',
      value: json['value']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mathOperator': mathOperator,
      'operandType': operandType,
      'value': value,
    };
  }

  @override
  List<Object?> get props => [mathOperator, operandType, value];
}

class ConditionRuleEntity extends ConditionNodeEntity {
  final String field;
  final String comparison;
  final dynamic value;
  final String valueType; // VALUE, FIELD, FIELD_LIST, MATH_EXPRESSION
  final String? compareTo; // VALUE, FIELD
  final List<MathOperationEntity>? mathOperations;

  const ConditionRuleEntity({
    required this.field,
    this.comparison = '==',
    this.value,
    this.valueType = 'VALUE',
    this.compareTo,
    this.mathOperations,
  });

  ConditionRuleEntity copyWith({
    String? field,
    String? comparison,
    dynamic value,
    String? valueType,
    String? compareTo,
    List<MathOperationEntity>? mathOperations,
  }) {
    return ConditionRuleEntity(
      field: field ?? this.field,
      comparison: comparison ?? this.comparison,
      value: value ?? this.value,
      valueType: valueType ?? this.valueType,
      compareTo: compareTo ?? this.compareTo,
      mathOperations: mathOperations ?? this.mathOperations,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'field': field,
      'comparison': comparison,
      'value': value,
      'valueType': valueType,
    };
    if (valueType == 'MATH_EXPRESSION') {
      map['compareTo'] = compareTo ?? 'VALUE';
      map['mathOperations'] = (mathOperations ?? [])
          .map((op) => op.toJson())
          .toList();
    }
    return map;
  }

  @override
  List<Object?> get props => [
        field,
        comparison,
        value,
        valueType,
        compareTo,
        mathOperations,
      ];
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
