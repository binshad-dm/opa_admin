import 'package:flutter/material.dart';

import '../../../../../core/design/widgets/app_dropdown_field.dart';
import '../../../domain/entities/role_dto_entity.dart';
import '../../../domain/entities/user_dto_entity.dart';

class SubjectSelectorWidget extends StatelessWidget {
  final String subjectType; // ROLE or USER
  final String subjectId;
  final List<RoleDtoEntity> roles;
  final List<UserDtoEntity> users;
  final ValueChanged<String> onSubjectTypeChanged;
  final ValueChanged<String> onSubjectIdChanged;
  final bool isLoading;

  const SubjectSelectorWidget({
    super.key,
    required this.subjectType,
    required this.subjectId,
    required this.roles,
    required this.users,
    required this.onSubjectTypeChanged,
    required this.onSubjectIdChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isRole = subjectType == 'ROLE';

    List<DropdownMenuItem<String>> items = [];
    if (isRole) {
      items = roles
          .map(
            (r) => DropdownMenuItem<String>(
              value: r.id,
              child: Text(
                r.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          )
          .toList();
    } else {
      items = users
          .map(
            (u) => DropdownMenuItem<String>(
              value: u.id,
              child: Text(
                u.displayName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          )
          .toList();
    }

    final validValue = items.any((i) => i.value == subjectId)
        ? subjectId
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 480;

        final typeDropdown = Semantics(
          identifier: 'subject_type_dropdown',
          label: 'Subject Type',
          hint: 'Select subject type: Role or User',
          button: true,
          child: AppDropdownField<String>(
            label: 'Subject Type',
            value: subjectType,
            items: const [
              DropdownMenuItem(
                value: 'ROLE',
                child: Text('Role', style: TextStyle(fontSize: 13)),
              ),
              DropdownMenuItem(
                value: 'USER',
                child: Text('User', style: TextStyle(fontSize: 13)),
              ),
            ],
            onChanged: (val) {
              if (val != null) onSubjectTypeChanged(val);
            },
          ),
        );

        final subjectDropdown = Semantics(
          identifier: 'subject_id_dropdown',
          label: isRole ? 'Select Role' : 'Select User',
          hint:
              'Select ${isRole ? "role" : "user"} to view and manage policies',
          button: true,
          child: AppDropdownField<String>(
            label: 'Subject',
            value: validValue,
            hintText: isLoading ? 'Loading subjects...' : 'Select Subject...',
            readOnly: isLoading || items.isEmpty,
            items: items,
            onChanged: (val) {
              if (val != null) onSubjectIdChanged(val);
            },
          ),
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              typeDropdown,
              const SizedBox(height: 12),
              subjectDropdown,
            ],
          );
        }

        return Wrap(
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(width: 160, child: typeDropdown),
            SizedBox(
              width: constraints.maxWidth > 650 ? 320 : 260,
              child: subjectDropdown,
            ),
          ],
        );
      },
    );
  }
}
