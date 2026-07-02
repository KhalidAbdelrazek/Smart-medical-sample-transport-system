import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UserRestrictionTile extends StatelessWidget {
  final String name;
  final bool isRestricted;
  final ValueChanged<bool> onToggle;
  final bool isLoading;

  const UserRestrictionTile({
    super.key,
    required this.name,
    required this.isRestricted,
    required this.onToggle,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: isLoading ? null : () => onToggle(!isRestricted),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
        child: Row(
          children: [
            // Avatar Placeholder
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            // Name
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Switch
            if (isLoading)
              SizedBox(
                width: 20.w,
                height: 20.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.primary,
                ),
              )
            else
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: isRestricted,
                  onChanged: onToggle,
                  activeColor: cs.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
