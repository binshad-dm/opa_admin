import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design/widgets/app_button.dart';
import '../../../../../core/design/widgets/app_segmented_button.dart';
import '../../../../../core/service_locator.dart';
import '../../../../../core/shared/snackbar.dart';
import '../../../domain/entities/policy_entity.dart';
import '../../view_model/condition_builder_cubit.dart';
import '../../view_model/condition_builder_state.dart';
import 'condition_group_widget.dart';
import 'custom_rego_editor_widget.dart';

class ConditionBuilderDialog extends StatefulWidget {
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
  State<ConditionBuilderDialog> createState() => _ConditionBuilderDialogState();
}

class _ConditionBuilderDialogState extends State<ConditionBuilderDialog> {
  final _formKey = GlobalKey<FormState>();
  String _activeTab = 'builder'; // 'builder' or 'preview'

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<ConditionBuilderCubit>()..init(widget.permissionCode, widget.policy),
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

          final screenSize = MediaQuery.sizeOf(context);
          final isSmallScreen = screenSize.width < 600;

          final dialogWidth = isSmallScreen
              ? screenSize.width * 0.96
              : (screenSize.width * 0.92).clamp(550.0, 1200.0);
          final dialogHeight = isSmallScreen
              ? (screenSize.height * 0.94).clamp(380.0, 850.0)
              : (screenSize.height * 0.90).clamp(450.0, 850.0);
          final isNarrow = dialogWidth < 800;

          return Dialog(
            insetPadding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 24,
              vertical: isSmallScreen ? 12 : 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            child: Container(
              width: dialogWidth,
              height: dialogHeight,
              padding: EdgeInsets.all(isSmallScreen ? 14 : 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Modal Header
                    if (isSmallScreen) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Condition Builder: ${widget.permissionCode}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Semantics(
                            identifier: 'close_condition_builder_dialog_button',
                            label: 'Close dialog',
                            button: true,
                            tooltip: 'Close dialog',
                            child: IconButton(
                              icon: const Icon(Icons.close),
                              tooltip: 'Close dialog',
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Semantics(
                            identifier: 'use_custom_rego_checkbox',
                            label: 'Use Custom Rego',
                            checked: state.useCustomRego,
                            child: Checkbox(
                              value: state.useCustomRego,
                              onChanged: (val) {
                                cubit.setUseCustomRego(val ?? false);
                              },
                            ),
                          ),
                          const Text(
                            'Use Custom Rego',
                            style: TextStyle(fontSize: 13),
                          ),
                          if (!state.useCustomRego) ...[
                            const Spacer(),
                            AppSegmentedButton<String>(
                              groupValue: _activeTab,
                              width: 180,
                              children: const {
                                'builder': 'Rules',
                                'preview': 'Preview',
                              },
                              onValueChanged: (val) {
                                setState(() => _activeTab = val);
                              },
                            ),
                          ],
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Condition Builder: ${widget.permissionCode}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          if (isNarrow && !state.useCustomRego) ...[
                            AppSegmentedButton<String>(
                              groupValue: _activeTab,
                              width: 200,
                              children: const {
                                'builder': 'Builder',
                                'preview': 'Preview',
                              },
                              onValueChanged: (val) {
                                setState(() => _activeTab = val);
                              },
                            ),
                            const SizedBox(width: 12),
                          ],
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Semantics(
                                identifier: 'use_custom_rego_checkbox',
                                label: 'Use Custom Rego',
                                checked: state.useCustomRego,
                                child: Checkbox(
                                  value: state.useCustomRego,
                                  onChanged: (val) {
                                    cubit.setUseCustomRego(val ?? false);
                                  },
                                ),
                              ),
                              const Text(
                                'Use Custom Rego',
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Semantics(
                            identifier: 'close_condition_builder_dialog_button',
                            label: 'Close dialog',
                            button: true,
                            tooltip: 'Close dialog',
                            child: IconButton(
                              icon: const Icon(Icons.close),
                              tooltip: 'Close dialog',
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const Divider(height: 20),

                    // Modal Content Body
                    Expanded(
                      child: state.isLoadingFields
                          ? const Center(child: CircularProgressIndicator())
                          : state.useCustomRego
                          ? CustomRegoEditorWidget(
                              snippet: state.customRegoSnippet,
                              onChanged: cubit.setCustomRegoSnippet,
                            )
                          : isNarrow
                          ? (_activeTab == 'builder'
                              ? SingleChildScrollView(
                                  child: ConditionGroupWidget(
                                    node: state.expressionTree,
                                    fields: state.fields,
                                    permissionCode: widget.permissionCode,
                                    onChange: cubit.updateTree,
                                    isRoot: true,
                                  ),
                                )
                              : _buildPreviewContainer(context, cubit, state))
                          : Flex(
                              direction: Axis.horizontal,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left Column: Group Tree Builder
                                Expanded(
                                  flex: 6,
                                  child: SingleChildScrollView(
                                    child: ConditionGroupWidget(
                                      node: state.expressionTree,
                                      fields: state.fields,
                                      permissionCode: widget.permissionCode,
                                      onChange: cubit.updateTree,
                                      isRoot: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Right Column: Live Preview
                                Expanded(
                                  flex: 4,
                                  child: _buildPreviewContainer(
                                    context,
                                    cubit,
                                    state,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const Divider(height: 20),

                    // Modal Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Semantics(
                          identifier: 'cancel_condition_builder_button',
                          label: 'Cancel',
                          button: true,
                          child: AppOutlinedButton(
                            text: 'Cancel',
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Semantics(
                          identifier: 'apply_condition_builder_button',
                          label: 'Apply conditions',
                          button: true,
                          enabled: cubit.isValid,
                          child: AppButton(
                            text: 'Apply',
                            enabled: cubit.isValid,
                            onPressed: () {
                              final formValid =
                                  _formKey.currentState?.validate() ?? true;
                              final validationError = cubit.validationError;

                              if (!formValid || validationError != null) {
                                showCustomSnackBar(
                                  context: context,
                                  message: validationError ??
                                      'Please correct all validation errors before applying.',
                                  type: SnackBarType.alert,
                                );
                                return;
                              }

                              if (state.useCustomRego) {
                                widget.onApply(
                                  widget.permissionCode,
                                  null,
                                  true,
                                  state.customRegoSnippet,
                                );
                              } else {
                                final treeJson =
                                    state.expressionTree.children.isEmpty
                                        ? null
                                        : state.expressionTree.toJson();
                                widget.onApply(
                                  widget.permissionCode,
                                  treeJson,
                                  false,
                                  '',
                                );
                              }
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPreviewContainer(
    BuildContext context,
    ConditionBuilderCubit cubit,
    ConditionBuilderState state,
  ) {
    final hasEmptyGroup = !state.useCustomRego && cubit.hasEmptyGroup();

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasEmptyGroup
              ? Colors.redAccent.withOpacity(0.5)
              : Theme.of(context).dividerColor.withOpacity(0.2),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              if (hasEmptyGroup)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(0.5),
                    ),
                  ),
                  child: const Text(
                    'EMPTY GROUP',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
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
                  color: hasEmptyGroup ? Colors.orangeAccent : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
