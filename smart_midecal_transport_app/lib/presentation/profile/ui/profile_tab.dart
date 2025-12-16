import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_midecal_transport_app/core/routes/route_names.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';
import 'package:smart_midecal_transport_app/presentation/profile/ui/widgets/profile_item.dart';
import 'package:smart_midecal_transport_app/presentation/profile/ui/widgets/section_card.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Employee Profile
          SectionCard(
            title: 'profile.employee_profile'.tr(),
            child: Column(
              children: const [
                ProfileItem(
                  icon: Icons.person_outline,
                  labelKey: 'profile.name',
                  value: 'Sarah Martinez',
                ),
                ProfileItem(
                  icon: Icons.badge_outlined,
                  labelKey: 'profile.employee_id',
                  value: 'EMP-2024-014',
                ),
                ProfileItem(
                  icon: Icons.apartment_outlined,
                  labelKey: 'profile.department',
                  value: 'Blood Bank',
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          /// Role & Permissions
          SectionCard(
            title: 'profile.role_permissions'.tr(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'profile.current_role'.tr(),
                      style: theme.textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        'profile.employee'.tr(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.actionColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Text(
                  'profile.permissions_description'.tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.labelColor,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          /// Appearance
          SectionCard(
            title: 'profile.appearance'.tr(),
            child: Row(
              children: [
                Icon(
                  Icons.dark_mode_outlined,
                  size: 22.sp,
                  color: theme.iconTheme.color,
                ),
                SizedBox(width: 12.w),
                Text('profile.theme'.tr(), style: theme.textTheme.bodyMedium),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.inActiveColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    theme.brightness == Brightness.dark
                        ? 'profile.dark_mode'.tr()
                        : 'profile.light_mode'.tr(),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 32.h),

          /// Logout
          GestureDetector(
            onTap: () {
              Navigator.pushReplacementNamed(context, RouteNames.register);
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColors.actionColor),
              ),
              child: Center(
                child: Text(
                  'profile.logout'.tr(),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.actionColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
