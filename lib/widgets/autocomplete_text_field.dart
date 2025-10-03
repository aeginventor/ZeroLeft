import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../services/autocomplete_service.dart';
import '../utils/constants.dart';

/// 자동완성 텍스트 필드 위젯
class AutocompleteTextField extends StatelessWidget {
  final TextEditingController controller;
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
    final autocompleteService = AutocompleteService();

    return TypeAheadField<AutocompleteSuggestion>(
      controller: controller,
      builder: (context, controller, focusNode) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: labelText,
            hintText: hintText,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
          ),
          autofocus: autofocus,
          textCapitalization: TextCapitalization.words,
          validator: validator,
          onEditingComplete: onEditingComplete,
        );
      },
      suggestionsCallback: (pattern) async {
        return await autocompleteService.getSuggestions(pattern);
      },
      itemBuilder: (context, suggestion) {
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
        );
      },
      onSelected: (suggestion) {
        controller.text = suggestion.name;
        if (onSuggestionSelected != null) {
          onSuggestionSelected!(suggestion);
        }
      },
      emptyBuilder: (context) {
        return const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '검색 결과가 없습니다',
            style: TextStyle(color: Colors.grey),
          ),
        );
      },
      errorBuilder: (context, error) {
        return const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '오류가 발생했습니다',
            style: TextStyle(color: Colors.red),
          ),
        );
      },
      loadingBuilder: (context) {
        return const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}

