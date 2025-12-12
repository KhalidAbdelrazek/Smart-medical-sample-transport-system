import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/core/di/di.dart';
import 'package:smart_midecal_transport_app/presentation/request%20sample/ui/cubit/request_blood_view_model.dart';
import 'package:smart_midecal_transport_app/presentation/request%20sample/ui/widgets/recent_requests.dart';
import 'widgets/form_card.dart';

class RequestSampleTab extends StatefulWidget {
  const RequestSampleTab({super.key});

  @override
  State<RequestSampleTab> createState() => _RequestSampleTabState();
}

class _RequestSampleTabState extends State<RequestSampleTab> {
  final RequestBloodViewModel requestBloodViewModel =
      getIt<RequestBloodViewModel>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FormCard(requestBloodViewModel: requestBloodViewModel),
              SizedBox(height: 25.h),
              Text("request_sample.recent_requests".tr(), style: theme.textTheme.displaySmall),
              SizedBox(height: 12.h),
              RecentRequestsList(requestBloodViewModel: requestBloodViewModel),
              SizedBox(height: 50.h,)
            ],
          ),
        ),
      ),
    );
  }
}
