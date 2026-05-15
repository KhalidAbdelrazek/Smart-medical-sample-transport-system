import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';

/// Card containing the selectable room chips.
class RoomSelectorCard extends StatelessWidget {
  final String? selectedRoom;
  final void Function(String) onRoomSelected;
  final ThemeData theme;

  const RoomSelectorCard({
    super.key,
    required this.selectedRoom,
    required this.onRoomSelected,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    // Ideally this list comes from the View Model or an API, 
    // but we extract it cleanly for now.
    final rooms = ['1', '2', '3'];

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.meeting_room_outlined,
                  size: 20.sp,
                  color: AppColors.buttonColor,
                ),
                SizedBox(width: 8.w),
                Text('extra.select_delivery_room'.tr(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            Row(
              children: rooms.map((room) {
                final isSelected = selectedRoom == room;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(
                      end: room != rooms.last ? 10.w : 0,
                    ),
                    child: InkWell(
                      onTap: () => onRoomSelected(room),
                      borderRadius: BorderRadius.circular(12.r),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.buttonColor
                              : theme.scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.buttonColor
                                : theme.dividerColor.withValues(alpha: 0.15),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          room,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isSelected
                                ? Colors.white
                                : theme.textTheme.bodyLarge?.color,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

