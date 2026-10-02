import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/dashed.dart';
import '../../../core/money.dart';
import '../../../core/tokens.dart';

/// 01.1 onboarding — one widget, step 1 | 2 | 3.
class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key, required this.onDone, this.initialStep = 1});

  /// lewati / mulai sekarang → 01.2 masuk.
  final VoidCallback onDone;
  final int initialStep;

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  late int _step = widget.initialStep;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Decode the step 2/3 art now so it's ready when the step fades in.
    for (final i in [2, 3]) {
      precacheImage(
        AssetImage('assets/images/onboarding_$i.png'),
        context,
        onError: (_, _) {},
      );
    }
  }

  /// Crossfade on [_step]; the old child fades out on top, the new one sets
  /// the size.
  /// [fill]: both children get the whole box (the fixed-height art).
  Widget _swap(Widget child, {bool fill = false}) => AnimatedSwitcher(
    duration: AppMotion.select,
    layoutBuilder: (current, previous) => Stack(
      alignment: Alignment.topLeft,
      fit: fill ? StackFit.expand : StackFit.loose,
      children: [
        for (final p in previous)
          if (fill)
            Positioned.fill(child: p)
          else
            Positioned(top: 0, left: 0, right: 0, child: p),
        ?current,
      ],
    ),
    child: KeyedSubtree(key: ValueKey(_step), child: child),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isLast = _step == 3;
    final (title, body) = switch (_step) {
      1 => (l.onboarding1Title, l.onboarding1Body),
      2 => (l.onboarding2Title, l.onboarding2Body),
      _ => (l.onboarding3Title, l.onboarding3Body),
    };

    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 56, 24, 28),
        // Scrolls only when the screen is shorter than the design (e.g. SE).
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Segments(
                    step: _step,
                    onPick: (i) => setState(() => _step = i),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('mibu', style: AppText.wordmark(26)),
                        if (!isLast)
                          TextButton(
                            onPressed: widget.onDone,
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.mist,
                              foregroundColor: AppColors.ink,
                              minimumSize: const Size(0, 36),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              shape: const StadiumBorder(),
                              textStyle: AppText.label.copyWith(fontSize: 14),
                            ),
                            child: Text(l.onboardingSkip),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 340,
                    child: _swap(
                      fill: true,
                      Center(
                        child: switch (_step) {
                          1 => const _PocketsIllustration(),
                          // 2/3: images rendered from the design board (24px pad
                          // around the 342×340 frame so rotated chips/shadow fit).
                          _ => OverflowBox(
                            maxWidth: 390,
                            maxHeight: 388,
                            child: Image.asset(
                              'assets/images/onboarding_$_step.png',
                              width: 390,
                              height: 388,
                              excludeFromSemantics: true,
                            ),
                          ),
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _swap(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.onboardingCounter(_step),
                          style: AppText.caption.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          style: AppText.title.copyWith(
                            fontSize: 34,
                            letterSpacing: -0.03 * 34,
                            height: 1.08,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          body,
                          style: AppText.label.copyWith(
                            height: 1.45,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: isLast
                        ? widget.onDone
                        : () => setState(() => _step++),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: AppColors.paper,
                      minimumSize: const Size.fromHeight(56),
                      shape: const StadiumBorder(),
                      textStyle: AppText.body.copyWith(fontSize: 17),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 8,
                      children: [
                        Text(isLast ? l.onboardingStart : l.onboardingNext),
                        const HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowRight02,
                          size: 20,
                          strokeWidth: AppStroke.iconOnInkSmall,
                          color: AppColors.paper,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 48,
                    child: Center(
                      child: Text(
                        l.onboardingFooter,
                        style: AppText.label.copyWith(
                          fontSize: 14,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stories-style progress; tap a segment to jump.
class _Segments extends StatelessWidget {
  const _Segments({required this.step, required this.onPick});

  final int step;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Row(
      spacing: 6,
      children: [
        for (var i = 1; i <= 3; i++)
          Expanded(
            child: Semantics(
              button: true,
              selected: i == step,
              label: l.onboardingStepLabel(i),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onPick(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: AnimatedContainer(
                    duration: AppMotion.select,
                    curve: AppMotion.ease,
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= step ? AppColors.ink : AppColors.track,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Step 1: gaji → three pocket jars. Amounts are sample data.
class _PocketsIllustration extends StatelessWidget {
  const _PocketsIllustration();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SizedBox(
      width: 342,
      height: 340,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            left: 0,
            top: 40,
            child: CustomPaint(size: Size(342, 120), painter: _FlowPainter()),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(22),
              ),
              alignment: Alignment.center,
              child: Text.rich(
                TextSpan(
                  text: '💼  ${l.onboardingSalaryIn} · ',
                  children: [
                    TextSpan(
                      text: rupiahCompact(8500000),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                style: AppText.label.copyWith(
                  fontSize: 15,
                  color: AppColors.paper,
                ),
              ),
            ),
          ),
          const _Coin(left: 78, top: 66, deg: -14),
          const _Coin(left: 158, top: 78, deg: 8),
          const _Coin(left: 248, top: 62, deg: 18),
          Positioned(
            left: 9,
            top: 118,
            child: _Jar(
              emoji: '🍜',
              name: l.pocketFood,
              amount: 1500000,
              fill: 0.72,
            ),
          ),
          Positioned(
            left: 122,
            top: 118,
            child: _Jar(
              emoji: '☕',
              name: l.pocketCoffee,
              amount: 300000,
              fill: 0.38,
              fillColor: AppColors.onInkMuted,
            ),
          ),
          Positioned(
            left: 235,
            top: 118,
            child: _Jar(
              emoji: '✈️',
              name: l.pocketHoliday,
              amount: 1000000,
              fill: 0.86,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dashed lines from the salary pill down to each jar.
class _FlowPainter extends CustomPainter {
  const _FlowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(171, 6)
      ..cubicTo(171, 50, 58, 50, 58, 92)
      ..moveTo(171, 6)
      ..lineTo(171, 92)
      ..moveTo(171, 6)
      ..cubicTo(171, 50, 284, 50, 284, 92);
    canvas.drawPath(
      dashPath(path),
      Paint()
        ..color = AppColors.line
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppStroke.outline,
    );
  }

  @override
  bool shouldRepaint(_FlowPainter old) => false;
}

class _Coin extends StatelessWidget {
  const _Coin({required this.left, required this.top, required this.deg});

  final double left, top, deg;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: Transform.rotate(
        angle: deg * math.pi / 180,
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.ink,
            shape: BoxShape.circle,
          ),
          child: Text(
            'Rp',
            style: AppText.micro.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.paper,
            ),
          ),
        ),
      ),
    );
  }
}

class _Jar extends StatelessWidget {
  const _Jar({
    required this.emoji,
    required this.name,
    required this.amount,
    required this.fill,
    this.fillColor = AppColors.ink,
  });

  final String emoji, name;
  final int amount;
  final double fill;
  final Color fillColor;

  static const _shape = BorderRadius.vertical(
    top: Radius.circular(40),
    bottom: Radius.circular(24),
  );

  @override
  Widget build(BuildContext context) {
    final outline = Border.all(color: AppColors.ink, width: AppStroke.outline);
    return SizedBox(
      width: 98,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 30), // disc 44 overlaps 14
                width: 98,
                height: 160,
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: _shape,
                ),
                foregroundDecoration: BoxDecoration(
                  border: outline,
                  borderRadius: _shape,
                ),
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: fill,
                  widthFactor: 1,
                  child: ColoredBox(color: fillColor),
                ),
              ),
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  shape: BoxShape.circle,
                  border: outline,
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: AppText.label.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            rupiahCompact(amount),
            style: AppText.caption.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
