import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../l10n/app_localizations.dart';
import '../tokens.dart';

enum AppTab { home, pockets, stats, settings }

/// 00.3 TabBar — floats in a Stack over content; give lists
/// [AppSpace.tabBarClearance] bottom padding.
class AppTabBar extends StatelessWidget {
  const AppTabBar({
    super.key,
    required this.active,
    required this.onSelect,
    required this.onAdd,
  });

  final AppTab active;
  final ValueChanged<AppTab> onSelect;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tabs = [
      (AppTab.home, HugeIcons.strokeRoundedInvoice01, l.tabHome),
      (AppTab.pockets, HugeIcons.strokeRoundedShoppingBag02, l.tabPockets),
      (AppTab.stats, HugeIcons.strokeRoundedAnalytics01, l.tabStats),
      (AppTab.settings, HugeIcons.strokeRoundedSettings01, l.tabSettings),
    ];
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 18),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: AppColors.divider,
                width: AppStroke.hairline,
              ),
              boxShadow: AppShadows.float,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                for (final (tab, icon, label) in tabs)
                  _Dot(
                    icon: icon,
                    label: label,
                    on: tab == active,
                    onTap: () => onSelect(tab),
                  ),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: l.addEntry,
            child: GestureDetector(
              onTap: onAdd,
              child: Container(
                alignment: Alignment.center,
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.ink,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.lift,
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedPlusSign,
                  size: 24,
                  strokeWidth: AppStroke.iconOnInkSmall,
                  color: AppColors.paper,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.icon,
    required this.label,
    required this.on,
    required this.onTap,
  });

  final List<List<dynamic>> icon;
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: on,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          alignment: Alignment.center,
          duration: AppMotion.select,
          curve: AppMotion.ease,
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: on ? AppColors.mist : AppColors.paper,
            shape: BoxShape.circle,
          ),
          child: HugeIcon(
            icon: icon,
            size: 22,
            strokeWidth: AppStroke.icon,
            color: on ? AppColors.ink : AppColors.subtle,
          ),
        ),
      ),
    );
  }
}
