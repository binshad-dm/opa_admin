import 'package:flutter/material.dart';

import '../../../../core/design/widgets/app_text_form_field.dart';

class CustomRegoEditorWidget extends StatelessWidget {
  final String snippet;
  final ValueChanged<String> onChanged;

  const CustomRegoEditorWidget({
    super.key,
    required this.snippet,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Write custom Rego code. You do not need to specify `package` or `allow_rule` / `deny_rule` headers. Just provide helper rules if needed, or directly write logic.",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade700),
            ),
            padding: const EdgeInsets.all(4),
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                child: AppTextFormField(
                  initialValue: snippet,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  hintText:
                      '# Write Rego code snippet here...\nallow {\n    input.user.role == "ADMIN"\n}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: Color(0xFFD4D4D4),
                    height: 1.4,
                  ),
                  decoration: const InputDecoration(
                    hintText:
                        '# Write Rego code snippet here...\nallow {\n    input.user.role == "ADMIN"\n}',
                    hintStyle: TextStyle(
                      color: Color(0xFF6A9955),
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.all(8),
                  ),
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
