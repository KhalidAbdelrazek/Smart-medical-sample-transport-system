import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/core/di/di.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';

import 'cubit/restrictions_cubit.dart';
import 'cubit/restrictions_state.dart';
import 'widgets/custom_expandable_dropdown.dart';
import 'widgets/restrictions_skeleton.dart';
import 'widgets/user_restriction_tile.dart';

class RestrictionsTabPage extends StatefulWidget {
  const RestrictionsTabPage({super.key});

  @override
  State<RestrictionsTabPage> createState() => _RestrictionsTabPageState();
}

class _RestrictionsTabPageState extends State<RestrictionsTabPage>
    with AutomaticKeepAliveClientMixin {
  late RestrictionsCubit _cubit;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<RestrictionsCubit>()..loadData();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<RestrictionsCubit, RestrictionsState>(
        listener: (context, state) {
          if (state is RestrictionsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () => _cubit.refresh(),
            color: AppColors.primaryLight,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: _buildContent(context, state),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, RestrictionsState state) {
    if (state is RestrictionsLoading || state is RestrictionsInitial) {
      return const RestrictionsSkeleton(key: ValueKey('loading'));
    }

    if (state is RestrictionsError) {
      return Center(
        key: const ValueKey('error'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(state.message),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _cubit.loadData(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is RestrictionsLoaded) {
      return _LoadedBody(key: const ValueKey('loaded'), state: state);
    }

    return const SizedBox.shrink();
  }
}

class _LoadedBody extends StatelessWidget {
  final RestrictionsLoaded state;

  const _LoadedBody({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RestrictionsCubit>();
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      children: [
        // ── Header ───────────────────────────────────────────────────
        const _PageHeader(),
        SizedBox(height: 32.h),

        // ── Doctor Restrictions ──────────────────────────────────────
        RestrictionsCard(
          title: 'Doctor Restrictions',
          subtitle: 'Manage operational access for all doctors',
          isGlobalOn: state.isAllDoctorsRestricted,
          isExpanded: state.isDoctorExpanded,
          isLoading: state.isDoctorLoading,
          onGlobalToggle: (v) => cubit.toggleDoctorGlobal(v),
          onExpandToggle: cubit.toggleDoctorExpanded,
          expandedContent: Column(
            children: state.doctors.asMap().entries.map((entry) {
              final index = entry.key;
              final doctor = entry.value; // DoctorsSamplesEntity
              return Column(
                children: [
                  UserRestrictionTile(
                    name: doctor.name ?? 'Unknown Doctor',
                    isRestricted: doctor.isRestricted ?? false,
                    onToggle: (v) =>
                        cubit.toggleIndividualDoctor(doctor.id!, v),
                    isLoading: state.isDoctorLoading,
                  ),
                  if (index != state.doctors.length - 1)
                    Divider(
                      height: 1,
                      indent: 62.w,
                      endIndent: 18.w,
                      color: cs.outlineVariant.withOpacity(0.4),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 16.h),

        // ── Storage Restrictions ─────────────────────────────────────
        RestrictionsCard(
          title: 'Storage Restrictions',
          subtitle: 'Manage sample loading access for employees',
          isGlobalOn: state.isAllStorageRestricted,
          isExpanded: state.isStorageExpanded,
          isLoading: state.isStorageLoading,
          onGlobalToggle: (v) => cubit.toggleStorageGlobal(v),
          onExpandToggle: cubit.toggleStorageExpanded,
          // Storage section expandedContent:
          expandedContent: Column(
            children: state.storageEmployees.asMap().entries.map((entry) {
              final index = entry.key;
              final employee = entry.value; // StorageSamplesEntity
              return Column(
                children: [
                  UserRestrictionTile(
                    name: employee.name ?? 'Unknown Employee',
                    isRestricted: employee.isRestricted ?? false,
                    onToggle: (v) =>
                        cubit.toggleIndividualStorage(employee.id!, v),
                    isLoading: state.isStorageLoading,
                  ),
                  if (index != state.storageEmployees.length - 1)
                    Divider(
                      height: 1,
                      indent: 62.w,
                      endIndent: 18.w,
                      color: cs.outlineVariant.withOpacity(0.4),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 16.h),

        // ── Transport Car Restriction ────────────────────────────────
        RestrictionsCard(
          title: 'Transport Car',
          subtitle: 'Prevent the car from dispatching requests',
          isGlobalOn: state.carRestricted,
          isExpanded: false,
          isLoading: state.isCarLoading,
          onGlobalToggle: (v) => cubit.toggleCarRestriction(v),
          onExpandToggle: () {},
          showExpand: false,
          activeColor: AppColors.warning,
          expandedContent: const SizedBox.shrink(),
        ),

        SizedBox(height: 40.h),
      ],
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Control',
          style: TextStyle(
            fontSize: 26.sp,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          'Manage operational restrictions and safety protocols across the entire transport network.',
          style: TextStyle(
            fontSize: 14.sp,
            height: 1.4,
            color: cs.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
