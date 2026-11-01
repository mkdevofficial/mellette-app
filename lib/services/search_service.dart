import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:archive/archive.dart';
import '../models/document.dart';

class SearchService {
  static final SearchService _instance = SearchService._internal();
  factory SearchService() => _instance;
  SearchService._internal();

  List<DocumentModel> _documents = [];
  Map<String, DocumentModel> _docsMap = {};
  Map<String, int> _categoriesCounts = {};
  List<Map<String, dynamic>>? _pagesIndex;
  bool _isLoadingContentIndex = false;
  bool _isInitialized = false;

  List<DocumentModel> get documents => _documents;
  Map<String, int> get categoriesCounts => _categoriesCounts;
  bool get isInitialized => _isInitialized;
  bool get isContentLoaded => _pagesIndex != null;

  /// Initialize and load documents metadata
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final jsonStr = await rootBundle.loadString('assets/data/documents.json');
      final List<dynamic> list = json.decode(jsonStr) as List<dynamic>;

      _documents = list.map((e) => DocumentModel.fromJson(e as Map<String, dynamic>)).toList();
      _docsMap = {for (var d in _documents) d.id: d};

      // Calculate categories counts
      final counts = <String, int>{};
      for (var d in _documents) {
        counts[d.category] = (counts[d.category] ?? 0) + 1;
      }
      _categoriesCounts = counts;
      _isInitialized = true;
    } catch (e) {
      // ignore
    }
  }

  /// Lazy load and decompress the 9,030 pages index for deep full-text search
  Future<void> loadContentIndexIfNeeded() async {
    if (_pagesIndex != null || _isLoadingContentIndex) return;
    _isLoadingContentIndex = true;

    try {
      final byteData = await rootBundle.load('assets/data/pages_index.json.gz');
      final gzBytes = byteData.buffer.asUint8List();
      final decompressedBytes = GZipDecoder().decodeBytes(gzBytes);
      final jsonStr = utf8.decode(decompressedBytes);
      final List<dynamic> rawList = json.decode(jsonStr) as List<dynamic>;

      _pagesIndex = rawList.cast<Map<String, dynamic>>();
    } catch (e) {
      // ignore
    } finally {
      _isLoadingContentIndex = false;
    }
  }

  /// Normalize Arabic text for uniform matching
  static String normalizeArabic(String text) {
    if (text.isEmpty) return '';
    var str = text;

    // Remove tashkeel / diacritics
    str = str.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');

    // Normalize Alef variations
    str = str.replaceAll(RegExp(r'[أإآٱ]'), 'ا');

    // Normalize Taa Marbuta
    str = str.replaceAll('ة', 'ه');

    // Normalize Ya and Alef Maqsura
    str = str.replaceAll('ى', 'ي');

    // Remove Tatweel / Kasheeda
    str = str.replaceAll('\u0640', '');

    return str.toLowerCase().trim();
  }

  /// Search in Document Titles
  List<SearchResultItem> searchTitles(String query, {String? category}) {
    final cleanQuery = normalizeArabic(query);
    final results = <SearchResultItem>[];

    for (final doc in _documents) {
      if (category != null && category.isNotEmpty && category != 'الكل' && doc.category != category) {
        continue;
      }

      if (cleanQuery.isEmpty) {
        results.add(SearchResultItem(document: doc));
        continue;
      }

      final normTitleAR = normalizeArabic(doc.titleAR);
      final normTitleFR = doc.titleFR.toLowerCase();

      if (normTitleAR.contains(cleanQuery) || normTitleFR.contains(cleanQuery)) {
        results.add(SearchResultItem(document: doc));
      }
    }

    return results;
  }

  /// Search inside page contents (Deep Full-Text Search across 9,030 pages)
  Future<List<SearchResultItem>> searchContent(String query, {String? category, int limit = 60}) async {
    final cleanQuery = normalizeArabic(query);
    if (cleanQuery.isEmpty) {
      return searchTitles('', category: category);
    }

    await loadContentIndexIfNeeded();
    final pages = _pagesIndex;
    if (pages == null) return [];

    final results = <SearchResultItem>[];

    for (final page in pages) {
      final docId = page['d']?.toString() ?? '';
      final doc = _docsMap[docId];
      if (doc == null) continue;

      if (category != null && category.isNotEmpty && category != 'الكل' && doc.category != category) {
        continue;
      }

      final pageText = page['t']?.toString() ?? '';
      final normPageText = normalizeArabic(pageText);

      final index = normPageText.indexOf(cleanQuery);
      if (index != -1) {
        final pageNum = page['p'] as int? ?? 1;

        // Generate context snippet around the match
        final start = (index - 40).clamp(0, pageText.length);
        final end = (index + cleanQuery.length + 50).clamp(0, pageText.length);
        var snippet = pageText.substring(start, end).replaceAll('\n', ' ').trim();
        if (start > 0) snippet = '...$snippet';
        if (end < pageText.length) snippet = '$snippet...';

        results.add(SearchResultItem(
          document: doc,
          pageNum: pageNum,
          snippet: snippet,
        ));

        if (results.length >= limit) break;
      }
    }

    return results;
  }

  /// Get document by ID
  DocumentModel? getDocumentById(String id) => _docsMap[id];

  /// Get search hits (matching pages) for a specific document and query
  Future<List<int>> getSearchHitsForDoc(String docId, String query) async {
    final cleanQuery = normalizeArabic(query);
    if (cleanQuery.isEmpty) return [];

    await loadContentIndexIfNeeded();
    final pages = _pagesIndex;
    if (pages == null) return [];

    final hits = <int>[];
    for (final page in pages) {
      if (page['d']?.toString() == docId) {
        final pageText = page['t']?.toString() ?? '';
        if (normalizeArabic(pageText).contains(cleanQuery)) {
          final p = page['p'] as int? ?? 1;
          if (!hits.contains(p)) hits.add(p);
        }
      }
    }
    hits.sort();
    return hits;
  }
}
