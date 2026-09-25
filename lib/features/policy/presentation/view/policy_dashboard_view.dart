import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/responsive/responsive_builder.dart';
import '../../../../core/design/widgets/app_button.dart';
import '../../../../core/design/widgets/app_dropdown_field.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/locale_cubit.dart';
import '../../../../core/service_locator.dart';
import '../../../../core/shared/snackbar.dart';
import '../../domain/entities/policy_entity.dart';
import '../view_model/policy_cubit.dart';
import '../view_model/policy_state.dart';
import 'widgets/condition_builder_dialog.dart';
import 'widgets/policy_grid_widget.dart';
import 'widgets/subject_selector_widget.dart';

class PolicyDashboardView extends StatelessWidget {
  const PolicyDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<PolicyCubit>()..initDashboard(),
      child: const _PolicyDashboardContent(),
    );
  }
}

class _PolicyDashboardContent extends StatelessWidget {
  const _PolicyDashboardContent();

  void _openConditionBuilder(
    BuildContext context,
    PolicyCubit cubit,
    String permissionCode,
    List<PolicyEntity> policies,
  ) {
    PolicyEntity? policy;
    try {
      policy = policies.firstWhere((p) => p.permissionCode == permissionCode);
    } catch (_) {}

    ConditionBuilderDialog.show(
      context: context,
      permissionCode: permissionCode,
      policy: policy,
      onApply: (pCode, json, useCustom, snippet) {
        cubit.updatePolicyConditions(pCode, json, useCustom, snippet);
      },
    );
  }

  Widget _buildLanguageSwitcher(BuildContext context) {
    final currentLang = Localizations.localeOf(context).languageCode;
    const languages = [
      DropdownMenuItem(
        value: 'en',
        child: Text(
          'EN',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
      DropdownMenuItem(
        value: 'es',
        child: Text(
          'ES',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
      DropdownMenuItem(
        value: 'ar',
        child: Text(
          'AR',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    ];

    final validLang = languages.any((l) => l.value == currentLang)
        ? currentLang
        : 'en';

    return SizedBox(
      width: 78,
      child: Semantics(
        identifier: 'language_switcher_dropdown',
        label: 'Switch Language',
        button: true,
        child: AppDropdownField<String>(
          value: validLang,
          items: languages,
          onChanged: (val) {
            if (val != null) {
              try {
                context.read<LocaleCubit>().changeLocale(val);
              } catch (_) {}
            }
          },
        ),
      ),
    );
  }

  Widget _buildSaveButton(
    PolicyLoaded state,
    PolicyCubit cubit,
    BuildContext context,
  ) {
    return Semantics(
      identifier: 'save_policies_button',
      button: true,
      enabled: !state.isSaving,
      label: state.isSaving ? 'Saving policy changes' : 'Save Changes',
      hint: 'Save all policy changes',
      child: AppButton(
        text: state.isSaving ? 'Saving...' : 'Save Changes',
        icon: state.isSaving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save_outlined, size: 18),
        enabled: !state.isSaving,
        onPressed: () async {
          final message = await cubit.savePolicies();
          if (context.mounted && message != null && message.isNotEmpty) {
            showCustomSnackBar(
              context: context,
              message: message,
              type: SnackBarType.success,
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final pageTitle = loc?.appTitle ?? 'Authorization Dashboard';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocConsumer<PolicyCubit, PolicyState>(
        listener: (context, state) {
          if (state is PolicyLoaded) {
            if (state.saveError != null && state.saveError!.isNotEmpty) {
              showCustomSnackBar(
                context: context,
                message: state.saveError!,
                type: SnackBarType.failure,
              );
            }
          } else if (state is PolicyError) {
            showCustomSnackBar(
              context: context,
              message: state.message,
              type: SnackBarType.failure,
            );
          }
        },
        builder: (context, state) {
          final cubit = context.read<PolicyCubit>();

          if (state is PolicyLoading) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(state.message ?? 'Loading...'),
                ],
              ),
            );
          }

          if (state is PolicyError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(state.message),
                  const SizedBox(height: 16),
                  Semantics(
                    identifier: 'retry_button',
                    button: true,
                    label: 'Retry loading dashboard',
                    child: AppButton(
                      text: 'Retry',
                      onPressed: () => cubit.initDashboard(),
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is PolicyLoaded) {
            return ResponsiveBuilder(
              builder: (context, screenSize) {
                final isSmall = screenSize == ScreenSize.small;
                final isMedium = screenSize == ScreenSize.medium;
                final paddingAmount = isSmall ? 12.0 : (isMedium ? 18.0 : 24.0);

                return Padding(
                  padding: EdgeInsets.all(paddingAmount),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section - Mobile vs Tablet/Web
                      if (isSmall) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pageTitle,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF0F4C81),
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Manage OPA permissions & rules.',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // const SizedBox(width: 8),
                            // _buildLanguageSwitcher(context),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: _buildSaveButton(state, cubit, context),
                        ),
                      ] else ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pageTitle,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF0F4C81),
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Manage Open Policy Agent permissions, conditions, and custom Rego expressions.',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // const SizedBox(width: 12),
                            // _buildLanguageSwitcher(context),
                            const SizedBox(width: 12),
                            _buildSaveButton(state, cubit, context),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Controls Bar: Subject Selector
                      Semantics(
                        container: true,
                        label: 'Subject selector section',
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).dividerColor.withOpacity(0.15),
                            ),
                          ),
                          child: SubjectSelectorWidget(
                            subjectType: state.subjectType,
                            subjectId: state.subjectId,
                            roles: state.roles,
                            users: state.users,
                            onSubjectTypeChanged: cubit.setSubjectType,
                            onSubjectIdChanged: cubit.setSubjectId,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Module Tabs
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: state.availableModules.map((mod) {
                            final isSelected = state.selectedModule == mod;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Semantics(
                                identifier: 'module_tab_${mod.toLowerCase()}',
                                label: '$mod module tab',
                                button: true,
                                selected: isSelected,
                                child: ChoiceChip(
                                  label: Text(
                                    mod.toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF0F4C81),
                                    ),
                                  ),
                                  selected: isSelected,
                                  selectedColor: const Color(0xFF0F4C81),
                                  backgroundColor: Theme.of(context).cardColor,
                                  onSelected: (_) =>
                                      cubit.setSelectedModule(mod),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Policy Grid List Body
                      Expanded(
                        child: Semantics(
                          container: true,
                          label:
                              'Policy list for module ${state.selectedModule}',
                          child: PolicyGridWidget(
                            policies: state.policies,
                            onTogglePolicy: cubit.togglePolicy,
                            onEditConditions: (permissionCode) {
                              _openConditionBuilder(
                                context,
                                cubit,
                                permissionCode,
                                state.policies,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
