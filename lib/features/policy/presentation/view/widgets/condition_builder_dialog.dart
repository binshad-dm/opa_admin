import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design/widgets/app_button.dart';
import '../../../../../core/service_locator.dart';
import '../../../../../core/shared/snackbar.dart';
import '../../../domain/entities/policy_entity.dart';
import '../../view_model/condition_builder_cubit.dart';
import '../../view_model/condition_builder_state.dart';
import 'condition_group_widget.dart';
import 'custom_rego_editor_widget.dart';

class ConditionBuilderDialog extends StatelessWidget {
  final String permissionCode;
  final PolicyEntity? policy;
  final Function(
    String permissionCode,
    Map<String, dynamic>? expressionJson,
    bool useCustomRego,
    String customRegoSnippet,
  )
  onApply;

  const ConditionBuilderDialog({
    super.key,
    required this.permissionCode,
    this.policy,
    required this.onApply,
  });

  static Future<void> show({
    required BuildContext context,
    required String permissionCode,
    PolicyEntity? policy,
    required Function(
      String permissionCode,
      Map<String, dynamic>? expressionJson,
      bool useCustomRego,
      String customRegoSnippet,
    )
    onApply,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConditionBuilderDialog(
        permissionCode: permissionCode,
        policy: policy,
        onApply: onApply,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<ConditionBuilderCubit>()..init(permissionCode, policy),
      child: BlocConsumer<ConditionBuilderCubit, ConditionBuilderState>(
        listener: (context, state) {
          if (state.error != null && state.error!.isNotEmpty) {
            showCustomSnackBar(
              context: context,
              message: state.error!,
              type: SnackBarType.failure,
            );
          }
        },
        builder: (context, state) {
          final cubit = context.read<ConditionBuilderCubit>();

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            child: Container(
              width: 1100,
              height: 700,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modal Header
                  Row(
                    children: [
                      Text(
                        'Condition Builder: $permissionCode',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Row(
                        children: [
                          Checkbox(
                            value: state.useCustomRego,
                            onChanged: (val) {
                              cubit.setUseCustomRego(val ?? false);
                            },
                          ),
                          const Text(
                            'Use Custom Rego',
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Modal Content Body
                  Expanded(
                    child: state.isLoadingFields
                        ? const Center(child: CircularProgressIndicator())
                        : state.useCustomRego
                        ? CustomRegoEditorWidget(
                            snippet: state.customRegoSnippet,
                            onChanged: cubit.setCustomRegoSnippet,
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left Column: Group Tree Builder
                              Expanded(
                                flex: 6,
                                child: SingleChildScrollView(
                                  child: ConditionGroupWidget(
                                    node: state.expressionTree,
                                    fields: state.fields,
                                    permissionCode: permissionCode,
                                    onChange: cubit.updateTree,
                                    isRoot: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Right Column: Preview
                              Builder(
                                builder: (context) {
                                  final hasEmptyGroup =
                                      !state.useCustomRego &&
                                      cubit.hasEmptyGroup();
                                  return Expanded(
                                    flex: 4,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: hasEmptyGroup
                                              ? Colors.redAccent.withOpacity(
                                                  0.5,
                                                )
                                              : Theme.of(
                                                  context,
                                                ).dividerColor.withOpacity(0.2),
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'PREVIEW',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey,
                                                  letterSpacing: 1.2,
                                                ),
                                              ),
                                              // if (hasEmptyGroup)
                                              //   Container(
                                              //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              //     decoration: BoxDecoration(
                                              //       color: Colors.redAccent.withOpacity(0.2),
                                              //       borderRadius: BorderRadius.circular(4),
                                              //       border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                                              //     ),
                                              //     child: const Text(
                                              //       'EMPTY GROUP DETECTED',
                                              //       style: TextStyle(
                                              //         fontSize: 10,
                                              //         fontWeight: FontWeight.bold,
                                              //         color: Colors.redAccent,
                                              //       ),
                                              //     ),
                                              //   ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Expanded(
                                            child: SingleChildScrollView(
                                              child: Text(
                                                cubit.generatePreview(),
                                                style: TextStyle(
                                                  fontFamily: 'monospace',
                                                  fontSize: 13,
                                                  height: 1.5,
                                                  color: hasEmptyGroup
                                                      ? Colors.orangeAccent
                                                      : null,
                                                ),
                                              ),
                                            ),
                                          ),
                                          // if (hasEmptyGroup) ...[
                                          //   const SizedBox(height: 8),
                                          //   Container(
                                          //     padding: const EdgeInsets.all(8),
                                          //     decoration: BoxDecoration(
                                          //       color: Colors.redAccent.withOpacity(0.1),
                                          //       borderRadius: BorderRadius.circular(6),
                                          //       border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                                          //     ),
                                          //     child: const Row(
                                          //       children: [
                                          //         Icon(Icons.warning_amber_rounded, size: 16, color: Colors.redAccent),
                                          //         SizedBox(width: 6),
                                          //         Expanded(
                                          //           child: Text(
                                          //             'Empty group detected in preview section. Add rules or remove empty group to proceed.',
                                          //             style: TextStyle(
                                          //               color: Colors.redAccent,
                                          //               fontSize: 11,
                                          //               fontWeight: FontWeight.w500,
                                          //             ),
                                          //           ),
                                          //         ),
                                          //       ],
                                          //     ),
                                          //   ),
                                          // ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                  ),
                  const Divider(height: 24),

                  // Modal Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AppOutlinedButton(
                        text: 'Cancel',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 12),
                      AppButton(
                        text: 'Apply',
                        enabled: cubit.isValid,
                        onPressed: () {
                          if (!cubit.isValid) {
                            showCustomSnackBar(
                              context: context,
                              message: state.useCustomRego
                                  ? 'Cannot apply: Custom Rego snippet is empty.'
                                  : 'Cannot apply: Empty group present in preview section.',
                              type: SnackBarType.alert,
                            );
                            return;
                          }

                          if (state.useCustomRego) {
                            onApply(
                              permissionCode,
                              null,
                              true,
                              state.customRegoSnippet,
                            );
                          } else {
                            final treeJson =
                                state.expressionTree.children.isEmpty
                                ? null
                                : state.expressionTree.toJson();
                            onApply(permissionCode, treeJson, false, '');
                          }
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
