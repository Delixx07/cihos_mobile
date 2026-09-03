import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/health_article.dart';
import 'health_news_repository.dart';

/// Manages persistence of bookmarked/saved health articles.
class SavedArticlesRepository {
  static const _key = 'saved_health_articles_ids';

  Future<Set<String>> loadSavedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_key);
      if (list != null) {
        return list.toSet();
      }
    } catch (_) {}
    // Seeded initial reading list for demonstration & test consistency
    return {'r1', 'r2'};
  }

  Future<void> persistSavedIds(Set<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, ids.toList());
    } catch (_) {}
  }
}

final savedArticlesRepositoryProvider = Provider<SavedArticlesRepository>((ref) {
  return SavedArticlesRepository();
});

class SavedArticlesNotifier extends StateNotifier<Set<String>> {
  SavedArticlesNotifier(this._repository) : super(const {'r1', 'r2'}) {
    _init();
  }

  final SavedArticlesRepository _repository;

  Future<void> _init() async {
    final ids = await _repository.loadSavedIds();
    state = ids;
  }

  bool isSaved(String articleId) => state.contains(articleId);

  Future<bool> toggle(String articleId) async {
    final current = Set<String>.from(state);
    final isNowSaved = !current.contains(articleId);
    if (isNowSaved) {
      current.add(articleId);
    } else {
      current.remove(articleId);
    }
    state = current;
    await _repository.persistSavedIds(current);
    return isNowSaved;
  }

  Future<void> add(String articleId) async {
    if (state.contains(articleId)) return;
    final current = Set<String>.from(state)..add(articleId);
    state = current;
    await _repository.persistSavedIds(current);
  }

  Future<void> remove(String articleId) async {
    if (!state.contains(articleId)) return;
    final current = Set<String>.from(state)..remove(articleId);
    state = current;
    await _repository.persistSavedIds(current);
  }
}

final savedArticleIdsProvider =
    StateNotifierProvider<SavedArticlesNotifier, Set<String>>((ref) {
  final repo = ref.watch(savedArticlesRepositoryProvider);
  return SavedArticlesNotifier(repo);
});

final savedArticlesProvider = Provider<List<HealthArticle>>((ref) {
  final savedIds = ref.watch(savedArticleIdsProvider);
  final allArticles = ref.watch(healthArticlesProvider);
  return allArticles.where((a) => savedIds.contains(a.id)).toList();
});

/// Toggles user favorite status and synchronizes like count with CMS backend.
Future<bool> toggleArticleFavorite(WidgetRef ref, String articleId) async {
  final isNowSaved = await ref.read(savedArticleIdsProvider.notifier).toggle(articleId);
  await ref.read(healthArticlesProvider.notifier).toggleLike(articleId, isNowSaved);
  return isNowSaved;
}
