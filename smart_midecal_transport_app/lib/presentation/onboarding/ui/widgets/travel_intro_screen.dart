import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class TravelIntroScreen extends StatelessWidget {
  final String? backgroundImage;
  final String? title;
  final String? description;
  final String? nextText;
  final String? backText;
  final VoidCallback? onNextPressed;
  final VoidCallback? onBackPressed;
  final Color? color;

  const TravelIntroScreen({
    super.key,
    this.color,
    this.backgroundImage,
    this.title,
    this.description,
    this.nextText,
    this.backText,
    this.onNextPressed,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          /// Background image
          if (backgroundImage != null)
            SizedBox.expand(
              child: Image.asset(
                backgroundImage!,
                fit: BoxFit.cover,
              ),
            ),
            
          /// Gradient Overlay for better text readability
          if (backgroundImage != null)
            SizedBox.expand(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.5, 0.7, 1.0],
                  ),
                ),
              ),
            ),

          /// Overlay content
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 40.h),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  if (description != null) ...[
                    SizedBox(height: 16.h),
                    Text(
                      description!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  SizedBox(height: 32.h),

                  /// Buttons
                  Column(
                    children: [
                      if (nextText != null && onNextPressed != null)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: onNextPressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              elevation: 0,
                            ),
                            child: Text(
                              nextText!,
                              style: GoogleFonts.inter(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      if (backText != null && nextText != null)
                        SizedBox(height: 16.h),
                      if (backText != null && onBackPressed != null)
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: onBackPressed,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              foregroundColor: theme.textTheme.bodyMedium?.color,
                            ),
                            child: Text(
                              backText!,
                              style: GoogleFonts.inter(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                                color: theme.hintColor,
                              ),
                            ),
                          ),
                        ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}