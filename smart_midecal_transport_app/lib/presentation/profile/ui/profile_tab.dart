import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_midecal_transport_app/core/routes/route_names.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';
import 'package:smart_midecal_transport_app/presentation/profile/ui/widgets/profile_item.dart';
import 'package:smart_midecal_transport_app/presentation/profile/ui/widgets/section_card.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 100.h), // Added bottom padding for floating navbar
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
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
                      isLast: true,
                    ),
                  ],
                ),
              ),
        
              SizedBox(height: 20.h),
        
              /// Role & Permissions
              SectionCard(
                title: 'profile.role_permissions'.tr(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48.w,
                          height: 48.w,
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          child: Icon(Icons.admin_panel_settings_outlined, size: 22.sp, color: theme.primaryColor),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'profile.current_role'.tr(),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: AppColors.labelColor,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  Text(
                                    'profile.employee'.tr(),
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Text(
                                      'Active',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10.sp
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, size: 16.sp, color: AppColors.labelColor),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'profile.permissions_description'.tr(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.labelColor,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        
              SizedBox(height: 20.h),
        
              /// Appearance
              SectionCard(
                title: 'profile.appearance'.tr(),
                child: Row(
                  children: [
                    Container(
                      width: 48.w,
                      height: 48.w,
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Icon(Icons.palette_outlined, size: 22.sp, color: theme.primaryColor),
                    ),
                    SizedBox(width: 16.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('profile.theme'.tr(), style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                         Text('Switch between light & dark', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.labelColor)),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: theme.dividerColor.withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        theme.brightness == Brightness.dark
                            ? 'profile.dark_mode'.tr()
                            : 'profile.light_mode'.tr(),
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
        
              SizedBox(height: 32.h),
        
              /// Logout
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, RouteNames.register);
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    side: BorderSide(color: AppColors.error.withOpacity(0.5)),
                  ),
                  backgroundColor: AppColors.error.withOpacity(0.05),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: AppColors.error, size: 20.sp),
                    SizedBox(width: 8.w),
                    Text(
                      'profile.logout'.tr(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
