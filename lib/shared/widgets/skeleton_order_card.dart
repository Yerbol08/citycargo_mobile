import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../app/theme.dart';

class SkeletonOrderCard extends StatelessWidget {
  const SkeletonOrderCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;
    final shimmerContentColor = isDark ? Colors.white24 : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                    width: 80, height: 16, color: shimmerContentColor),
                Container(
                    width: 60, height: 20, color: shimmerContentColor),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                    width: 20, height: 20, color: shimmerContentColor),
                const SizedBox(width: 12),
                Container(
                    width: 150, height: 14, color: shimmerContentColor),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                    width: 20, height: 20, color: shimmerContentColor),
                const SizedBox(width: 12),
                Container(
                    width: 120, height: 14, color: shimmerContentColor),
              ],
            ),
            const SizedBox(height: 16),
            Container(
                width: double.infinity,
                height: 1,
                color: shimmerContentColor),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                    width: 100, height: 14, color: shimmerContentColor),
                Container(
                    width: 70, height: 18, color: shimmerContentColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
