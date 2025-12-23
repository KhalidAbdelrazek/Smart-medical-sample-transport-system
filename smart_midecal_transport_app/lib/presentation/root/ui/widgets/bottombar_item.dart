import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';

class BottomBarItem extends StatefulWidget {
  const BottomBarItem(
    this.icon,
    this.title, {
    super.key,
    this.onTap,
    this.color = AppColors.inActiveColor,
    this.activeColor = AppColors.primaryLight,
    this.isActive = false,
    this.isNotified = false,
  });

  final String icon;
  final String title;
  final Color color;
  final Color activeColor;
  final bool isNotified;
  final bool isActive;
  final GestureTapCallback? onTap;

  @override
  State<BottomBarItem> createState() => _BottomBarItemState();
}

class _BottomBarItemState extends State<BottomBarItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
       duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
     if (widget.isActive) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant BottomBarItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: widget.isActive 
                      ? widget.activeColor.withOpacity(0.1) 
                      : Colors.transparent,
                ),
                child: SvgPicture.asset(
                  widget.icon,
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    widget.isActive ? widget.activeColor : widget.color,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Optional: Add indicator dot or label if desired
            Text(
              widget.title,
              style: TextStyle(
                color: widget.isActive ? widget.activeColor : widget.color,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
