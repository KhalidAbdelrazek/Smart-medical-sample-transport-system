import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';
import 'package:smart_midecal_transport_app/presentation/request%20sample/ui/widgets/urgency_button.dart';
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
        border: BoxBorder.all(
          color: theme.highlightColor,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormFields.label("Patient Name", theme),
          SizedBox(height: 6.h),
          FormFields.inputField(
            widget.requestBloodViewModel.patientController,
            "Enter patient name",
            theme,
          ),
          SizedBox(height: 16.h),
          FormFields.label("Blood Type", theme),
          SizedBox(height: 6.h),
          FormFields.dropdown(widget.requestBloodViewModel, theme, setState),
          SizedBox(height: 16.h),
          FormFields.label("Urgency Level", theme),
          SizedBox(height: 10.h),
          UrgencyButtons(
              requestBloodViewModel: widget.requestBloodViewModel,
              theme: theme,
              isDark: isDark,
              onChange: () => setState(() {})),
          SizedBox(height: 16.h),
          FormFields.label("Location", theme),
          SizedBox(height: 6.h),
          FormFields.inputField(
            widget.requestBloodViewModel.locationController,
            "Enter location or room number",
            theme,
          ),
          SizedBox(height: 16.h),
          FormFields.label("Additional Notes", theme),
          SizedBox(height: 6.h),
          FormFields.notesField(widget.requestBloodViewModel.notesController, theme),
          SizedBox(height: 20.h),
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
                "Submit Request",
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
