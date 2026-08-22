import 'package:flutter/material.dart';

import '../../../../core/design/widgets/app_searchable_field.dart';
import '../../../../core/service_locator.dart';
import '../../domain/entities/dynamic_option_entity.dart';
import '../../domain/usecases/get_dynamic_options_usecase.dart';

class DynamicDropdownWidget extends StatefulWidget {
  final String endpoint;
  final String permissionCode;
  final dynamic value;
  final ValueChanged<String> onChange;

  const DynamicDropdownWidget({
    super.key,
    required this.endpoint,
    required this.permissionCode,
    required this.value,
    required this.onChange,
  });

  @override
  State<DynamicDropdownWidget> createState() => _DynamicDropdownWidgetState();
}

class _DynamicDropdownWidgetState extends State<DynamicDropdownWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.value != null && widget.value.toString().isNotEmpty) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  void didUpdateWidget(DynamicDropdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _controller.text = widget.value?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<List<DynamicOptionEntity>> _fetchOptions(String query) async {
    final useCase = sl<GetDynamicOptionsUseCase>();
    final result = await useCase(
      permissionCode: widget.permissionCode,
      endpoint: widget.endpoint,
      page: 0,
      search: query,
    );

    return result.fold(
      (_) => <DynamicOptionEntity>[],
      (data) => (data['content'] as List<dynamic>? ?? []).cast<DynamicOptionEntity>(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: AppSearchableField<DynamicOptionEntity>(
        controller: _controller,
        hintText: 'Select option...',
        suggestionsCallback: _fetchOptions,
        itemToString: (opt) => opt.displayName,
        itemBuilder: (context, opt) {
          return Text(
            opt.displayName,
            style: const TextStyle(fontSize: 13),
          );
        },
        onSuggestionSelected: (opt) {
          widget.onChange(opt.id);
        },
        onChanged: (text) {
          widget.onChange(text);
        },
      ),
    );
  }
}
