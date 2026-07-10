// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$profileHash() => r'9e5409c429e152ac38c0372e81afb6e4e3bccec2';

/// GET /v1/users/me (Phase 1.5). No screen reads this yet -- the Profile
/// Overlay UI is built in Phase 5 -- but the endpoint + provider exist now
/// per the Phase 1 API surface.
///
/// Copied from [profile].
@ProviderFor(profile)
final profileProvider =
    AutoDisposeFutureProvider<Map<String, dynamic>>.internal(
      profile,
      name: r'profileProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$profileHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProfileRef = AutoDisposeFutureProviderRef<Map<String, dynamic>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
