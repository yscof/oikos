import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// 웹에서 화면이 넓으면 앱을 폰 폭으로 가운데 정렬해 보여준다.
/// 네이티브 앱과 좁은 화면(모바일 브라우저)에서는 그대로 전체 폭.
class MobileFrame extends StatelessWidget {
  const MobileFrame({super.key, this.child});

  /// 큰 폰 기준 폭(iPhone Pro Max ≈ 430pt).
  static const double phoneWidth = 430;

  /// 이 폭을 넘으면 폰 프레임을 씌운다.
  static const double frameThreshold = 600;

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final content = child ?? const SizedBox.shrink();
    if (!kIsWeb) return content;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= frameThreshold) return content;
        final scheme = Theme.of(context).colorScheme;
        return ColoredBox(
          color: scheme.surfaceContainerLow,
          child: Center(
            child: Container(
              width: phoneWidth,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border.symmetric(
                  vertical: BorderSide(color: scheme.outlineVariant),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: content,
            ),
          ),
        );
      },
    );
  }
}
