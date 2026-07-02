import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/presentation/employee/root/domain/entity/notification_response_entity.dart';

/// Shows a two-step dialog:
///   Step 1 – Ask "Do you want to return samples?"
///   Step 2 – If yes, show a selectable list of returnable samples from the car.
///
/// Returns:
///   • `null`          – dialog was dismissed without a decision
///   • `[]` (empty)    – user chose "No" (send empty list to backend)
///   • `[codes...]`    – user chose "Yes" and selected samples
class ReturnHandoffDialog extends StatefulWidget {
  const ReturnHandoffDialog._({required this.returnableSamples});

  final List<ReturnableSamplesEntity> returnableSamples;

  /// Shows the dialog and returns the user's decision.
  static Future<List<String>?> show(
    BuildContext context, {
    required List<ReturnableSamplesEntity> returnableSamples,
  }) {
    return showDialog<List<String>>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          ReturnHandoffDialog._(returnableSamples: returnableSamples),
    );
  }

  @override
  State<ReturnHandoffDialog> createState() => _ReturnHandoffDialogState();
}

class _ReturnHandoffDialogState extends State<ReturnHandoffDialog> {
  // null = step 1 (ask yes/no), true = step 2 (show sample list)
  bool _showSampleList = false;
  final Set<String> _selected = {};

  void _selectAll() {
    setState(() {
      _selected.addAll(
        widget.returnableSamples.map((s) => s.sampleCode).whereType<String>(),
      );
    });
  }

  void _clearAll() {
    setState(() => _selected.clear());
  }

  void _toggle(String code) {
    setState(() {
      if (_selected.contains(code)) {
        _selected.remove(code);
      } else {
        _selected.add(code);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        child: _showSampleList
            ? _buildSampleListStep(theme, scheme)
            : _buildYesNoStep(theme, scheme),
      ),
    );
  }

  // ─────────────── Step 1: Yes / No ───────────────

  Widget _buildYesNoStep(ThemeData theme, ColorScheme scheme) {
    return Padding(
      padding: EdgeInsets.all(24.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            width: 56.r,
            height: 56.r,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.swap_horiz_rounded,
              size: 30.r,
              color: scheme.onPrimaryContainer,
            ),
          ),
          SizedBox(height: 16.h),

          // Title
          Text(
            'employee.return_handoff_title'.tr(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),

          // Subtitle
          Text(
            'employee.return_handoff_subtitle'.tr(
              args: ['${widget.returnableSamples.length}'],
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(<String>[]),
                  child: Text('employee.return_handoff_no'.tr()),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: FilledButton(
                  onPressed: () => setState(() => _showSampleList = true),
                  child: Text('employee.return_handoff_yes'.tr()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────── Step 2: Sample List ───────────────

  Widget _buildSampleListStep(ThemeData theme, ColorScheme scheme) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 16.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: () => setState(() {
                  _showSampleList = false;
                  _selected.clear();
                }),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'employee.return_handoff_select_title'.tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),

          // Select-all / clear row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _selectAll,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                ),
                child: Text(
                  'employee.return_handoff_select_all'.tr(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.primary,
                  ),
                ),
              ),
              Text('·', style: TextStyle(color: scheme.onSurfaceVariant)),
              TextButton(
                onPressed: _clearAll,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                ),
                child: Text(
                  'employee.return_handoff_clear'.tr(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.error,
                  ),
                ),
              ),
            ],
          ),

          // Sample list (constrained height)
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: 0.45 * MediaQuery.of(context).size.height,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.returnableSamples.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
              itemBuilder: (context, index) {
                final sample = widget.returnableSamples[index];
                final code = sample.sampleCode ?? '';
                final isSelected = _selected.contains(code);

                return InkWell(
                  onTap: code.isEmpty ? null : () => _toggle(code),
                  borderRadius: BorderRadius.circular(8.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 10.h,
                      horizontal: 4.w,
                    ),
                    child: Row(
                      children: [
                        // Checkbox
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 22.r,
                          height: 22.r,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? scheme.primary
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? scheme.primary
                                  : scheme.outline,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check_rounded,
                                  size: 14.r,
                                  color: scheme.onPrimary,
                                )
                              : null,
                        ),
                        SizedBox(width: 12.w),

                        // Sample info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sample.patientName ?? '—',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurface,
                                ),
                              ),
                              if (code.isNotEmpty) ...[
                                SizedBox(height: 2.h),
                                Text(
                                  code,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 16.h),

          // Confirm / Cancel row
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(<String>[]),
                  child: Text('employee.return_handoff_skip'.tr()),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _selected.isEmpty
                      ? null
                      : () => Navigator.of(context).pop(_selected.toList()),
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: Text(
                    'employee.return_handoff_confirm'.tr(
                      args: ['${_selected.length}'],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }
}
