import 'package:flutter/material.dart';
import '../services/autocomplete_service.dart';
import '../utils/constants.dart';

/// 자동완성 텍스트 필드 위젯
class AutocompleteTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final FormFieldValidator<String>? validator;
  final ValueChanged<AutocompleteSuggestion>? onSuggestionSelected;
  final VoidCallback? onEditingComplete;
  final bool autofocus;

  const AutocompleteTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.validator,
    this.onSuggestionSelected,
    this.onEditingComplete,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return _AutocompleteTextField(
      controller: controller,
      focusNode: focusNode,
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      autofocus: autofocus,
      validator: validator,
      onEditingComplete: onEditingComplete,
      onSuggestionSelected: onSuggestionSelected,
    );
  }
}

/// 한글 입력을 지원하는 자체 구현 Autocomplete TextField
class _AutocompleteTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final bool autofocus;
  final String? Function(String?)? validator;
  final VoidCallback? onEditingComplete;
  final Function(AutocompleteSuggestion)? onSuggestionSelected;

  const _AutocompleteTextField({
    required this.controller,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.autofocus = false,
    this.validator,
    this.onEditingComplete,
    this.onSuggestionSelected,
  });

  @override
  State<_AutocompleteTextField> createState() => _AutocompleteTextFieldState();
}

class _AutocompleteTextFieldState extends State<_AutocompleteTextField> {
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<AutocompleteSuggestion> _suggestions = [];
  bool _isLoading = false;
  final AutocompleteService _autocompleteService = AutocompleteService();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    _updateSuggestions();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _updateSuggestions();
    } else {
      _removeOverlay();
    }
  }

  void _updateSuggestions() async {
    final text = widget.controller.text;
    if (text.isEmpty) {
      _removeOverlay();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final suggestions = await _autocompleteService.getSuggestions(text);
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isLoading = false;
        });
        _showOverlay();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isLoading = false;
        });
      }
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: const Offset(0, 60),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: _suggestions.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        '검색 결과가 없습니다',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        return ListTile(
                          leading: Text(
                            suggestion.icon,
                            style: const TextStyle(fontSize: 24),
                          ),
                          title: Text(suggestion.name),
                          subtitle: suggestion.category != null
                              ? Text(suggestion.category!)
                              : null,
                          trailing: suggestion.source == SuggestionSource.favorite
                              ? const Icon(Icons.star, color: AppConstants.warningYellow, size: 20)
                              : suggestion.usageCount != null && suggestion.usageCount! > 1
                                  ? Text(
                                      '${suggestion.usageCount}회',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    )
                                  : null,
                          onTap: () {
                            widget.controller.text = suggestion.name;
                            if (widget.onSuggestionSelected != null) {
                              widget.onSuggestionSelected!(suggestion);
                            }
                            _removeOverlay();
                            _focusNode.unfocus();
                          },
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        focusNode: widget.focusNode ?? _focusNode,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
          suffixIcon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : null,
        ),
        autofocus: widget.autofocus,
        textCapitalization: TextCapitalization.none,
        textInputAction: TextInputAction.done,
        keyboardType: TextInputType.text,
        enableSuggestions: true,
        autocorrect: true,
        validator: widget.validator,
        onEditingComplete: widget.onEditingComplete,
        onChanged: (value) {
          // 한글 입력을 위해 즉시 업데이트
          _updateSuggestions();
        },
      ),
    );
  }
}

