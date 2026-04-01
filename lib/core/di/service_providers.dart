// Service provider declarations for dependency injection.
//
// Registers image upload service providers that bridge data-layer
// services with domain-layer repositories. Presentation layer should
// import service providers from here, never directly from
// data/services/ files.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/core/di/datasource_providers.dart';
import 'package:fishfeed/core/di/repository_providers.dart';
import 'package:fishfeed/data/services/image_sync_queue.dart';
import 'package:fishfeed/data/services/image_upload_service.dart';
import 'package:fishfeed/presentation/providers/aquarium_providers.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/presentation/providers/fish_management_provider.dart';
import 'package:fishfeed/services/image_processing_service.dart';

/// Provider for [ImageSyncQueue].
///
/// Provides singleton access to the file-based image upload queue.
final imageSyncQueueProvider = Provider<ImageSyncQueue>((ref) {
  return ImageSyncQueue();
});

/// Provider for [ImageProcessingService].
///
/// Provides singleton access to the image compression service.
final imageProcessingServiceProvider = Provider<ImageProcessingService>((ref) {
  return ImageProcessingService();
});

/// Provider for [ImageUploadService].
///
/// Wires together the queue, image processor, Dio client, and the
/// [EntityPhotoKeyUpdater] callback that updates local models after
/// successful uploads via repositories.
final imageUploadServiceProvider = Provider<ImageUploadService>((ref) {
  final queue = ref.watch(imageSyncQueueProvider);
  final imageProcessor = ref.watch(imageProcessingServiceProvider);
  final apiClient = ref.watch(apiClientProvider);
  final aquariumRepo = ref.read(aquariumRepositoryProvider);
  final fishRepo = ref.read(fishRepositoryProvider);
  final userRepo = ref.read(userRepositoryProvider);

  return ImageUploadService(
    queue: queue,
    imageProcessor: imageProcessor,
    dio: apiClient.dio,
    onUploadComplete:
        ({
          required String entityType,
          required String entityId,
          required String photoKey,
        }) async {
          switch (entityType) {
            case 'aquarium':
              await aquariumRepo.updatePhotoKeyLocally(
                aquariumId: entityId,
                photoKey: photoKey,
              );
              ref.read(userAquariumsProvider.notifier).loadAquariums();
            case 'fish':
              await fishRepo.updatePhotoKeyLocally(
                fishId: entityId,
                photoKey: photoKey,
              );
              ref.invalidate(fishByAquariumIdProvider);
            case 'avatar':
              await userRepo.updateAvatarKeyFromUpload(photoKey);
              ref.read(authNotifierProvider.notifier).updateAvatarKey(photoKey);
          }
        },
  );
});
