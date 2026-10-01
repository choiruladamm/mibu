import 'package:flutter/widgets.dart';

/// Tapping outside a text field closes the keyboard. Flutter only does this
/// on desktop / web; on Android / iOS a touch outside keeps the focus.
/// Wrap the app once — it overrides EditableText's tap-outside action.
class TapOutsideUnfocus extends StatelessWidget {
  const TapOutsideUnfocus({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Actions(
    actions: {
      EditableTextTapOutsideIntent:
          CallbackAction<EditableTextTapOutsideIntent>(
            onInvoke: (intent) {
              intent.focusNode.unfocus();
              return null;
            },
          ),
    },
    child: child,
  );
}
