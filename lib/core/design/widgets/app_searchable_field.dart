import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class AppSearchableField<T> extends StatefulWidget {
  final String? label;
  final String? hintText;
  final FutureOr<List<T>> Function(String query) suggestionsCallback;
  final Widget Function(BuildContext context, T suggestion) itemBuilder;
  final void Function(T suggestion) onSuggestionSelected;
  final String Function(T suggestion) itemToString;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool required;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final bool readOnly;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool? isDense;

  const AppSearchableField(
      {super.key,
      this.label,
      this.hintText,
      required this.suggestionsCallback,
      required this.itemBuilder,
      required this.onSuggestionSelected,
      required this.itemToString,
      this.controller,
      this.focusNode,
      this.required = false,
      this.validator,
      this.onChanged,
      this.onFieldSubmitted,
      this.readOnly = false,
      this.prefixIcon,
      this.suffixIcon,
      this.isDense = false});

  @override
  State<AppSearchableField<T>> createState() => _AppSearchableFieldState<T>();
}

class _AppSearchableFieldState<T> extends State<AppSearchableField<T>> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  final MenuController _menuController = MenuController();

  bool _isLoading = false;
  List<T> _suggestions = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(AppSearchableField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool changed = false;
    if (widget.controller != oldWidget.controller &&
        widget.controller != null) {
      _controller = widget.controller!;
      changed = true;
    }
    if (widget.focusNode != oldWidget.focusNode && widget.focusNode != null) {
      _focusNode.removeListener(_onFocusChange);
      _focusNode = widget.focusNode!;
      _focusNode.addListener(_onFocusChange);
      changed = true;
    }
    if (changed) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChange);
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      if (!_menuController.isOpen) {
        _menuController.open();
      }
      _onSearch(_controller.text);
    }
  }

  void _onSearch(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted || !_focusNode.hasFocus) return;

      setState(() => _isLoading = true);
      if (!_menuController.isOpen) {
        _menuController.open();
      }

      try {
        final results = await widget.suggestionsCallback(query);
        if (mounted && _focusNode.hasFocus) {
          setState(() {
            _suggestions = results;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _suggestions = [];
          });
        }
      }
    });
  }

  void _handleSuggestionSelected(T suggestion) {
    final text = widget.itemToString(suggestion);
    _controller.text = text;
    widget.onSuggestionSelected(suggestion);
    widget.onChanged?.call(text);
    if (_menuController.isOpen) {
      _menuController.close();
    }
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Row(
            children: [
              Text(widget.label!,
                  style: const TextStyle(
                    fontSize: 12,
                  )),
              if (widget.required)
                const Text(' *',
                    style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
            ],
          ),
          const Gap(4),
        ],
        LayoutBuilder(builder: (context, constraints) {
          return MenuAnchor(
            controller: _menuController,
            crossAxisUnconstrained: false,
            style: MenuStyle(
              elevation: MaterialStateProperty.all(8),
              shape: MaterialStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              backgroundColor: MaterialStateProperty.all(Colors.white),
              padding: MaterialStateProperty.all(EdgeInsets.zero),
              minimumSize:
                  MaterialStateProperty.all(Size(constraints.maxWidth, 0)),
              maximumSize:
                  MaterialStateProperty.all(Size(constraints.maxWidth, 300)),
            ),
            menuChildren: _buildMenuChildren(),
            builder: (context, controller, child) {
              return TextFormField(
                controller: _controller,
                focusNode: _focusNode,
                readOnly: widget.readOnly,
                onChanged: (val) {
                  _onSearch(val);
                  widget.onChanged?.call(val);
                },
                onFieldSubmitted: widget.onFieldSubmitted,
                validator: widget.validator,
                style: const TextStyle(fontSize: 13, color: Colors.black),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.normal),
                  filled: true,
                  fillColor: widget.readOnly
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFFF8FAFC),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  isDense: widget.isDense,
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 24,
                  ),
                  suffixIconConstraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 24,
                  ),
                  prefixIcon: widget.prefixIcon,
                  suffixIcon: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : (widget.suffixIcon ??
                          const Icon(Icons.search,
                              size: 18, color: Color(0xFF94A3B8))),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF0F4C81), width: 2),
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }

  List<Widget> _buildMenuChildren() {
    if (_isLoading && _suggestions.isEmpty) {
      return [
        Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              Gap(10),
              Text('Searching...',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
        )
      ];
    }

    if (_suggestions.isEmpty && !_isLoading) {
      return [
        Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: const Text(
            'No results found',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        )
      ];
    }

    return _suggestions.map((suggestion) {
      return InkWell(
        onTap: () => _handleSuggestionSelected(suggestion),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: widget.itemBuilder(context, suggestion),
        ),
      );
    }).toList();
  }
}
