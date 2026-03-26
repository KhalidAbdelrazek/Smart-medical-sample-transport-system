import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_midecal_transport_app/core/di/di.dart';

import 'cubit/my_requests_cubit.dart';
import 'my_requests_view.dart';

/// Entry point for the "My Requests" tab. Owns the [MyRequestsCubit] lifecycle
/// and provides it down the tree via [BlocProvider.value].
class MyRequestsTabPage extends StatefulWidget {
  const MyRequestsTabPage({super.key});

  @override
  State<MyRequestsTabPage> createState() => _MyRequestsTabPageState();
}

class _MyRequestsTabPageState extends State<MyRequestsTabPage>
    with AutomaticKeepAliveClientMixin {
  late final MyRequestsCubit _cubit;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<MyRequestsCubit>()..loadMyRequests();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    return BlocProvider.value(
      value: _cubit,
      child: const MyRequestsView(),
    );
  }
}
