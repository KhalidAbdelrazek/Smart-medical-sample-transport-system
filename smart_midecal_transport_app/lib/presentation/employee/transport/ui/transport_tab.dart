import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_midecal_transport_app/core/di/di.dart';
import 'package:smart_midecal_transport_app/presentation/employee/transport/domain/transport_model_entity.dart';

import 'cubit/transport_states.dart';
import 'cubit/transport_view_model.dart';
import 'widgets/transport_card.dart';

class TransportTab extends StatefulWidget {
  const TransportTab({super.key});

  @override
  State<TransportTab> createState() => _TransportTabState();
}

class _TransportTabState extends State<TransportTab> {
  final TransportViewModel transportViewModel = getIt<TransportViewModel>();

  String selectedStatus = "all_status";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider(
      create: (_) => transportViewModel..loadTransports(),
      child: Scaffold(
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Column(
            children: [
              BlocBuilder<TransportViewModel, TransportState>(
                builder: (context, state) {
                  return DropdownButtonFormField<String>(
                    value: selectedStatus,
                    style: theme.textTheme.headlineSmall,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: theme.cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: theme.highlightColor, width: 0.5),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                          value: 'all_status',
                          child: Text("transport.all_status".tr())),
                      DropdownMenuItem(
                          value: 'pending',
                          child: Text("transport.pending".tr())),
                      DropdownMenuItem(
                          value: 'urgent',
                          child: Text("transport.urgent".tr())),
                      DropdownMenuItem(
                          value: 'completed',
                          child: Text("transport.completed".tr())),
                    ],
                    onChanged: (value) {
                      setState(() => selectedStatus = value!);
                      context.read<TransportViewModel>().filterByStatus(value!);
                    },
                  );
                },
              ),

              SizedBox(height: 16.h),

              /// --- Transport List ---
              Expanded(
                child: BlocBuilder<TransportViewModel, TransportState>(
                  builder: (context, state) {
                    if (state is TransportLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    List<TransportModelEntity> data = [];

                    if (state is TransportLoaded) {
                      data = state.transports;
                    } else if (state is TransportFiltered) {
                      data = state.filtered;
                    }

                    return ListView.builder(
                      itemCount: data.length,
                      itemBuilder: (context, index) =>
                          Column(
                            children: [
                              TransportCard(transport: data[index]),
                              SizedBox(height: 12.h,)
                            ],
                          ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
