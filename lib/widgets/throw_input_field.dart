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

  /// Returns true when the input is definitively complete and cannot be
  /// extended to another valid dart input (e.g. "20", "D17", "T20", "25", "D25").
  /// Single-digit entries like "1"–"9" are NOT complete (could become "10"–"19").
  /// Prefixed entries like "D2" or "T3" are NOT complete (could become "D20"/"T20").
  bool _isDefinitivelyComplete(String input) {
    final upper = input.trim().toUpperCase();
    if (upper.isEmpty) return false;

    // 3-character inputs are always the longest valid form (D25, T20, D17, etc.)
    if (upper.length >= 3) return DartInputParser.isValid(upper);

    // "25" – single bull (two-char number, cannot be extended)
    if (upper == '25') return true;

    // Two-digit numbers 10–20 (cannot be extended further)
    final n = int.tryParse(upper);
    if (n != null && n >= 10 && n <= 20) return true;

    // Everything else (single digit "1"–"9", "D1"–"D9", "T1"–"T9") could
    // still receive another character, so do NOT auto-advance yet.
    return false;
  }

  void _validate(String value) {
    if (value.isEmpty) {
      setState(() => _error = null);
      return;
    }
    if (!DartInputParser.isValid(value)) {
      setState(() => _error = 'Invalid (e.g. 20, D16, T20, 25)');
    } else {
      setState(() => _error = null);
      // Auto-advance only when the input is unambiguously complete
      if (_isDefinitivelyComplete(value) && widget.nextFocusNode != null) {
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
