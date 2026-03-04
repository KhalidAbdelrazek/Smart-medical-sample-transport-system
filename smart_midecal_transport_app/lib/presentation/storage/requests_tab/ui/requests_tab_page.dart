import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_midecal_transport_app/core/di/di.dart';

import 'cubit/blood_samples_cubit.dart';
import 'view/blood_samples_view.dart';

/// Requests Tab Page — Blood Samples only (Blood Bag feature removed)
class RequestsTabPage extends StatefulWidget {
  const RequestsTabPage({super.key});

  @override
  State<RequestsTabPage> createState() => _RequestsTabPageState();
}

class _RequestsTabPageState extends State<RequestsTabPage> {
  late final BloodSamplesCubit _bloodSamplesCubit;

  @override
  void initState() {
    super.initState();
    _bloodSamplesCubit = getIt<BloodSamplesCubit>()..loadRequests();
  }

  @override
  void dispose() {
    _bloodSamplesCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloodSamplesCubit,
      child: const BloodSamplesView(),
    );
  }
}
