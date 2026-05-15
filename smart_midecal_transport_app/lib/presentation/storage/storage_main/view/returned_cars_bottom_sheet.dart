import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/presentation/storage/storage_main/domain/entity/returned_cars_response_entity.dart';
import 'package:smart_midecal_transport_app/presentation/storage/storage_main/logic/cubit/storage_main_cubit.dart';
import 'package:smart_midecal_transport_app/presentation/storage/storage_main/logic/cubit/storage_state.dart';
import 'package:smart_midecal_transport_app/presentation/storage/storage_main/view/widgets/returned_cars_skeleton.dart';

void showReturnedCarsBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      // Provide the same cubit instance to the bottom sheet
      return BlocProvider.value(
        value: context.read<StorageMainCubit>(),
        child: const _ReturnedCarsBottomSheetContent(),
      );
    },
  );
}

class _ReturnedCarsBottomSheetContent extends StatelessWidget {
  const _ReturnedCarsBottomSheetContent();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            children: [
              // Drag Handle
              Center(
                child: Container(
                  margin: EdgeInsetsDirectional.only(top: 12.h, bottom: 8.h),
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'storage.returned_cars_tab'.tr(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Content
              Expanded(
                child: BlocConsumer<StorageMainCubit, StorageState>(
                  listenWhen: (previous, current) =>
                      current is ConfirmSuccess || current is ConfirmError,
                  listener: (context, state) {
                    final messenger = ScaffoldMessenger.of(context);
                    if (state is ConfirmSuccess) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            state.message ?? 'storage.return_confirm_success'.tr(),
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else if (state is ConfirmError) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  builder: (context, state) {
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: _buildBody(context, state, scrollController),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, StorageState state, ScrollController scrollController) {
    if (state is StorageInitial || state is StorageLoading) {
      // Re-use the skeleton but make it scrollable if needed
      return ListView(
        controller: scrollController,
        padding: EdgeInsets.zero,
        children: const [
           ReturnedCarsSkeleton(key: ValueKey('skeleton')),
        ],
      );
    }
    if (state is StorageError) {
      return ListView(
        controller: scrollController,
        padding: EdgeInsets.zero,
        children: [
          SizedBox(height: 40.h),
          _ErrorPane(
            key: const ValueKey('error'),
            message: state.message,
            onRetry: () => context.read<StorageMainCubit>().refresh(),
          ),
        ],
      );
    }
    if (state is StorageSuccess) {
      return _CarsListPane(
        key: ValueKey('ok-${state.cars.length}'),
        cars: state.cars,
        lastUpdated: state.lastUpdated,
        scrollController: scrollController,
      );
    }
    if (state is ConfirmLoading) {
      return _CarsListPane(
        key: ValueKey('confirm-${state.carId}'),
        cars: state.cars,
        lastUpdated: state.lastUpdated,
        loadingCarId: state.carId,
        scrollController: scrollController,
      );
    }
    if (state is ConfirmSuccess) {
      return _CarsListPane(
        key: const ValueKey('confirm-success'),
        cars: state.cars,
        lastUpdated: state.lastUpdated,
        scrollController: scrollController,
      );
    }
    if (state is ConfirmError) {
      return _CarsListPane(
        key: const ValueKey('confirm-err'),
        cars: state.cars,
        lastUpdated: state.lastUpdated,
        scrollController: scrollController,
      );
    }
    return SizedBox.shrink(key: const ValueKey('unknown'));
  }
}

class _ErrorPane extends StatelessWidget {
  const _ErrorPane({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 52.sp,
              color: scheme.error,
            ),
            SizedBox(height: 16.h),
            Text(
              'storage.returned_cars_error_title'.tr(),
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('home.retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarsListPane extends StatelessWidget {
  const _CarsListPane({
    super.key,
    required this.cars,
    required this.lastUpdated,
    required this.scrollController,
    this.loadingCarId,
  });

  final List<ReturnedCarEntity> cars;
  final DateTime lastUpdated;
  final ScrollController scrollController;
  final int? loadingCarId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.read<StorageMainCubit>();

    if (cars.isEmpty) {
      return RefreshIndicator(
        color: scheme.primary,
        onRefresh: cubit.refresh,
        child: ListView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: 60.h),
            Icon(
              Icons.inbox_outlined,
              size: 56.sp,
              color: scheme.onSurfaceVariant,
            ),
            SizedBox(height: 16.h),
            Center(
              child: Text(
                'storage.returned_cars_empty'.tr(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 8.h),
          child: _LastUpdatedRow(lastUpdated: lastUpdated),
        ),
        Expanded(
          child: RefreshIndicator(
            color: scheme.primary,
            onRefresh: cubit.refresh,
            child: ListView.separated(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
              itemCount: cars.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                final car = cars[index];
                final actionId = _carActionId(car);
                return _ReturnedCarCard(
                  car: car,
                  isConfirming: loadingCarId != null && actionId == loadingCarId,
                  onConfirm: loadingCarId != null || actionId == null
                      ? null
                      : () => cubit.confirmReturnedCar(actionId),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

int? _carActionId(ReturnedCarEntity car) => car.carId ?? car.id;

class _LastUpdatedRow extends StatefulWidget {
  const _LastUpdatedRow({required this.lastUpdated});

  final DateTime lastUpdated;

  @override
  State<_LastUpdatedRow> createState() => _LastUpdatedRowState();
}

class _LastUpdatedRowState extends State<_LastUpdatedRow> {
  late DateTime _tick;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _tick = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _tick = DateTime.now());
    });
  }

  @override
  void didUpdateWidget(covariant _LastUpdatedRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lastUpdated != widget.lastUpdated) {
      _tick = DateTime.now();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final seconds = _tick.difference(widget.lastUpdated).inSeconds.clamp(0, 86400);
    return Row(
      children: [
        Icon(
          Icons.autorenew_rounded,
          size: 16.sp,
          color: scheme.primary.withValues(alpha: 0.9),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            'storage.last_updated_seconds'.tr(args: ['$seconds']),
            style: textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReturnedCarCard extends StatelessWidget {
  const _ReturnedCarCard({
    required this.car,
    required this.onConfirm,
    required this.isConfirming,
  });

  final ReturnedCarEntity car;
  final VoidCallback? onConfirm;
  final bool isConfirming;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final title = car.carNumber != null && car.carNumber!.isNotEmpty
        ? '${'storage.car_label'.tr()} ${car.carNumber}'
        : '${'storage.car_id_label'.tr()} ${car.id ?? car.carId ?? '—'}';
    final ts = car.arrivedAtStorage ?? car.createdAt;
    final timeStr = ts != null
        ? DateFormat.yMMMd().add_Hm().format(DateTime.parse(ts))
        : '—';

    return Material(
      color: scheme.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.local_shipping_rounded,
                    color: scheme.onPrimaryContainer,
                    size: 22.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      if (car.status != null && car.status!.isNotEmpty)
                        _StatusChip(status: car.status!),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 16.sp,
                  color: scheme.onSurfaceVariant,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    '${'storage.arrived_label'.tr()}: $timeStr',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            if (car.capacity != null) ...[
              SizedBox(height: 6.h),
              Text(
                '${'storage.capacity_label'.tr()}: ${car.capacity}',
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            SizedBox(height: 14.h),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                onPressed: (_carActionId(car) == null || isConfirming)
                    ? null
                    : onConfirm,
                child: isConfirming
                    ? SizedBox(
                        height: 20.h,
                        width: 20.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: scheme.onPrimary,
                        ),
                      )
                    : Text('storage.confirm_return'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        status,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
