import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../data/models/person_detail_model.dart';
import '../../data/datasources/person_remote_datasource.dart';

final personRemoteDataSourceProvider = Provider<PersonRemoteDataSource>((ref) {
  return PersonRemoteDataSource();
});

/// Person filmography filter: 'all', 'movie', 'tv'
final personFilmographyFilterProvider = StateProvider.autoDispose<String>((ref) => 'all');

/// Fetches full person details & filmography
final personDetailProvider =
    FutureProvider.autoDispose.family<PersonDetailModel, int>((ref, personId) async {
  final lang = ref.watch(appLanguageProvider);
  final tmdbLang = lang == AppLanguage.en ? 'en-US' : 'id-ID';
  final dataSource = ref.watch(personRemoteDataSourceProvider);
  return dataSource.getPersonDetail(personId, language: tmdbLang);
});

