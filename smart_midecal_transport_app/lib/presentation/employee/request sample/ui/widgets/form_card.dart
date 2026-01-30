import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';
import 'package:smart_midecal_transport_app/presentation/employee/request%20sample/ui/widgets/urgency_button.dart';
import '../cubit/request_blood_view_model.dart';
import 'form_fields.dart';

class FormCard extends StatefulWidget {
  final RequestBloodViewModel requestBloodViewModel;
  const FormCard({super.key, required this.requestBloodViewModel});

  @override
  State<FormCard> createState() => _FormCardState();
}

class _FormCardState extends State<FormCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: BoxBorder.all(color: theme.highlightColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient Name
          FormFields.label("request_sample.patient_name".tr(), theme),
          SizedBox(height: 6.h),
          FormFields.inputField(
            widget.requestBloodViewModel.patientController,
            "request_sample.enter_patient_name".tr(),
            theme,
          ),
          SizedBox(height: 16.h),

          // Blood Type
          FormFields.label("request_sample.blood_type".tr(), theme),
          SizedBox(height: 6.h),
          FormFields.dropdown(widget.requestBloodViewModel, theme, setState),
          SizedBox(height: 16.h),

          // Urgency Level
          FormFields.label("request_sample.urgency_level".tr(), theme),
          SizedBox(height: 10.h),
          UrgencyButtons(
            requestBloodViewModel: widget.requestBloodViewModel,
            theme: theme,
            isDark: isDark,
            onChange: () => setState(() {}),
          ),
          SizedBox(height: 16.h),

          // Location
          FormFields.label("request_sample.location".tr(), theme),
          SizedBox(height: 6.h),
          FormFields.inputField(
            widget.requestBloodViewModel.locationController,
            "request_sample.enter_location".tr(),
            theme,
          ),
          SizedBox(height: 16.h),

          // Additional Notes
          FormFields.label("request_sample.additional_notes".tr(), theme),
          SizedBox(height: 6.h),
          FormFields.notesField(
            widget.requestBloodViewModel.notesController,
            theme,
          ),
          SizedBox(height: 20.h),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonColor,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              onPressed: () {},
              child: Text(
                "request_sample.submit_request".tr(),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
