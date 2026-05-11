import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/presentation/employee/root/ui/cubit/notification_cubit.dart';
import 'package:smart_midecal_transport_app/presentation/employee/root/ui/cubit/notification_state.dart';
import 'package:smart_midecal_transport_app/presentation/employee/root/ui/models/notification_list_item.dart';

class NotificationCard extends StatefulWidget {
  const NotificationCard({
    super.key,
    required this.item,
    required this.animateEntry,
  });

  final NotificationListItem item;
  final bool animateEntry;

  @override
  State<NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<NotificationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    if (widget.animateEntry) {
      _controller.forward().whenComplete(() {
        if (mounted) {
          context.read<NotificationCubit>().acknowledgeEntryAnimation(
                widget.item.requestId,
              );
        }
      });
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _relativeTime(DateTime at) {
    final diff = DateTime.now().difference(at);
    if (diff.inSeconds < 60) {
      return 'employee.notifications_just_now'.tr();
    }
    if (diff.inMinutes < 60) {
      return 'employee.notifications_minutes_ago'
          .tr(args: ['${diff.inMinutes}']);
    }
    if (diff.inHours < 24) {
      return 'employee.notifications_hours_ago'.tr(args: ['${diff.inHours}']);
    }
    return 'employee.notifications_days_ago'.tr(args: ['${diff.inDays}']);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final item = widget.item;

    return FadeTransition(
      opacity:
          CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic)),
        child: Material(
          color: scheme.surfaceContainerHighest,
          elevation: 0,
          shadowColor: scheme.shadow.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16.r),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.titleTrKey.tr(),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            if (item.description.isNotEmpty)
                              Text(
                                item.description,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  height: 1.35,
                                ),
                              ),
                            if (item.roomLabel.isNotEmpty) ...[
                              SizedBox(height: 6.h),
                              Text(
                                'employee.notifications_room'.tr(
                                  args: [item.roomLabel],
                                ),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        _relativeTime(item.firstSeenAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  BlocSelector<NotificationCubit, NotificationState, bool>(
                    selector: (s) =>
                        s.actionInFlightIds.contains(item.requestId),
                    builder: (context, loading) {
                      if (loading) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          child: Center(
                            child: SizedBox(
                              width: 24.w,
                              height: 24.h,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: scheme.primary,
                              ),
                            ),
                          ),
                        );
                      }
                      return Row(
                        children: [
                          Expanded(
                            child: FilledButton.tonal(
                              // ✅ Now goes through onAcceptTapped so the
                              //    return-handoff dialog is shown when needed.
                              onPressed: () => context
                                  .read<NotificationCubit>()
                                  .onAcceptTapped(context, item.requestId),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_rounded, size: 18.sp),
                                  SizedBox(width: 6.w),
                                  Text('employee.notifications_accept'.tr()),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => context
                              .read<NotificationCubit>()
                               .onRejectTapped(context, item.requestId),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.close_rounded, size: 18.sp),
                                  SizedBox(width: 6.w),
                                  Text('employee.notifications_reject'.tr()),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}