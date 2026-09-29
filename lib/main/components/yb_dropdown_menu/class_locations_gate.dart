import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/components/system_page.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/system_theme.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/class_locations_cubit/class_locations_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/class_location.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/contracts/class_location_repository.dart';

/// Subscribes to the live location list and builds [builder] once it has at
/// least one location; shows loading / error / empty states otherwise.
/// Set [pageTitle] when used above a page, so those states keep the page
/// chrome and back button.
class ClassLocationsGate extends StatelessWidget {
  const ClassLocationsGate({super.key, required this.builder, this.pageTitle});
  final Widget Function(BuildContext context, List<ClassLocation> locations)
      builder;
  final String? pageTitle;

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) =>
            ClassLocationsCubit(GetIt.I<ClassLocationRepository>())..watch(),
        child: BlocBuilder<ClassLocationsCubit, ClassLocationsState>(
            builder: (context, state) {
          final locations = state.locations;
          if (locations != null && locations.isNotEmpty) {
            return builder(context, locations);
          }
          return _frame(context, _status(context, state));
        }),
      );

  Widget _frame(BuildContext context, Widget child) => pageTitle == null
      ? child
      : SystemPage(title: pageTitle!, scaffoldKey: GlobalKey(), child: child);

  Widget _status(BuildContext context, ClassLocationsState state) {
    if (state.locations == null && state.errorMessage == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final ds = SystemTheme.of(context);
    return Center(
        child: Padding(
            padding: EdgeInsets.all(ds.metric('spaceMedium')),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(state.errorMessage ?? '尚未設定任何據點，請聯絡管理員。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: ds.metric('bodySize'),
                      color: ds.color('secondaryText'))),
              const SizedBox(height: 12),
              OutlinedButton(
                  onPressed: context.read<ClassLocationsCubit>().watch,
                  child: const Text('重新載入')),
            ])));
  }
}
