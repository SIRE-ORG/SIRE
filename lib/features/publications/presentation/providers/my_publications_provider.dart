import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/api_flags.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/publication_image_datasource.dart';
import '../../data/datasources/publication_image_datasource_impl.dart';
import '../../data/datasources/publications_remote_datasource.dart';
import '../../data/datasources/publications_remote_datasource_mock_impl.dart';
import '../../data/datasources/publications_remote_datasource_real_impl.dart';
import '../../data/repositories/publications_repository_impl.dart';
import '../../domain/entities/publication.dart';
import '../../domain/entities/publication_summary_item.dart';
import '../../domain/repositories/publications_repository.dart';
import '../../domain/usecases/create_publication_usecase.dart';
import '../../domain/usecases/delete_publication_usecase.dart';
import '../../domain/usecases/get_my_publications_usecase.dart';
import '../../domain/usecases/get_publication_detail_usecase.dart';
import '../../domain/usecases/toggle_publication_status_usecase.dart';
import '../../domain/usecases/update_publication_usecase.dart';

part 'my_publications_provider.g.dart';

// ---------------------------------------------------------------------------
// Infraestructura
// ---------------------------------------------------------------------------

@riverpod
PublicationsRemoteDatasource publicationsRemoteDatasource(Ref ref) =>
    ApiFlags.useRealBackend
    ? PublicationsRemoteDatasourceRealImpl(
        dio: DioClient.createSync().dio,
        supabase: Supabase.instance.client,
      )
    : PublicationsRemoteDatasourceMockImpl();

@riverpod
PublicationImageDatasource publicationImageDatasource(Ref ref) =>
    PublicationImageDatasourceImpl();

@riverpod
PublicationsRepository publicationsRepository(Ref ref) =>
    PublicationsRepositoryImpl(
      remoteDatasource: ref.watch(publicationsRemoteDatasourceProvider),
    );

// ---------------------------------------------------------------------------
// Detalle de publicación (family)
// ---------------------------------------------------------------------------

@riverpod
Future<Publication> publicationDetail(Ref ref, String id) {
  final repo = ref.watch(publicationsRepositoryProvider);
  return GetPublicationDetailUseCase(repo).call(id: id);
}

// ---------------------------------------------------------------------------
// MyPublicationsNotifier — listado paginado del publicador
// ---------------------------------------------------------------------------

@riverpod
class MyPublicationsNotifier extends _$MyPublicationsNotifier {
  int _page = 1;
  bool _hasMore = false;

  @override
  Future<List<PublicationSummaryItem>> build() async {
    final result = await GetMyPublicationsUseCase(
      ref.read(publicationsRepositoryProvider),
    ).call(page: 1);
    _page = 1;
    _hasMore = result.hasMore;
    return result.items;
  }

  bool get hasMore => _hasMore;

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !_hasMore) return;
    final nextPage = _page + 1;
    final result = await GetMyPublicationsUseCase(
      ref.read(publicationsRepositoryProvider),
    ).call(page: nextPage);
    _page = nextPage;
    _hasMore = result.hasMore;
    state = AsyncData([...current, ...result.items]);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

// ---------------------------------------------------------------------------
// PublicationFormNotifier — create / update / toggle / delete
// ---------------------------------------------------------------------------

@riverpod
class PublicationFormNotifier extends _$PublicationFormNotifier {
  @override
  FutureOr<void> build() {}

  Future<Publication> create({
    required CreatePublicationParams params,
    Uint8List? imageBytes,
    String? imageExtension,
  }) async {
    state = const AsyncLoading();
    try {
      final result =
          await CreatePublicationUseCase(
            repository: ref.read(publicationsRepositoryProvider),
            imageDatasource: ref.read(publicationImageDatasourceProvider),
          ).call(
            params: params,
            imageBytes: imageBytes,
            imageExtension: imageExtension,
          );
      state = const AsyncData(null);
      ref.invalidate(myPublicationsNotifierProvider);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<Publication> edit({
    required String id,
    required UpdatePublicationParams params,
    Uint8List? imageBytes,
    String? imageExtension,
  }) async {
    state = const AsyncLoading();
    try {
      final result =
          await UpdatePublicationUseCase(
            repository: ref.read(publicationsRepositoryProvider),
            imageDatasource: ref.read(publicationImageDatasourceProvider),
          ).call(
            id: id,
            params: params,
            imageBytes: imageBytes,
            imageExtension: imageExtension,
          );
      state = const AsyncData(null);
      ref.invalidate(myPublicationsNotifierProvider);
      ref.invalidate(publicationDetailProvider(id));
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> toggleStatus({
    required String id,
    required bool isActive,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => TogglePublicationStatusUseCase(
        ref.read(publicationsRepositoryProvider),
      ).call(id: id, isActive: isActive),
    );
    ref.invalidate(myPublicationsNotifierProvider);
    ref.invalidate(publicationDetailProvider(id));
  }

  Future<void> delete({required String id}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => DeletePublicationUseCase(
        ref.read(publicationsRepositoryProvider),
      ).call(id: id),
    );
    ref.invalidate(myPublicationsNotifierProvider);
  }
}
