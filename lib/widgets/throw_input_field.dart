import 'package:flutter/material.dart';
import 'package:d4rts/utils/dart_input_parser.dart';

class ThrowInputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool autoFocus;
  final VoidCallback? onNext;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;

  const ThrowInputField({
    super.key,
    required this.controller,
    required this.label,
    this.autoFocus = false,
    this.onNext,
    this.focusNode,
    this.nextFocusNode,
  });

  @override
  State<ThrowInputField> createState() => _ThrowInputFieldState();
}

class _ThrowInputFieldState extends State<ThrowInputField> {
  String? _error;

  void _validate(String value) {
    if (value.isEmpty) {
      setState(() => _error = null);
      return;
    }
    if (!DartInputParser.isValid(value)) {
      setState(() => _error = 'Invalid (e.g. 20, D16, T20, 25)');
    } else {
      setState(() => _error = null);
      // Auto-advance to next field if valid
      if (widget.nextFocusNode != null) {
        widget.nextFocusNode!.requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      autofocus: widget.autoFocus,
      textCapitalization: TextCapitalization.characters,
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: _error,
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      ),
      onChanged: _validate,
      onSubmitted: (_) {
        widget.onNext?.call();
        if (widget.nextFocusNode != null) {
          widget.nextFocusNode!.requestFocus();
        }
      },
      textInputAction: widget.nextFocusNode != null
          ? TextInputAction.next
          : TextInputAction.done,
    );
  }
}
