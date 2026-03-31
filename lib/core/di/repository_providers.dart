// Repository provider declarations for dependency injection.
//
// Presentation layer should import repository providers from here,
// never directly from data/repositories/*_impl.dart files.
// This maintains Clean Architecture's dependency inversion principle.

export 'package:fishfeed/data/repositories/ai_scan_repository.dart'
    show aiScanRepositoryProvider;
export 'package:fishfeed/data/repositories/aquarium_repository_impl.dart'
    show aquariumRepositoryProvider;
export 'package:fishfeed/data/repositories/auth_repository_impl.dart'
    show authRepositoryProvider;
export 'package:fishfeed/data/repositories/family_repository_impl.dart'
    show familyRepositoryProvider;
export 'package:fishfeed/data/repositories/fish_repository_impl.dart'
    show fishRepositoryProvider;
export 'package:fishfeed/data/repositories/push_repository_impl.dart'
    show pushRepositoryProvider;
export 'package:fishfeed/data/repositories/settings_repository_impl.dart'
    show settingsRepositoryProvider;
export 'package:fishfeed/data/repositories/species_repository_impl.dart'
    show speciesRepositoryProvider;
export 'package:fishfeed/data/repositories/streak_repository_impl.dart'
    show streakRepositoryProvider;
export 'package:fishfeed/data/repositories/user_repository_impl.dart'
    show userRepositoryProvider;
