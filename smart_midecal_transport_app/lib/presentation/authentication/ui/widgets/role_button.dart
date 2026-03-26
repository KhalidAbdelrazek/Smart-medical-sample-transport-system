import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';

class RoleButton extends StatelessWidget {
  final bool active;
  final String label;
  final String iconPath;
  final VoidCallback onTap;
const RoleButton({super.key, 
          required this.active,
          required this.label,
          required this.iconPath,
          required this.onTap,
        });
  @override
  Widget build(BuildContext context) {
    return           
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                decoration: BoxDecoration(
                  color: active ? AppColors.buttonColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.primaryLight,
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(iconPath, height: 20.h),
                    SizedBox(width: 8.w),
                    Text(label),
                  ],
                ),
              ),
            ),
          );
        

  }
}