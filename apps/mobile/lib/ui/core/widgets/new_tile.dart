import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../dashed.dart';
import '../tokens.dart';

/// Dashed "+" disc closing a category grid (03.2, 03.3): "baru" / "bikin “x”".
class NewCategoryTile extends StatelessWidget {
  const NewCategoryTile({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          spacing: 6,
          children: [
            CustomPaint(
              painter: _DashedCircle(),
              child: const SizedBox(
                width: 60,
                height: 60,
                child: Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedAdd01,
                    size: 22,
                    strokeWidth: AppStroke.icon,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.caption,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedCircle extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    canvas.drawPath(
      dashPath(Path()..addOval(r.deflate(AppStroke.outline / 2))),
      Paint()
        ..color = AppColors.ink
        ..strokeWidth = AppStroke.outline
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_DashedCircle old) => false;
}
