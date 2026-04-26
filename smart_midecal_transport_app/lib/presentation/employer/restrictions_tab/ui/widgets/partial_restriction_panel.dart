import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';
import 'package:smart_midecal_transport_app/presentation/employer/restrictions_tab/domain/entities/restrictions_entity.dart';

/// Inline expandable panel for partial restriction of doctors or storage employees.
class PartialRestrictionPanel extends StatelessWidget {
  final String title;
  final Color accentColor;
  final bool isExpanded;
  final bool isLoading;       // action loading (apply button)
  final bool isListLoading;   // fetching the person list
  final List<PersonEntity> people;
  final Set<String> selectedIds;
  final String searchQuery;
  final VoidCallback onToggleExpand;
  final ValueChanged<String> onTogglePerson;
  final VoidCallback onSelectAll;
  final VoidCallback onClearAll;
  final VoidCallback onApply;
  final ValueChanged<String> onSearchChanged;

  const PartialRestrictionPanel({
    super.key,
    required this.title,
    required this.accentColor,
    required this.isExpanded,
    required this.isLoading,
    required this.isListLoading,
    required this.people,
    required this.selectedIds,
    required this.searchQuery,
    required this.onToggleExpand,
    required this.onTogglePerson,
    required this.onSelectAll,
    required this.onClearAll,
    required this.onApply,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // ── Header button ────────────────────────────────────────────
        GestureDetector(
          onTap: onToggleExpand,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isExpanded
                  ? accentColor.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isExpanded
                    ? accentColor.withValues(alpha: 0.4)
                    : theme.dividerColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 18.sp,
                  color: isExpanded ? accentColor : AppColors.labelColor,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.sp,
                      color: isExpanded ? accentColor : null,
                    ),
                  ),
                ),
                if (selectedIds.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      '${selectedIds.length} selected',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                SizedBox(width: 8.w),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20.sp,
                    color: isExpanded ? accentColor : AppColors.labelColor,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Animated expanded body ───────────────────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: isExpanded
              ? _ExpandedBody(
                  accentColor: accentColor,
                  isLoading: isLoading,
                  isListLoading: isListLoading,
                  people: people,
                  selectedIds: selectedIds,
                  searchQuery: searchQuery,
                  onTogglePerson: onTogglePerson,
                  onSelectAll: onSelectAll,
                  onClearAll: onClearAll,
                  onApply: onApply,
                  onSearchChanged: onSearchChanged,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _ExpandedBody extends StatelessWidget {
  final Color accentColor;
  final bool isLoading;
  final bool isListLoading;
  final List<PersonEntity> people;
  final Set<String> selectedIds;
  final String searchQuery;
  final ValueChanged<String> onTogglePerson;
  final VoidCallback onSelectAll;
  final VoidCallback onClearAll;
  final VoidCallback onApply;
  final ValueChanged<String> onSearchChanged;

  const _ExpandedBody({
    required this.accentColor,
    required this.isLoading,
    required this.isListLoading,
    required this.people,
    required this.selectedIds,
    required this.searchQuery,
    required this.onTogglePerson,
    required this.onSelectAll,
    required this.onClearAll,
    required this.onApply,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.only(top: 8.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search field ───────────────────────────────────────────
          TextField(
            onChanged: onSearchChanged,
            style: TextStyle(fontSize: 13.sp),
            decoration: InputDecoration(
              hintText: 'Search...',
              hintStyle: TextStyle(
                fontSize: 13.sp,
                color: AppColors.labelColor,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 18.sp,
                color: AppColors.labelColor,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 10.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.4),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.4),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(color: accentColor),
              ),
              filled: true,
              fillColor: theme.cardColor,
            ),
          ),
          SizedBox(height: 10.h),

          // ── Select all / clear all ─────────────────────────────────
          Row(
            children: [
              _SmallChip(
                label: 'Select All',
                color: accentColor,
                onTap: onSelectAll,
              ),
              SizedBox(width: 8.w),
              _SmallChip(
                label: 'Clear All',
                color: AppColors.labelColor,
                onTap: onClearAll,
              ),
              const Spacer(),
              if (selectedIds.isNotEmpty)
                Text(
                  '${selectedIds.length} selected',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          SizedBox(height: 10.h),

          // ── People list ────────────────────────────────────────────
          if (isListLoading)
            _ListSkeleton()
          else if (people.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Text(
                  'No people found',
                  style: TextStyle(
                    color: AppColors.labelColor,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            )
          else
            ...people.map(
              (person) => _PersonTile(
                person: person,
                isSelected: selectedIds.contains(person.id),
                accentColor: accentColor,
                onToggle: () => onTogglePerson(person.id ?? ''),
              ),
            ),

          SizedBox(height: 14.h),

          // ── Apply button ───────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 44.h,
            child: ElevatedButton.icon(
              onPressed: isLoading || selectedIds.isEmpty ? null : onApply,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: accentColor.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
              ),
              icon: isLoading
                  ? SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(Icons.check_rounded, size: 18.sp),
              label: Text(
                isLoading
                    ? 'Applying...'
                    : 'Apply Partial Restriction (${selectedIds.length})',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Person tile ─────────────────────────────────────────────────────────

class _PersonTile extends StatelessWidget {
  final PersonEntity person;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onToggle;

  const _PersonTile({
    required this.person,
    required this.isSelected,
    required this.accentColor,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isSelected
            ? accentColor.withValues(alpha: 0.08)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isSelected
              ? accentColor.withValues(alpha: 0.4)
              : theme.dividerColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18.r,
            backgroundColor: accentColor.withValues(alpha: 0.15),
            child: Text(
              (person.name?.isNotEmpty == true)
                  ? person.name![0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.w700,
                fontSize: 13.sp,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.name ?? 'Unknown',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                  ),
                ),
                if (person.email != null && person.email!.isNotEmpty)
                  Text(
                    person.email!,
                    style: TextStyle(
                      color: AppColors.labelColor,
                      fontSize: 11.sp,
                    ),
                  ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isSelected,
            onChanged: (_) => onToggle(),
            activeColor: accentColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

// ─── Small chip ──────────────────────────────────────────────────────────

class _SmallChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SmallChip({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─── Skeleton loader for list ─────────────────────────────────────────────

class _ListSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (i) => _SkeletonTile(key: ValueKey(i)),
      ),
    );
  }
}

class _SkeletonTile extends StatefulWidget {
  const _SkeletonTile({super.key});

  @override
  State<_SkeletonTile> createState() => _SkeletonTileState();
}

class _SkeletonTileState extends State<_SkeletonTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        margin: EdgeInsets.only(bottom: 8.h),
        height: 56.h,
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.grey)
              .withValues(alpha: _anim.value),
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
    );
  }
}
