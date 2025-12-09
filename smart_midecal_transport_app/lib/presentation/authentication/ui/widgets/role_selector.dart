import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/core/assets/app_assets.dart';
import 'package:smart_midecal_transport_app/presentation/authentication/ui/cubit/sign_in_cubit.dart';
import 'package:smart_midecal_transport_app/presentation/authentication/ui/widgets/role_button.dart';

class RoleSelector extends StatelessWidget {
  final SignInCubit cubit;
  const RoleSelector({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignInCubit, dynamic>(
      bloc: cubit,
      builder: (_, __) {
        return Row(
          children: [
            RoleButton(
              active: cubit.isEmployee,
              label: "sign_in.role.employee".tr(),
              iconPath: cubit.isEmployee
                  ? AppAssets.signInEmployeeIcon
                  : AppAssets.signInEmployerIcon,
              onTap: () => cubit.setEmployee(true),
            ),
            SizedBox(width: 12.w),
            RoleButton(
              active: !cubit.isEmployee,
              label: "sign_in.role.employer".tr(),
              iconPath: !cubit.isEmployee
                  ? AppAssets.signInEmployeeIcon
                  : AppAssets.signInEmployerIcon,
              onTap: () => cubit.setEmployee(false),
            ),
          ],
        );
      },
    );
  }
}
