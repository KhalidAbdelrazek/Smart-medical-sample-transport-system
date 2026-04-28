import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';
import 'package:smart_midecal_transport_app/core/provider/theme_provider.dart';
import 'package:smart_midecal_transport_app/core/provider/locale_provider.dart';
import '../cubit/profile_cubit.dart';

/// Settings section widget with functional language and theme switches
class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final isDark = theme.brightness == Brightness.dark;
    final isArabic = context.locale.languageCode == 'ar';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
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
            'profile.settings'.tr(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16.h),

          // Language Switch
          _SettingsTile(
            icon: Icons.language_rounded,
            iconColor: AppColors.info,
            label: 'profile.language'.tr(),
            trailing: _LanguageSwitch(
              isArabic: isArabic,
              onChanged: () => localeProvider.toggleLocale(context),
            ),
          ),
          SizedBox(height: 12.h),

          // Theme Switch
          _SettingsTile(
            icon: Icons.dark_mode_rounded,
            iconColor: isDark ? AppColors.warning : AppColors.primaryLight,
            label: 'profile.theme'.tr(),
            trailing: _ThemeSwitch(
              isDark: isDark,
              onChanged: () => themeProvider.toggleTheme(),
            ),
          ),
          SizedBox(height: 12.h),

          // Logout
          InkWell(
            onTap: () {
              context.read<ProfileCubit>().logout();
            },
            borderRadius: BorderRadius.circular(12.r),
            child: _SettingsTile(
              icon: Icons.logout_rounded,
              iconColor: AppColors.error,
              label: 'profile.logout'.tr(),
              trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16.sp, color: AppColors.labelColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Widget trailing;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, color: iconColor, size: 20.sp),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        trailing,
      ],
    );
  }
}

/// Language toggle switch
class _LanguageSwitch extends StatelessWidget {
  final bool isArabic;
  final VoidCallback onChanged;

  const _LanguageSwitch({required this.isArabic, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: AppColors.info.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _langChip('EN', !isArabic),
            SizedBox(width: 4.w),
            _langChip('عربي', isArabic),
          ],
        ),
      ),
    );
  }

  Widget _langChip(String label, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.info : Colors.transparent,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.info,
          fontWeight: FontWeight.w600,
          fontSize: 12.sp,
        ),
      ),
    );
  }
}

/// Theme toggle switch
class _ThemeSwitch extends StatelessWidget {
  final bool isDark;
  final VoidCallback onChanged;

  const _ThemeSwitch({required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.warning.withValues(alpha: 0.15)
              : AppColors.primaryLight.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: isDark
                ? AppColors.warning.withValues(alpha: 0.3)
                : AppColors.primaryLight.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _themeChip(Icons.light_mode_rounded, !isDark, AppColors.warning),
            SizedBox(width: 4.w),
            _themeChip(Icons.dark_mode_rounded, isDark, AppColors.primaryDark),
          ],
        ),
      ),
    );
  }

  Widget _themeChip(IconData icon, bool isSelected, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: isSelected ? color : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 18.sp,
        color: isSelected
            ? (color == AppColors.warning
                  ? Colors.white
                  : AppColors.appDarkBgColor)
            : AppColors.labelColor,
      ),
    );
  }
}
