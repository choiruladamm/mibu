import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../data/biometrics.dart';
import '../../../../domain/models/app_lock.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/app_lock_providers.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/app_switch.dart';
import '../../../core/widgets/nav_header.dart';
import '../../../core/widgets/toast.dart';
import '../../settings/view_models/settings_view_model.dart';
import '../view_models/lock_labels.dart';
import 'lock_flow_sheet.dart';

/// 99.10b–d kunci app: on / off, how it opens, when it asks again, blur.
class LockSettingsView extends ConsumerWidget {
  const LockSettingsView({super.key});

  Future<void> _flow(BuildContext context, LockFlow flow, BioKind kind) async {
    final toast = await showLockFlow(context, flow, kind: kind);
    if (toast == null || !context.mounted) return;
    showToast(
      context,
      icon: ToastIcon.check,
      title: toast.title,
      sub: toast.sub,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final lock = ref.watch(appLockProvider).value;
    if (lock == null) return const Scaffold();
    final kind = ref.watch(bioKindProvider).value ?? BioKind.none;
    final controller = ref.read(appLockProvider.notifier);
    final bio = kind.word(l);
    final android = defaultTargetPlatform != TargetPlatform.iOS;
    final bioOn = lock.bio && kind != BioKind.none;

    Future<void> toggleBio(bool on) async {
      if (!on) return controller.setBio(false);
      if (lock.bioChanged) return _flow(context, LockFlow.bioAgain, kind);
      // Ask once now: shows the iOS permission, and proves it works.
      final ok = await ref
          .read(biometricsProvider)
          .authenticate(l.lockBioReason);
      if (ok) await controller.setBio(true);
    }

    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.only(top: AppSpace.s48),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppSpace.s32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NavHeader(
                title: l.settingsLock,
                sub: [lock.modeLabel(l, kind)],
                backLabel: l.tabSettings,
              ),
              const SizedBox(height: AppSpace.s20),
              _Group(
                children: [
                  _SwitchRow(
                    icon: HugeIcons.strokeRoundedLock,
                    title: l.lockMain,
                    sub: lock.enabled
                        ? l.lockMainOn(bioOn ? l.lockHowBio(bio) : l.lockHowPin)
                        : l.lockModeOff,
                    value: lock.enabled,
                    onChanged: (_) => _flow(
                      context,
                      lock.enabled ? LockFlow.disable : LockFlow.enable,
                      kind,
                    ),
                  ),
                ],
              ),
              if (!lock.enabled)
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 10, 28, 0),
                  child: Text(
                    l.lockOffNote,
                    style: AppText.caption.copyWith(
                      height: 1.4,
                      color: AppColors.muted,
                    ),
                  ),
                )
              else ...[
                _Section(
                  title: l.lockSectionOpen,
                  child: _Group(
                    margin: EdgeInsets.zero,
                    children: [
                      if (kind != BioKind.none)
                        _SwitchRow(
                          icon: kind == BioKind.face
                              ? AppIcons.faceId
                              : AppIcons.fingerprint,
                          title: l.lockUseBio(bio),
                          sub: l.lockUseBioSub,
                          value: bioOn,
                          onChanged: toggleBio,
                        ),
                      if (kind != BioKind.none && lock.bioChanged)
                        _Note(
                          icon: HugeIcons.strokeRoundedInformationCircle,
                          text: l.lockBioChanged(bio),
                        ),
                      if (kind == BioKind.none)
                        _Note(
                          icon: HugeIcons.strokeRoundedViewOff,
                          text: l.lockNoBio,
                          muted: true,
                        ),
                      _NavRow(
                        title: l.lockChangePin,
                        onTap: () => _flow(context, LockFlow.change, kind),
                      ),
                    ],
                  ),
                ),
                _Section(
                  title: l.lockSectionAfter,
                  child: _Segments(
                    label: l.lockSectionAfter,
                    selected: lock.after.inMinutes,
                    options: [
                      (0, l.lockAfterNow),
                      (1, l.lockAfterMin(1)),
                      (5, l.lockAfterMin(5)),
                      (15, l.lockAfterMin(15)),
                    ],
                    onPick: (m) => controller.setAfter(Duration(minutes: m)),
                  ),
                ),
                const SizedBox(height: AppSpace.s24),
                _Group(
                  children: [
                    _SwitchRow(
                      icon: HugeIcons.strokeRoundedViewOff,
                      title: l.lockBlur,
                      sub: android ? l.lockBlurSubAndroid : l.lockBlurSubIos,
                      value: lock.blur,
                      onChanged: controller.setBlur,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpace.s32),
              _ForgotCard(
                body: l.lockCardBody(bioOn ? l.lockCardOr(bio) : ''),
                onExport: () => exportCsv(ref),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A mist card holding rows, hairlines between them.
class _Group extends StatelessWidget {
  const _Group({
    required this.children,
    this.margin = const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
  });

  final List<Widget> children;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.mist,
        borderRadius: BorderRadius.circular(AppRadius.groupCard),
      ),
      child: Column(
        children: [
          for (final (i, c) in children.indexed) ...[
            if (i > 0)
              const Divider(
                height: AppStroke.hairline,
                thickness: AppStroke.hairline,
                indent: 64,
                color: AppColors.divider,
              ),
            c,
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.s24,
        AppSpace.gutter,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              title,
              style: AppText.caption.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Disc extends StatelessWidget {
  const _Disc({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 36,
    decoration: const BoxDecoration(
      color: AppColors.paper,
      shape: BoxShape.circle,
    ),
    child: Center(child: child),
  );
}

HugeIcon _icon(List<List<dynamic>> icon, {Color color = AppColors.ink}) =>
    HugeIcon(icon: icon, size: 20, strokeWidth: AppStroke.icon, color: color);

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.sub,
    required this.value,
    required this.onChanged,
  });

  final List<List<dynamic>> icon;
  final String title, sub;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.s16),
        child: Row(
          spacing: 12,
          children: [
            _Disc(child: _icon(icon)),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 1,
                children: [
                  Text(title, style: AppText.label),
                  Text(
                    sub,
                    style: AppText.caption.copyWith(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            AppSwitch(value: value, label: title, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: AppSpace.settingsRow,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s16),
            child: Row(
              spacing: 12,
              children: [
                _Disc(
                  child: Text(
                    '•••',
                    style: AppText.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Expanded(child: Text(title, style: AppText.label)),
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  size: 18,
                  strokeWidth: AppStroke.icon,
                  color: AppColors.subtle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// An info line inside a card (face id changed, no biometric on this phone).
class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text, this.muted = false});

  final List<List<dynamic>> icon;
  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s16,
          vertical: 12,
        ),
        child: Row(
          spacing: 12,
          children: [
            _Disc(
              child: _icon(
                icon,
                color: muted ? AppColors.grey400 : AppColors.ink,
              ),
            ),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  text,
                  style: AppText.caption.copyWith(
                    height: 1.4,
                    color: muted ? AppColors.muted : AppColors.ink,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "kunci lagi setelah ditinggal": one of a few minute counts.
class _Segments extends StatelessWidget {
  const _Segments({
    required this.label,
    required this.selected,
    required this.options,
    required this.onPick,
  });

  final String label;
  final int selected;
  final List<(int, String)> options;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: label,
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(width: AppStroke.outline, color: AppColors.ink),
        ),
        child: Row(
          spacing: 2,
          children: [
            for (final (minutes, text) in options)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: minutes == selected,
                  label: text,
                  excludeSemantics: true,
                  onTap: () => onPick(minutes),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onPick(minutes),
                    child: AnimatedContainer(
                      duration: AppMotion.select,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: minutes == selected
                            ? AppColors.ink
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(19),
                      ),
                      child: Text(
                        text,
                        maxLines: 1,
                        style: AppText.label.copyWith(
                          fontSize: 14,
                          fontWeight: minutes == selected
                              ? FontWeight.w500
                              : FontWeight.w400,
                          color: minutes == selected
                              ? AppColors.paper
                              : AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 99.10 "pin nggak bisa direset": why, and the way to keep the notes safe.
class _ForgotCard extends StatelessWidget {
  const _ForgotCard({required this.body, required this.onExport});

  final String body;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.statTile),
        border: Border.all(width: AppStroke.outline, color: AppColors.ink),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Text(
            l.lockForgotTitle,
            style: AppText.label.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            body,
            style: AppText.caption.copyWith(
              height: 1.4,
              color: AppColors.muted,
            ),
          ),
          TextButton(
            onPressed: onExport,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, AppSpace.minTouch),
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
              foregroundColor: AppColors.ink,
              textStyle: AppText.label.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
            child: Text(l.lockCardExport),
          ),
        ],
      ),
    );
  }
}
