import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../domain/app_lock.dart';
import '../../../domain/models/app_lock.dart';
import '../../../l10n/app_localizations.dart';
import '../tokens.dart';

/// [PinPad.state]: what the keys do.
enum PinPadState {
  normal,

  /// Held after too many wrong pins: digits and ⌫ dim and stop answering,
  /// the biometric key stays live.
  locked,

  /// The biometric slot is empty (new face / fingerprint, not trusted yet).
  bioHidden,
}

/// 00.31 PinPad — 6 dots over a 3×4 keypad: digits, a biometric key where the
/// "000" of AmountKeypad would be, ⌫. Shows [message] under the dots; [error]
/// shakes them once.
class PinPad extends StatefulWidget {
  const PinPad({
    super.key,
    required this.filled,
    required this.onKey,
    required this.onBackspace,
    this.message = '',
    this.error = false,
    this.state = PinPadState.normal,
    this.bio = BioKind.none,
    this.onBio,
  });

  static const width = 300.0;
  static const _rowHeight = 60.0, _gap = 10.0;

  final int filled;
  final String message;
  final bool error;
  final PinPadState state;
  final BioKind bio;
  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;
  final VoidCallback? onBio;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> with SingleTickerProviderStateMixin {
  late final _shake = AnimationController(
    vsync: this,
    duration: AppMotion.wiggle,
  );

  @override
  void didUpdateWidget(PinPad old) {
    super.didUpdateWidget(old);
    if (widget.error && !old.error) _shake.forward(from: 0);
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  // The design's mibu-shake: 0, -8, 8, -5, 5, 0.
  double _dx(double t) => switch (t) {
    < 0.2 => -8 * t / 0.2,
    < 0.4 => -8 + 16 * (t - 0.2) / 0.2,
    < 0.6 => 8 - 13 * (t - 0.4) / 0.2,
    < 0.8 => -5 + 10 * (t - 0.6) / 0.2,
    _ => 5 - 5 * (t - 0.8) / 0.2,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final held = widget.state == PinPadState.locked;
    final n = widget.filled.clamp(0, pinLength);
    final emphasis = widget.error || held;

    Widget digit(String k) => _Key(
      label: k,
      dim: held,
      onTap: held ? null : () => widget.onKey(k),
      color: AppColors.mist,
      child: Text(k, style: AppText.label.copyWith(fontSize: 26)),
    );

    Widget row(List<Widget> keys) => Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PinPad._gap,
        children: [for (final k in keys) Expanded(child: k)],
      ),
    );

    final bioShown =
        widget.bio != BioKind.none && widget.state != PinPadState.bioHidden;

    return Semantics(
      container: true,
      label: l.pinPadLabel(n),
      child: SizedBox(
        width: PinPad.width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: AnimatedBuilder(
                animation: _shake,
                builder: (_, child) => Transform.translate(
                  offset: Offset(_dx(_shake.value), 0),
                  child: child,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 14,
                  children: [
                    for (var i = 0; i < pinLength; i++)
                      Container(
                        key: ValueKey('pin-dot-$i-${i < n ? 'on' : 'off'}'),
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < n ? AppColors.ink : null,
                          border: i < n
                              ? null
                              : Border.all(
                                  width: AppStroke.outline,
                                  color: widget.error
                                      ? AppColors.ink
                                      : AppColors.line,
                                ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Semantics(
              liveRegion: true,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 20),
                child: Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: AppText.caption.copyWith(
                    fontSize: 14,
                    fontWeight: emphasis ? FontWeight.w600 : FontWeight.w400,
                    color: emphasis ? AppColors.ink : AppColors.muted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: PinPad._rowHeight * 4 + PinPad._gap * 3,
              child: Column(
                spacing: PinPad._gap,
                children: [
                  row([digit('1'), digit('2'), digit('3')]),
                  row([digit('4'), digit('5'), digit('6')]),
                  row([digit('7'), digit('8'), digit('9')]),
                  row([
                    if (bioShown)
                      _Key(
                        label: widget.bio == BioKind.face
                            ? l.pinPadBioFace
                            : l.pinPadBioFinger,
                        outline: AppColors.ink,
                        onTap: widget.onBio,
                        child: HugeIcon(
                          icon: widget.bio == BioKind.face
                              ? AppIcons.faceId
                              : AppIcons.fingerprint,
                          size: 26,
                          strokeWidth: AppStroke.icon,
                          color: AppColors.ink,
                        ),
                      )
                    else
                      const ExcludeSemantics(child: SizedBox.shrink()),
                    digit('0'),
                    _Key(
                      label: l.keyBackspace,
                      outline: AppColors.ink,
                      dim: held,
                      onTap: held ? null : widget.onBackspace,
                      child: const HugeIcon(
                        icon: AppIcons.backspace,
                        size: 24,
                        strokeWidth: AppStroke.icon,
                        color: AppColors.ink,
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    required this.label,
    required this.onTap,
    required this.child,
    this.color = AppColors.paper,
    this.outline,
    this.dim = false,
  });

  final String label;
  final VoidCallback? onTap; // null = does nothing (held, or no handler)
  final Widget child;
  final Color color;
  final Color? outline;
  final bool dim; // held: 35%

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: outline == null
          ? BorderSide.none
          : BorderSide(color: outline!, width: AppStroke.outline),
    );
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: Opacity(
        opacity: dim ? 0.35 : 1,
        child: Material(
          color: color,
          shape: shape,
          child: InkWell(
            customBorder: shape,
            onTap: onTap,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
