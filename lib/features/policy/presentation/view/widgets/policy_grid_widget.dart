import 'package:flutter/material.dart';

import '../../../domain/entities/policy_entity.dart';
import 'policy_card_widget.dart';

class PolicyGridWidget extends StatelessWidget {
  final List<PolicyEntity> policies;
  final ValueChanged<String> onTogglePolicy;
  final ValueChanged<String> onEditConditions;

  const PolicyGridWidget({
    super.key,
    required this.policies,
    required this.onTogglePolicy,
    required this.onEditConditions,
  });

  @override
  Widget build(BuildContext context) {
    if (policies.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.security_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              const Text(
                'No policies found for this module and subject.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    // Group policies by resourceName
    final Map<String, List<PolicyEntity>> grouped = {};
    for (final p in policies) {
      grouped.putIfAbsent(p.resourceName, () => []).add(p);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1100
            ? 3
            : (constraints.maxWidth > 700 ? 2 : 1);

        final entries = grouped.entries.toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: entries.map((entry) {
              final width =
                  (constraints.maxWidth - (16 * (crossAxisCount - 1))) /
                  crossAxisCount;

              return SizedBox(
                width: width,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withOpacity(0.15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.folder_outlined,
                            size: 18,
                            color: Color(0xFF0F4C81),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.key.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF0F4C81),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...entry.value.map(
                        (policy) => PolicyCardWidget(
                          policy: policy,
                          onToggle: onTogglePolicy,
                          onEditConditions: onEditConditions,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
