import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_midecal_transport_app/core/di/di.dart';

import 'cubit/blood_samples_cubit.dart';
// import 'cubit/return_approval_cubit.dart';
import 'view/requests_tab_view.dart';

/// Requests Tab Page — Transport Requests and Return Approval
class RequestsTabPage extends StatefulWidget {
  const RequestsTabPage({super.key});

  @override
  State<RequestsTabPage> createState() => _RequestsTabPageState();
}

class _RequestsTabPageState extends State<RequestsTabPage> {
  late final BloodSamplesCubit _bloodSamplesCubit;
  // late final ReturnApprovalCubit _returnApprovalCubit;

  @override
  void initState() {
    super.initState();
    _bloodSamplesCubit = getIt<BloodSamplesCubit>()..loadRequests();
    // _returnApprovalCubit = getIt<ReturnApprovalCubit>()..loadReturnRequests();
  }

  @override
  void dispose() {
    _bloodSamplesCubit.close();
    // _returnApprovalCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _bloodSamplesCubit),
        // BlocProvider.value(value: _returnApprovalCubit),
      ],
      child: const RequestsTabView(),
    );
  }
}
