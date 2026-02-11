import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';
import 'package:smart_midecal_transport_app/core/theme/theme_provider.dart';
import 'package:smart_midecal_transport_app/core/localization/locale_provider.dart';

/// Employee settings section with language/theme toggles and logout
/// Matches the EmployerSettingsSection pattern
class EmployeeSettingsSection extends StatelessWidget {
  const EmployeeSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'employee.settings'.tr(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16.h),

          // Language toggle
          _SettingsTile(
            icon: Icons.language_rounded,
            title: 'employee.language'.tr(),
            trailing: Switch(
              value: context.locale.languageCode == 'ar',
              activeColor: AppColors.primaryLight,
              onChanged: (value) {
                localeProvider.toggleLocale(context);
              },
            ),
            subtitle: context.locale.languageCode == 'ar'
                ? 'العربية'
                : 'English',
          ),

          Divider(color: theme.dividerColor.withValues(alpha: 0.2), height: 1),

          // Theme toggle
          _SettingsTile(
            icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            title: 'employee.theme'.tr(),
            trailing: Switch(
              value: isDark,
              activeColor: AppColors.primaryLight,
              onChanged: (value) {
                themeProvider.toggleTheme();
              },
            ),
            subtitle: isDark ? 'Dark' : 'Light',
          ),

          Divider(color: theme.dividerColor.withValues(alpha: 0.2), height: 1),

          // Logout
          _SettingsTile(
            icon: Icons.logout_rounded,
            title: 'employee.logout'.tr(),
            iconColor: AppColors.error,
            titleColor: AppColors.error,
            onTap: () {
              // TODO: Implement logout logic
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final String? subtitle;
  final Color? iconColor;
  final Color? titleColor;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.subtitle,
    this.iconColor,
    this.titleColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? AppColors.primaryLight;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: effectiveIconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: effectiveIconColor, size: 20.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: titleColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      subtitle!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.labelColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
