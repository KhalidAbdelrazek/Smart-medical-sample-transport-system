'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_midecal_transport_app/core/api%20manager/api_manager.dart';
import 'package:smart_midecal_transport_app/core/di/di.dart';
import 'package:smart_midecal_transport_app/presentation/storage/storage_main/data/data%20source/notification_ds_impl.dart';
import 'package:smart_midecal_transport_app/presentation/storage/storage_main/data/repository/notification_repository_impl.dart';
import 'package:smart_midecal_transport_app/presentation/storage/storage_main/logic/cubit/storage_main_cubit.dart';
import 'package:smart_midecal_transport_app/presentation/storage/storage_main/ui/storage_main_screen.dart';

/// Provides [StorageMainCubit] wired to the storage notification repository.
class ReturnedCarsShell extends StatelessWidget {
  const ReturnedCarsShell({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StorageMainCubit(
        NotificationRepositoryImpl(
          notificationDs: NotificationDsImpl(apiManager: getIt<ApiManager>()),
        ),
      )..startPolling(),
      child: const StorageMainScreen(),
    );
  }
}
