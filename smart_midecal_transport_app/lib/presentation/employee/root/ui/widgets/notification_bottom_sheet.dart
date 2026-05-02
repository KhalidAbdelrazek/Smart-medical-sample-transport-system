import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/presentation/employee/root/ui/cubit/notification_cubit.dart';
import 'package:smart_midecal_transport_app/presentation/employee/root/ui/cubit/notification_state.dart';
import 'package:smart_midecal_transport_app/presentation/employee/root/ui/widgets/notification_card.dart';

class NotificationBottomSheet {
  static Future<void> show(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (sheetContext) {
        return BlocProvider.value(
          // 🔥🔥 THIS IS THE FIX
          value: context.read<NotificationCubit>(),
          child: DraggableScrollableSheet(
            initialChildSize: 0.56,
            minChildSize: 0.34,
            maxChildSize: 0.88,
            expand: false,
            builder: (context, scrollController) {
              return Material(
                color: scheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 4.h, 16.w, 8.h),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'employee.notifications_title'.tr(),
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1),

                    /// 🔥 NOW BlocBuilder WILL WORK
                    Expanded(
                      child: BlocBuilder<NotificationCubit, NotificationState>(
                        builder: (context, state) {
                          if (state.isInitialLoading && state.items.isEmpty) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (state.items.isEmpty) {
                            return const Center(
                              child: Text("No Notifications"),
                            );
                          }

                          return ListView.builder(
                            controller: scrollController,
                            itemCount: state.items.length,
                            itemBuilder: (context, index) {
                              final item = state.items[index];

                              return NotificationCard(
                                item: item,
                                animateEntry: false,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 72.sp,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
            ),
            SizedBox(height: 16.h),
            Text(
              'employee.notifications_empty_title'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'employee.notifications_empty_subtitle'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
