import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomButton extends StatelessWidget {
  final Widget body;
  final Color? color;
  final Color? backgroundColor;
  final int? borderRadius;
  final void Function()? onPressed;
  final double? width;
  final double? height;

  const CustomButton({
    super.key,
    required this.body,
    this.onPressed,
    this.color,
    this.backgroundColor,
    this.borderRadius, this.width, this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width?.w,
      height: height?.h,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              backgroundColor ?? Theme.of(context).primaryColorDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side:
                borderRadius?.toDouble() != null
                    ? BorderSide(
                      width: borderRadius?.toDouble() ?? 0,
                      color: Theme.of(context).primaryColor,
                    )
                    : BorderSide.none,
          ),
        ),
        onPressed: onPressed,
        child: body,
      ),
    );
  }
}
