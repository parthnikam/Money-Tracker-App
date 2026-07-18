import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// iOS-style press feedback: slight scale + opacity, light haptic.
class IosPressable extends StatefulWidget {
  const IosPressable({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.enabled = true,
    this.haptic = true,
    this.scale = 0.97,
  });

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final bool enabled;
  final bool haptic;
  final double scale;

  @override
  State<IosPressable> createState() => _IosPressableState();
}

class _IosPressableState extends State<IosPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled || widget.onTap == null) return;
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && widget.onTap != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      onTapUp: enabled ? (_) => _setPressed(false) : null,
      onTap: !enabled
          ? null
          : () {
              if (widget.haptic) {
                HapticFeedback.selectionClick();
              }
              widget.onTap?.call();
            },
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _pressed ? 0.88 : 1,
          duration: const Duration(milliseconds: 110),
          child: widget.child,
        ),
      ),
    );
  }
}
