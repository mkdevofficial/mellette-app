class DocumentModel {
  final String id;
  final String category;
  final String titleAR;
  final String titleFR;
  final String fileName;
  final String assetPath;

  DocumentModel({
    required this.id,
    required this.category,
    required this.titleAR,
    required this.titleFR,
    required this.fileName,
    required this.assetPath,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as String? ?? '',
      category: json['category'] as String? ?? 'عام',
      titleAR: json['titleAR'] as String? ?? '',
      titleFR: json['titleFR'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      assetPath: json['assetPath'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'titleAR': titleAR,
      'titleFR': titleFR,
      'fileName': fileName,
      'assetPath': assetPath,
    };
  }
}

class SearchResultItem {
  final DocumentModel document;
  final int? pageNum;
  final String? snippet;

  SearchResultItem({
    required this.document,
    this.pageNum,
    this.snippet,
  });
}
