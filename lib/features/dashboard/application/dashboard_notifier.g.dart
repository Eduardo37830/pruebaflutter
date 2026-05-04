// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dashboardProjectsHash() => r'd08db9f316ac38b5d85bb34e18aeb55ba9ba2aa7';

/// Alimenta el listado completo de proyectos filtrando borrados de la DB local.
///
/// Copied from [dashboardProjects].
@ProviderFor(dashboardProjects)
final dashboardProjectsProvider =
    AutoDisposeStreamProvider<List<Project>>.internal(
      dashboardProjects,
      name: r'dashboardProjectsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$dashboardProjectsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DashboardProjectsRef = AutoDisposeStreamProviderRef<List<Project>>;
String _$dashboardNotifierHash() => r'9e959dcbd40042841fe473955e8b48240515e8aa';

/// Controla acciones como creacion, y borrado de proyectos del tablero
///
/// Copied from [DashboardNotifier].
@ProviderFor(DashboardNotifier)
final dashboardNotifierProvider =
    AutoDisposeNotifierProvider<DashboardNotifier, void>.internal(
      DashboardNotifier.new,
      name: r'dashboardNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$dashboardNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$DashboardNotifier = AutoDisposeNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
