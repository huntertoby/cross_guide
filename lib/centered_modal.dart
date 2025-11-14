// utils/centered_modal.dart
import 'package:flutter/material.dart';

Future<T?> showCenteredModal<T>(
    BuildContext context, {
      required Widget child,
      double maxWidth = 560,
      double maxHeightFactor = 0.8, // 最高佔螢幕 80%
      bool dismissible = true,
    }) {
  final theme = Theme.of(context);
  return showDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    builder: (ctx) {
      return Dialog(
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: theme.colorScheme.surfaceTint,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            // 高度用螢幕比例限制，內層用 ListView 可捲動
            maxHeight: MediaQuery.of(ctx).size.height * maxHeightFactor,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 假把手（視覺一致）
                const SizedBox(height: 10),
                Container(
                  width: 44, height: 5,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 10),
                // 內容可捲動
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
