import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A single unified card that contains:
/// • Global toggle row (title + subtitle + Switch)
/// • Animated expand/collapse section with the list content
class RestrictionsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isGlobalOn;
  final bool isExpanded;
  final bool isLoading;
  final ValueChanged<bool> onGlobalToggle;
  final VoidCallback onExpandToggle;
  final Color? activeColor;

  /// Content shown inside the expanded section (list of tiles).
  final Widget expandedContent;

  /// When false, the expand chevron is hidden (e.g. Car section has no list).
  final bool showExpand;

  const RestrictionsCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isGlobalOn,
    required this.isExpanded,
    required this.isLoading,
    required this.onGlobalToggle,
    required this.onExpandToggle,
    required this.expandedContent,
    this.activeColor,
    this.showExpand = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final effectiveColor = activeColor ?? cs.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded
              ? effectiveColor.withValues(alpha: 0.30)
              : cs.outlineVariant.withValues(alpha: 0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // ── Header Row ────────────────────────────────────────────
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: showExpand ? onExpandToggle : null,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 18.w,
                    vertical: 16.h,
                  ),
                  child: Row(
                    children: [
                      // Icon badge
                      _IconBadge(icon: _iconFor(title), color: effectiveColor),
                      SizedBox(width: 14.w),

                      // Title + subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                                letterSpacing: -0.2,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: cs.onSurface.withValues(alpha: 0.5),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: 6.w),

                      // Switch / loading
                      if (isLoading)
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: effectiveColor,
                          ),
                        )
                      else
                        Switch(
                          value: isGlobalOn,
                          onChanged: onGlobalToggle,
                          activeColor: effectiveColor,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),

                      // Chevron (only if expandable)
                      if (showExpand) ...[
                        SizedBox(width: 4.w),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 22.sp,
                            color: isExpanded
                                ? effectiveColor
                                : cs.onSurface.withValues(alpha: 0.38),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // ── Animated Expanded Content ─────────────────────────────
            if (showExpand)
              AnimatedSize(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeInOut,
                child: isExpanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: cs.outlineVariant.withValues(alpha: 0.45),
                          ),
                          expandedContent,
                        ],
                      )
                    : const SizedBox(width: double.infinity, height: 0),
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String t) {
    final lower = t.toLowerCase();
    if (lower.contains('doctor')) return Icons.medical_services_outlined;
    if (lower.contains('storage')) return Icons.inventory_2_outlined;
    if (lower.contains('car') || lower.contains('transport')) {
      return Icons.local_shipping_outlined;
    }
    return Icons.shield_outlined;
  }
}

// ─── Small helper ─────────────────────────────────────────────────────────────

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: 20.sp),
    );
  }
}
