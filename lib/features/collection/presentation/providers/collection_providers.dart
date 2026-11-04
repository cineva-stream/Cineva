import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../data/models/movie_collection_model.dart';
import '../../data/datasources/collection_remote_datasource.dart';

final collectionRemoteDataSourceProvider = Provider<CollectionRemoteDataSource>((ref) {
  return CollectionRemoteDataSource();
});

/// Fetches movie franchise collection details and parts
final collectionDetailProvider =
    FutureProvider.autoDispose.family<MovieCollectionModel, int>((ref, collectionId) async {
  final lang = ref.watch(appLanguageProvider);
  final tmdbLang = lang == AppLanguage.en ? 'en-US' : 'id-ID';
  final dataSource = ref.watch(collectionRemoteDataSourceProvider);
  return dataSource.getCollectionDetail(collectionId, language: tmdbLang);
});

