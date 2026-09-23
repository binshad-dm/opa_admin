import 'package:flutter/material.dart';

import '../../../../../core/design/widgets/app_toggle_switch.dart';
import '../../../domain/entities/policy_entity.dart';

class PolicyCardWidget extends StatelessWidget {
  final PolicyEntity policy;
  final ValueChanged<String> onToggle;
  final ValueChanged<String> onEditConditions;

  const PolicyCardWidget({
    super.key,
    required this.policy,
    required this.onToggle,
    required this.onEditConditions,
  });

  @override
  Widget build(BuildContext context) {
    final hasConditions =
        (policy.expressionJson != null && policy.expressionJson!.isNotEmpty) ||
        (policy.useCustomRego && policy.customRegoSnippet!.isNotEmpty);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Semantics(
            identifier: 'policy_switch_${policy.permissionCode}',
            label: 'Toggle policy for ${policy.action}',
            hint:
                'Double tap to ${policy.enabled ? "disable" : "enable"} this policy',
            toggled: policy.enabled,
            child: AppToggleSwitch(
              value: policy.enabled,
              onChanged: (_) => onToggle(policy.permissionCode),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            policy.action.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(width: 12),
          if (hasConditions)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Has Conditions',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (policy.disabledReason != null &&
              policy.disabledReason!.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '⚠️ ${policy.disabledReason}',
                style: const TextStyle(color: Colors.redAccent, fontSize: 11),
              ),
            ),
          ],
          const Spacer(),
          Semantics(
            identifier: 'configure_conditions_button_${policy.permissionCode}',
            label: 'Configure conditions for ${policy.action}',
            button: true,
            tooltip: 'Configure Conditions',
            child: IconButton(
              icon: const Icon(Icons.settings_outlined, size: 20),
              tooltip: 'Configure Conditions',
              onPressed: () => onEditConditions(policy.permissionCode),
            ),
          ),
        ],
      ),
    );
  }
}
