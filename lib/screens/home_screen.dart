import 'package:flutter/material.dart';
import '../models/document.dart';
import '../services/search_service.dart';
import '../widgets/download_progress_dialog.dart';
import '../widgets/github_dialog.dart';
import 'pdf_viewer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SearchService _searchService = SearchService();
  final TextEditingController _searchController = TextEditingController();

  bool _isInitLoading = true;
  bool _isSearching = false;
  String _searchMode = 'content'; // 'content' (deep full-text) or 'title'
  String _selectedCategory = 'الكل';
  List<SearchResultItem> _results = [];

  final List<String> _categories = [
    'الكل',
    'قوانين',
    'مراسيم',
    'الجريدة الرسمية',
    'قرارات المحاكم',
    'الاتفاقيات الدولية',
    'مناشير وبلاغات',
    'إعلانات',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await _searchService.init();
    _executeSearch();
    setState(() {
      _isInitLoading = false;
    });

    // Start background loading of 9,030 pages index in background
    _searchService.loadContentIndexIfNeeded();
  }

  Future<void> _executeSearch() async {
    final query = _searchController.text.trim();
    final category = _selectedCategory == 'الكل' ? null : _selectedCategory;

    setState(() {
      _isSearching = true;
    });

    List<SearchResultItem> items = [];
    if (_searchMode == 'title' || query.isEmpty) {
      items = _searchService.searchTitles(query, category: category);
    } else {
      items = await _searchService.searchContent(query, category: category);
    }

    if (mounted) {
      setState(() {
        _results = items;
        _isSearching = false;
      });
    }
  }

  void _downloadDoc(DocumentModel doc) {
    final fileName = doc.fileName.isNotEmpty ? doc.fileName : '${doc.category}_${doc.id}.pdf';
    DownloadProgressDialog.show(
      context,
      assetPath: doc.assetPath,
      fileName: fileName,
      title: doc.titleAR,
    );
  }

  void _openPdfViewer(SearchResultItem item) async {
    final doc = item.document;
    final query = _searchController.text.trim();

    List<int> hits = [];
    if (query.isNotEmpty) {
      hits = await _searchService.getSearchHitsForDoc(doc.id, query);
    }

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(
          document: doc,
          initialPage: item.pageNum ?? 1,
          searchHits: hits,
          searchQuery: query,
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'قوانين':
        return const Color(0xFF059669);
      case 'مراسيم':
        return const Color(0xFF2563EB);
      case 'الجريدة الرسمية':
        return const Color(0xFFD97706);
      case 'قرارات المحاكم':
        return const Color(0xFF7C3AED);
      case 'الاتفاقيات الدولية':
        return const Color(0xFF0891B2);
      default:
        return const Color(0xFF475569);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF059669)),
              SizedBox(height: 16),
              Text(
                'جارٍ تهيئة الحقيبة القضائية والمكتبة الرقمية...',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF064E3B),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
              ),
              child: const Icon(Icons.balance, color: Color(0xFFF59E0B), size: 22),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'الحقيبة القضائية الموريتانية',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'محرك البحث ومتصفح وتنزيل القوانين',
                  style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'مستودع المشروع على GitHub',
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.25)),
              ),
              child: const GitHubIcon(size: 18, color: Colors.white),
            ),
            onPressed: () => showGitHubReposDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Hero & Filter Area
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: const BoxDecoration(
              color: Color(0xFF064E3B),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Search Input Box
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _executeSearch(),
                    onChanged: (val) {
                      if (_searchMode == 'title') {
                        _executeSearch();
                      }
                    },
                    decoration: InputDecoration(
                      hintText: _searchMode == 'content'
                          ? 'ابحث في نصوص وصفحات القوانين (مثال: عقوبة، إيجار، تجارة)...'
                          : 'ابحث في عناوين الوثائق والقرارات القانونية...',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF059669)),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                _executeSearch();
                              },
                            ),
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: ElevatedButton(
                              onPressed: _executeSearch,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF059669),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              child: const Text('بحث', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Search Mode Toggle
                Row(
                  children: [
                    _buildModeChip('content', 'البحث في نصوص الصفحات', Icons.document_scanner),
                    const SizedBox(width: 8),
                    _buildModeChip('title', 'في العناوين فقط', Icons.title),
                  ],
                ),
              ],
            ),
          ),

          // 2. Category Filters Horizontal Scroll
          Container(
            height: 48,
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat;
                final count = cat == 'الكل'
                    ? _searchService.documents.length
                    : _searchService.categoriesCounts[cat] ?? 0;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text('$cat ($count)'),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                      _executeSearch();
                    },
                    selectedColor: const Color(0xFF059669),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF334155),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                );
              },
            ),
          ),

          // 3. Results Header & Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _searchController.text.trim().isNotEmpty
                      ? 'نتائج البحث: ${_results.length} نتيجة'
                      : 'قائمة الوثائق (${_results.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                    fontSize: 13,
                  ),
                ),
                if (_isSearching)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF059669)),
                  ),
              ],
            ),
          ),

          // 4. Results List
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off, size: 54, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'لم يتم العثور على نتائج مطابقة',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF475569)),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'جرّب البحث بكلمات أخرى أو التبديل بين البحث في العناوين والبحث في النصوص',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final item = _results[index];
                      final doc = item.document;
                      final catColor = _getCategoryColor(doc.category);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: InkWell(
                          onTap: () => _openPdfViewer(item),
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Category Badge & Page Hit
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: catColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: catColor.withOpacity(0.3)),
                                      ),
                                      child: Text(
                                        doc.category,
                                        style: TextStyle(
                                          color: catColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (item.pageNum != null) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFFFCD34D)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.bookmark, color: Color(0xFFD97706), size: 12),
                                            const SizedBox(width: 4),
                                            Text(
                                              'صفحة ${item.pageNum}',
                                              style: const TextStyle(
                                                color: Color(0xFF92400E),
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Title Arabic
                                Text(
                                  doc.titleAR,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                    height: 1.4,
                                  ),
                                ),

                                // Title French (if present)
                                if (doc.titleFR.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    doc.titleFR,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],

                                // Snippet with highlight (if content search hit)
                                if (item.snippet != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                    ),
                                    child: Text(
                                      item.snippet!,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF334155),
                                        height: 1.4,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),

                                // Action Buttons: Open & Download Full PDF
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () => _downloadDoc(doc),
                                      icon: const Icon(Icons.download, size: 16),
                                      label: const Text('تنزيل كامل الـ PDF'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF065F46),
                                        side: const BorderSide(color: Color(0xFF059669)),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: () => _openPdfViewer(item),
                                      icon: const Icon(Icons.chrome_reader_mode, size: 16),
                                      label: Text(
                                        item.pageNum != null ? 'قراءة (صفحة ${item.pageNum})' : 'قراءة الوثيقة',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF059669),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // 3. Footer Bar: App Info & "مصنوع بواسطة mokhtar eby" + GitHub
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  offset: const Offset(0, -2),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.balance, size: 14, color: Color(0xFF059669)),
                    SizedBox(width: 6),
                    Text(
                      'الحقيبة القضائية الموريتانية',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => showGitHubReposDialog(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF059669).withOpacity(0.2)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.code, size: 13, color: Color(0xFF059669)),
                        SizedBox(width: 4),
                        Text(
                          'مصنوع بواسطة mokhtar eby',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF065F46),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 6),
                        GitHubIcon(size: 13, color: Color(0xFF065F46)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip(String mode, String label, IconData icon) {
    final isSelected = _searchMode == mode;
    return InkWell(
      onTap: () {
        setState(() {
          _searchMode = mode;
        });
        _executeSearch();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF59E0B) : Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFF59E0B) : Colors.white.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? const Color(0xFF0F172A) : Colors.white,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
