import 'package:flutter/material.dart';

import '../../../../../core/design/widgets/app_dropdown_field.dart';
import '../../../../../core/service_locator.dart';
import '../../../domain/entities/dynamic_option_entity.dart';
import '../../../domain/usecases/get_dynamic_options_usecase.dart';

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
  List<DynamicOptionEntity> _options = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOptions();
  }

  @override
  void didUpdateWidget(DynamicDropdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.endpoint != oldWidget.endpoint ||
        widget.permissionCode != oldWidget.permissionCode) {
      _fetchOptions();
    }
  }

  Future<void> _fetchOptions() async {
    setState(() => _isLoading = true);
    final useCase = sl<GetDynamicOptionsUseCase>();
    final result = await useCase(
      permissionCode: widget.permissionCode,
      endpoint: widget.endpoint,
      page: 0,
      search: '',
    );

    if (mounted) {
      result.fold(
        (_) => setState(() {
          _options = [];
          _isLoading = false;
        }),
        (data) => setState(() {
          _options = (data['content'] as List<dynamic>? ?? [])
              .cast<DynamicOptionEntity>();
          _isLoading = false;
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: 140,
        height: 38,
        child: Center(
          child: Semantics(
            label: 'Loading dynamic options',
            child: const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    final items = _options
        .map(
          (opt) => DropdownMenuItem<String>(
            value: opt.id,
            child: Text(
              opt.displayName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        )
        .toList();

    final currentVal = items.any((i) => i.value == widget.value?.toString())
        ? widget.value?.toString()
        : null;

    return Expanded(
      child: Semantics(
        identifier: 'dynamic_dropdown_${widget.permissionCode}',
        label: 'Select dynamic option for ${widget.permissionCode}',
        button: true,
        child: AppDropdownField<String>(
          value: currentVal,
          hintText: 'Select option...',
          items: items,
          onChanged: (val) {
            if (val != null) widget.onChange(val);
          },
        ),
      ),
    );
  }
}
