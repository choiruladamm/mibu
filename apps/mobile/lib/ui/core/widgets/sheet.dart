import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../l10n/app_localizations.dart';
import '../tokens.dart';
import 'app_emoji.dart';

/// Opens [child] as a mibu bottom sheet (radius 32, scrim 45% from theme).
/// [enableDrag] false: only [SheetFrame.handleDrag] closes it by swiping —
/// for sheets with a keypad, where a swipe is easy to start by accident.
Future<T?> showAppSheet<T>(
  BuildContext context,
  Widget child, {
  bool enableDrag = true,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  enableDrag: enableDrag,
  builder: (_) => child,
);

/// Handle + title + close disc; [height] is the design's sheet height.
class SheetFrame extends StatelessWidget {
  const SheetFrame({
    super.key,
    required this.title,
    required this.height,
    required this.child,
    this.actions = const [],
    this.titleSize = 22,
    this.sub,
    this.scrollable = true,
    this.close,
    this.handleDrag = false,
  });

  final String title;
  final String? sub; // muted line under the title, inside the header
  final double height, titleSize;
  final List<Widget> actions;
  final Widget child;

  /// Replaces the close disc, e.g. 03.3's "beres".
  final Widget? close;

  /// Swipe down on the handle closes; pair with `enableDrag: false`.
  final bool handleDrag;

  /// Scroll [child] when the screen is shorter than [height]. Turn off when
  /// [child] scrolls itself (e.g. holds a GridView).
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final compact = titleSize < 26; // 00.12 / 00.13: smaller handle + close
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Handle(
                width: compact ? 36 : 40,
                onClose: handleDrag ? () => Navigator.of(context).pop() : null,
              ),
              SizedBox(height: compact ? 14 : 12),
              Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 4,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            title,
                            style: AppText.sheetTitle.copyWith(
                              fontSize: titleSize,
                            ),
                          ),
                        ),
                        if (sub != null)
                          Text(
                            sub!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.label.copyWith(
                              fontSize: 14,
                              color: AppColors.muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  ...actions,
                  close ??
                      CircleButton(
                        icon: HugeIcons.strokeRoundedCancel01,
                        label: l.close,
                        size: compact ? 40 : 44,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                ],
              ),
              Expanded(
                child: scrollable
                    ? CustomScrollView(
                        slivers: [
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: child,
                          ),
                        ],
                      )
                    : child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mist icon disc (close, calendar, arrows).
class CircleButton extends StatelessWidget {
  const CircleButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.size = 44,
    this.iconSize = 18,
    this.ink = false,
    this.color = AppColors.mist,
  });

  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback? onTap;
  final double size, iconSize;
  final bool ink; // filled ink (e.g. calendar while its sheet is open)
  final Color color;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ink ? AppColors.ink : (enabled ? color : Colors.transparent),
          ),
          child: HugeIcon(
            icon: icon,
            size: iconSize,
            strokeWidth: AppStroke.icon,
            color: ink
                ? AppColors.paper
                : enabled
                ? AppColors.ink
                : AppColors.line,
          ),
        ),
      ),
    );
  }
}

/// 56 ink pill — the one primary action per screen/sheet.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed; // null = disabled
  final List<List<dynamic>>? icon;

  @override
  Widget build(BuildContext context) {
    final fg = onPressed == null ? AppColors.subtle : AppColors.paper;
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.ink,
        disabledBackgroundColor: AppColors.mist,
        foregroundColor: AppColors.paper,
        disabledForegroundColor: AppColors.subtle,
        minimumSize: const Size.fromHeight(56),
        shape: const StadiumBorder(),
        textStyle: AppText.body.copyWith(fontSize: 17),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 10,
        children: [
          if (icon != null)
            HugeIcon(
              icon: icon!,
              size: 20,
              strokeWidth: AppStroke.iconOnInkSmall,
              color: fg,
            ),
          // "pakai 🍜 makan": the emoji is drawn, button size (00.20: 24).
          Flexible(
            child: EmojiText(
              label,
              emojiSize: 24,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _Handle extends StatefulWidget {
  const _Handle({required this.width, required this.onClose});

  final double width;
  final VoidCallback? onClose; // null = the sheet itself drags

  @override
  State<_Handle> createState() => _HandleState();
}

class _HandleState extends State<_Handle> {
  double _dy = 0;

  @override
  Widget build(BuildContext context) {
    final bar = Center(
      child: Container(
        width: widget.width,
        height: 5,
        decoration: BoxDecoration(
          color: AppColors.line,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
    final close = widget.onClose;
    if (close == null) return bar;
    // Taller hit area than the 5px bar.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (_) => _dy = 0,
      onVerticalDragUpdate: (d) => _dy += d.delta.dy,
      onVerticalDragEnd: (d) {
        if (_dy > 48 || (d.primaryVelocity ?? 0) > 400) close();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: bar,
      ),
    );
  }
}
