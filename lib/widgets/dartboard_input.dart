import 'package:flutter/material.dart';
import 'package:d4rts/models/dart_throw.dart';

class DartboardInput extends StatefulWidget {
  final void Function(List<DartThrow> darts) onConfirm;
  final int maxDarts;

  const DartboardInput({
    super.key,
    required this.onConfirm,
    this.maxDarts = 3,
  });

  @override
  State<DartboardInput> createState() => _DartboardInputState();
}

class _DartboardInputState extends State<DartboardInput> {
  ThrowMultiplier _selectedMultiplier = ThrowMultiplier.single;
  final List<DartThrow> _darts = [];

  void _addDart(int value) {
    if (_darts.length >= widget.maxDarts) return;
    final dart = DartThrow(baseValue: value, multiplier: _selectedMultiplier);
    if (!dart.isValid) return;
    setState(() {
      _darts.add(dart);
      if (_darts.length >= widget.maxDarts) {
        // Auto-confirm
        _confirm();
      }
    });
  }

  void _addMiss() {
    if (_darts.length >= widget.maxDarts) return;
    setState(() {
      _darts.add(const DartThrow(baseValue: 0, multiplier: ThrowMultiplier.single));
    });
  }

  void _clear() {
    setState(() {
      _darts.clear();
      _selectedMultiplier = ThrowMultiplier.single;
    });
  }

  void _confirm() {
    if (_darts.isEmpty) return;
    final dartsToSubmit = List<DartThrow>.from(_darts);
    setState(() {
      _darts.clear();
      _selectedMultiplier = ThrowMultiplier.single;
    });
    widget.onConfirm(dartsToSubmit);
  }

  String _dartLabel(DartThrow d) {
    if (d.isMiss) return '0';
    if (d.multiplier == ThrowMultiplier.double_) return 'D${d.baseValue}';
    if (d.multiplier == ThrowMultiplier.triple) return 'T${d.baseValue}';
    return '${d.baseValue}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Dart entry display
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.maxDarts,
            (i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Container(
                width: 56,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                  color: i < _darts.length
                      ? colorScheme.primaryContainer
                      : colorScheme.surface,
                ),
                alignment: Alignment.center,
                child: Text(
                  i < _darts.length ? _dartLabel(_darts[i]) : '-',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Multiplier toggle
        SegmentedButton<ThrowMultiplier>(
          segments: const [
            ButtonSegment(
              value: ThrowMultiplier.single,
              label: Text('Single'),
            ),
            ButtonSegment(
              value: ThrowMultiplier.double_,
              label: Text('Double'),
            ),
            ButtonSegment(
              value: ThrowMultiplier.triple,
              label: Text('Triple'),
            ),
          ],
          selected: {_selectedMultiplier},
          onSelectionChanged: (s) {
            setState(() => _selectedMultiplier = s.first);
          },
        ),
        const SizedBox(height: 8),

        // Number grid: 1-20
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 10,
            childAspectRatio: 1.2,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
          ),
          itemCount: 20,
          itemBuilder: (ctx, i) {
            final n = i + 1;
            final isTripleAvailable = _selectedMultiplier == ThrowMultiplier.triple;
            // T25 is invalid but 25 will be in a separate row
            return _NumberButton(
              label: '$n',
              onTap: () => _addDart(n),
              enabled: _darts.length < widget.maxDarts,
              color: isTripleAvailable
                  ? colorScheme.tertiaryContainer
                  : _selectedMultiplier == ThrowMultiplier.double_
                      ? colorScheme.secondaryContainer
                      : null,
            );
          },
        ),
        const SizedBox(height: 4),

        // Row for 25 and Bull (D25=50)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _NumberButton(
              label: '25',
              onTap: () {
                // 25 is only valid for single or double
                if (_selectedMultiplier == ThrowMultiplier.triple) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Triple bull is not valid!')),
                  );
                  return;
                }
                _addDart(25);
              },
              enabled: _darts.length < widget.maxDarts &&
                  _selectedMultiplier != ThrowMultiplier.triple,
              wide: true,
            ),
            const SizedBox(width: 8),
            _NumberButton(
              label: 'Bull',
              onTap: () {
                setState(() => _selectedMultiplier = ThrowMultiplier.double_);
                _addDart(25);
              },
              enabled: _darts.length < widget.maxDarts,
              wide: true,
              color: colorScheme.secondaryContainer,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Action row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            OutlinedButton.icon(
              onPressed: _darts.length < widget.maxDarts ? _addMiss : null,
              icon: const Icon(Icons.close),
              label: const Text('Miss'),
            ),
            OutlinedButton.icon(
              onPressed: _darts.isNotEmpty ? _clear : null,
              icon: const Icon(Icons.clear),
              label: const Text('Clear'),
            ),
            FilledButton.icon(
              onPressed: _darts.isNotEmpty ? _confirm : null,
              icon: const Icon(Icons.check),
              label: const Text('Confirm'),
            ),
          ],
        ),
      ],
    );
  }
}

class _NumberButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final bool wide;
  final Color? color;

  const _NumberButton({
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.wide = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: wide ? 80 : null,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: enabled
                ? (color ?? theme.colorScheme.surfaceContainerHighest)
                : theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: enabled
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }
}
