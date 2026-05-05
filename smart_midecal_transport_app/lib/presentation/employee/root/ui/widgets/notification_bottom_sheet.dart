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

