import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';
import 'package:smart_midecal_transport_app/presentation/employer/statistics_tab/ui/cubit/statistics_cubit.dart';

/// Animated horizontal filter bar for week / month / year / all_time
class StatsFilterBar extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const StatsFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.primaryColor;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filterLabels.entries.map((entry) {
          final isSelected = entry.key == selectedFilter;
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: _FilterChip(
              label: entry.value,
              isSelected: isSelected,
              primary: primary,
              isDark: isDark,
              onTap: () => onFilterChanged(entry.key),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FilterChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.primary,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _controller.reverse();
  void _onTapUp(_) {
    _controller.forward();
    widget.onTap();
  }

  void _onTapCancel() => _controller.forward();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.primary
                : widget.isDark
                    ? AppColors.cardDarkColor
                    : AppColors.cardLightColor,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: widget.isSelected
                  ? widget.primary
                  : widget.isDark
                      ? AppColors.cardDarkStrokeColor
                      : AppColors.cardLightStrokeColor,
              width: 1.5,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: widget.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight:
                  widget.isSelected ? FontWeight.w600 : FontWeight.w500,
              color: widget.isSelected
                  ? Colors.white
                  : widget.isDark
                      ? AppColors.textDarkColor
                      : AppColors.labelColor,
            ),
          ),
        ),
      ),
    );
  }
}
