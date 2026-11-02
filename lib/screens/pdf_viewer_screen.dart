import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/document.dart';
import '../widgets/download_progress_dialog.dart';

class PdfViewerScreen extends StatefulWidget {
  final DocumentModel document;
  final int initialPage;
  final List<int> searchHits;
  final String searchQuery;

  const PdfViewerScreen({
    super.key,
    required this.document,
    this.initialPage = 1,
    this.searchHits = const [],
    this.searchQuery = '',
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey<SfPdfViewerState>();
  late PdfViewerController _pdfViewerController;
  late TextEditingController _searchController;
  PdfTextSearchResult? _searchResult;

  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoading = true;
  bool _showMenu = false;

  // Custom text selection state
  String? _selectedText;
  Rect? _selectionRegion;
  Annotation? _selectedAnnotation;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pdfViewerController = PdfViewerController();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void dispose() {
    _searchResult?.removeListener(_onSearchResultUpdate);
    _searchResult?.clear();
    _searchResult?.dispose();
    _searchController.dispose();
    _pdfViewerController.dispose();
    super.dispose();
  }

  void _onDocumentLoaded(PdfDocumentLoadedDetails details) {
    setState(() {
      _totalPages = details.document.pages.count;
      _isLoading = false;
    });

    if (widget.initialPage > 1 && widget.initialPage <= _totalPages) {
      _pdfViewerController.jumpToPage(widget.initialPage);
    }

    if (widget.searchQuery.isNotEmpty) {
      _performInBookSearch(widget.searchQuery);
    }
  }

  void _onPageChanged(PdfPageChangedDetails details) {
    setState(() {
      _currentPage = details.newPageNumber;
    });
  }

  void _onSearchResultUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  void _performInBookSearch(String query) {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      _clearInBookSearch();
      return;
    }

    _searchResult?.removeListener(_onSearchResultUpdate);
    _searchResult?.clear();
    _searchResult?.dispose();

    setState(() {
      _searchResult = _pdfViewerController.searchText(cleanQuery);
    });

    _searchResult?.addListener(_onSearchResultUpdate);
  }

  void _clearInBookSearch() {
    _searchResult?.removeListener(_onSearchResultUpdate);
    _searchResult?.clear();
    _searchResult?.dispose();
    _searchResult = null;
    _searchController.clear();
    setState(() {});
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      _pdfViewerController.nextPage();
    }
  }

  void _prevPage() {
    if (_currentPage > 1) {
      _pdfViewerController.previousPage();
    }
  }

  void _downloadFullPdf() {
    setState(() {
      _showMenu = false;
    });

    final fileName = widget.document.fileName.isNotEmpty
        ? widget.document.fileName
        : '${widget.document.category}_${widget.document.id}.pdf';

    DownloadProgressDialog.show(
      context,
      assetPath: widget.document.assetPath,
      fileName: fileName,
      title: widget.document.titleAR,
    );
  }

  // === Text Selection & Annotation Handling ===

  void _onTextSelectionChanged(PdfTextSelectionChangedDetails details) {
    setState(() {
      _selectedText = details.selectedText;
      _selectionRegion = details.globalSelectedRegion;
      if (_selectedText != null && _selectedText!.isNotEmpty) {
        _selectedAnnotation = null;
      }
    });
  }

  void _onAnnotationSelected(Annotation annotation) {
    setState(() {
      _selectedAnnotation = annotation;
      _selectedText = null;
      _selectionRegion = null;
    });
  }

  void _onAnnotationDeselected(Annotation annotation) {
    if (_selectedAnnotation == annotation) {
      setState(() {
        _selectedAnnotation = null;
      });
    }
  }

  /// Copies the currently selected text to system clipboard
  void _copySelectedText() {
    if (_selectedText == null || _selectedText!.isEmpty) return;

    Clipboard.setData(ClipboardData(text: _selectedText!));
    _pdfViewerController.clearSelection();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF34D399), size: 18),
            SizedBox(width: 8),
            Text('تم نسخ النص المحدد إلى الحافظة بنجاح'),
          ],
        ),
        backgroundColor: Color(0xFF065F46),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Shares the currently selected text
  void _shareSelectedText() {
    if (_selectedText == null || _selectedText!.isEmpty) return;

    final textToShare = _selectedText!;
    _pdfViewerController.clearSelection();
    Share.share(textToShare);
  }

  /// Searches for the currently selected text inside the PDF
  void _searchSelectedText() {
    if (_selectedText == null || _selectedText!.isEmpty) return;

    final query = _selectedText!;
    _pdfViewerController.clearSelection();
    _searchController.text = query;
    _performInBookSearch(query);
  }

  List<Rect> _getStoredRects(Annotation annotation) {
    final subject = annotation.subject ?? '';
    if (subject.isEmpty) return [];
    final rects = <Rect>[];
    for (final part in subject.split(';')) {
      final coords = part.split(',').map((s) => double.tryParse(s)).toList();
      if (coords.length == 4 && coords.every((c) => c != null)) {
        rects.add(Rect.fromLTRB(coords[0]!, coords[1]!, coords[2]!, coords[3]!));
      }
    }
    return rects;
  }

  /// Checks if an annotation overlaps with any of the selected text lines
  bool _overlapsWithSelectedLines(Annotation annotation, List<PdfTextLine> selectedLines) {
    if (selectedLines.isEmpty) return false;
    if (annotation.pageNumber != selectedLines.first.pageNumber) return false;

    final storedRects = _getStoredRects(annotation);
    if (storedRects.isEmpty) {
      return true;
    }

    for (final line in selectedLines) {
      for (final sRect in storedRects) {
        if (sRect.overlaps(line.bounds) || sRect.contains(line.bounds.center)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Toggles Underline Annotation on selected text (adds if absent, removes if already present)
  void _toggleUnderlineAnnotation() {
    final selectedLines = _pdfViewerKey.currentState?.getSelectedTextLines() ?? [];
    if (selectedLines.isEmpty) {
      _pdfViewerController.clearSelection();
      return;
    }

    final allAnnotations = _pdfViewerController.getAnnotations();
    final existing = allAnnotations.cast<Annotation?>().firstWhere(
          (a) => a is UnderlineAnnotation && _overlapsWithSelectedLines(a, selectedLines),
          orElse: () => null,
        );

    if (existing != null) {
      // Remove existing underline
      _pdfViewerController.removeAnnotation(existing);
      _pdfViewerController.clearSelection();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تمت إزالة التسطير (Underline) عن النص المحدد'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // Add new underline
      final underline = UnderlineAnnotation(textBoundsCollection: selectedLines);
      underline.name = 'underline';
      underline.subject = selectedLines.map((l) => '${l.bounds.left},${l.bounds.top},${l.bounds.right},${l.bounds.bottom}').join(';');
      underline.color = const Color(0xFF059669); // Emerald Underline
      _pdfViewerController.addAnnotation(underline);
      _pdfViewerController.clearSelection();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم وضع تسطير (Underline) تحت النص المحدد'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Toggles Highlight Annotation on selected text (adds if absent, removes if already present)
  void _toggleHighlightAnnotation() {
    final selectedLines = _pdfViewerKey.currentState?.getSelectedTextLines() ?? [];
    if (selectedLines.isEmpty) {
      _pdfViewerController.clearSelection();
      return;
    }

    final allAnnotations = _pdfViewerController.getAnnotations();
    final existing = allAnnotations.cast<Annotation?>().firstWhere(
          (a) => a is HighlightAnnotation && _overlapsWithSelectedLines(a, selectedLines),
          orElse: () => null,
        );

    if (existing != null) {
      // Remove existing highlight
      _pdfViewerController.removeAnnotation(existing);
      _pdfViewerController.clearSelection();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تمت إزالة التمييز (Highlight) عن النص المحدد'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // Add new highlight
      final highlight = HighlightAnnotation(textBoundsCollection: selectedLines);
      highlight.name = 'highlight';
      highlight.subject = selectedLines.map((l) => '${l.bounds.left},${l.bounds.top},${l.bounds.right},${l.bounds.bottom}').join(';');
      highlight.color = const Color(0xFFFBBF24); // Warm Radiant Amber Highlight
      _pdfViewerController.addAnnotation(highlight);
      _pdfViewerController.clearSelection();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تمييز النص المحدد بنجاح (Highlight)'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Removes the currently selected annotation (when tapped directly)
  void _deleteSelectedAnnotation() {
    if (_selectedAnnotation != null) {
      final toRemove = _selectedAnnotation!;
      _pdfViewerController.removeAnnotation(toRemove);
      setState(() {
        _selectedAnnotation = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف التمييز المحدد بنجاح'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveSearch = _searchResult != null && _searchResult!.hasResult;
    final hasTextSelection = _selectedText != null && _selectedText!.trim().isNotEmpty && _selectionRegion != null;

    // Calculate position for custom text selection toolbar
    double toolbarTop = 0;
    double toolbarLeft = 0;
    if (hasTextSelection) {
      final screenHeight = MediaQuery.of(context).size.height;
      final screenWidth = MediaQuery.of(context).size.width;
      const toolbarHeight = 44.0;
      const toolbarWidth = 280.0;

      // Position above selection if possible, otherwise below
      if (_selectionRegion!.top - toolbarHeight - 12 > MediaQuery.of(context).padding.top + 50) {
        toolbarTop = _selectionRegion!.top - toolbarHeight - 12;
      } else {
        toolbarTop = _selectionRegion!.bottom + 12;
      }

      // Center horizontally relative to selection bounds
      toolbarLeft = _selectionRegion!.center.dx - (toolbarWidth / 2);
      if (toolbarLeft < 10) toolbarLeft = 10;
      if (toolbarLeft + toolbarWidth > screenWidth - 10) {
        toolbarLeft = screenWidth - toolbarWidth - 10;
      }
      if (toolbarTop > screenHeight - 80) {
        toolbarTop = screenHeight - 80;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            // 1. Full Screen & Full Width Edge-to-Edge PDF Viewer
            Positioned.fill(
              child: widget.document.assetPath.isNotEmpty
                  ? SfPdfViewer.asset(
                      widget.document.assetPath,
                      key: _pdfViewerKey,
                      controller: _pdfViewerController,
                      canShowScrollHead: false,
                      canShowScrollStatus: false,
                      enableDoubleTapZooming: true,
                      canShowTextSelectionMenu: false, // We use our superior custom toolbar
                      pageLayoutMode: PdfPageLayoutMode.continuous,
                      onDocumentLoaded: _onDocumentLoaded,
                      onPageChanged: _onPageChanged,
                      onTextSelectionChanged: _onTextSelectionChanged,
                      onAnnotationSelected: _onAnnotationSelected,
                      onAnnotationDeselected: _onAnnotationDeselected,
                    )
                  : const Center(
                      child: Text(
                        'تعذر العثور على ملف الوثيقة',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
            ),

            // Loading Indicator
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: const Color(0xFF0F172A),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFFF59E0B)),
                        SizedBox(height: 16),
                        Text(
                          'جاري فتح صفحات الوثيقة...',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 2. Overlaid Navigation Arrows (Fixed at Left & Right Edges)
            // Right Arrow (RTL: Next Page)
            if (_currentPage < _totalPages)
              Positioned(
                right: 0,
                top: MediaQuery.of(context).size.height / 2 - 40,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _nextPage,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                    child: Container(
                      width: 52,
                      height: 84,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                        ),
                        border: Border.all(color: Colors.white.withOpacity(0.15)),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chevron_right, color: Colors.white, size: 32),
                          Text(
                            'التالي',
                            style: TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Left Arrow (RTL: Previous Page)
            if (_currentPage > 1)
              Positioned(
                left: 0,
                top: MediaQuery.of(context).size.height / 2 - 40,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _prevPage,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    child: Container(
                      width: 52,
                      height: 84,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                        border: Border.all(color: Colors.white.withOpacity(0.15)),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chevron_left, color: Colors.white, size: 32),
                          Text(
                            'السابق',
                            style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // 3. Floating Page Indicator (Top Center)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Text(
                    '$_currentPage / $_totalPages',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),

            // 4. Compact Floating Search Navigation Bar (When search is active and menu is closed)
            if (hasActiveSearch && !_showMenu)
              Positioned(
                top: MediaQuery.of(context).padding.top + 46,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withOpacity(0.92),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search, size: 14, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 6),
                        Text(
                          _searchResult!.isSearchCompleted
                              ? '${_searchResult!.currentInstanceIndex} من ${_searchResult!.totalInstanceCount}'
                              : 'جاري البحث...',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _searchResult?.previousInstance(),
                          borderRadius: BorderRadius.circular(10),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Icon(Icons.keyboard_arrow_up, size: 18, color: Colors.white),
                          ),
                        ),
                        InkWell(
                          onTap: () => _searchResult?.nextInstance(),
                          borderRadius: BorderRadius.circular(10),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: _clearInBookSearch,
                          borderRadius: BorderRadius.circular(10),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Icon(Icons.close, size: 14, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 5. Floating "..." Menu Button (Top Left)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 14,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _showMenu = !_showMenu;
                    });
                  },
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withOpacity(0.85),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: hasActiveSearch ? const Color(0xFFF59E0B) : Colors.white.withOpacity(0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.more_horiz,
                      color: hasActiveSearch ? const Color(0xFFF59E0B) : Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),

            // 6. === Custom Enhanced Text Selection Toolbar (شريط تحديد ونسخ وتمييز النصوص) ===
            if (hasTextSelection)
              Positioned(
                top: toolbarTop,
                left: toolbarLeft,
                child: Material(
                  elevation: 12,
                  borderRadius: BorderRadius.circular(14),
                  color: const Color(0xFF0F172A).withOpacity(0.96),
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.45)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1. Copy Button (نسخ)
                        _buildSelectionActionBtn(
                          icon: Icons.copy,
                          label: 'نسخ',
                          onTap: _copySelectedText,
                        ),
                        _buildDivider(),

                        // 2. Underline Toggle Button (تسطير / نزع التسطير)
                        _buildSelectionActionBtn(
                          icon: Icons.format_underlined,
                          label: 'تسطير',
                          onTap: _toggleUnderlineAnnotation,
                        ),
                        _buildDivider(),

                        // 3. Highlight Toggle Button (تمييز / نزع التمييز)
                        _buildSelectionActionBtn(
                          icon: Icons.border_color,
                          label: 'تمييز',
                          color: const Color(0xFFF59E0B),
                          onTap: _toggleHighlightAnnotation,
                        ),
                        _buildDivider(),

                        // 4. In-Book Search Button (بحث)
                        _buildSelectionActionBtn(
                          icon: Icons.search,
                          label: 'بحث',
                          onTap: _searchSelectedText,
                        ),
                        _buildDivider(),

                        // 5. Share Button (مشاركة)
                        _buildSelectionActionBtn(
                          icon: Icons.share,
                          label: 'مشاركة',
                          onTap: _shareSelectedText,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 7. Selected Annotation Options Pill (When user taps directly on an existing underline/highlight)
            if (_selectedAnnotation != null && !hasTextSelection)
              Positioned(
                top: MediaQuery.of(context).padding.top + 50,
                left: 0,
                right: 0,
                child: Center(
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(20),
                    color: const Color(0xFF0F172A).withOpacity(0.95),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.touch_app, size: 15, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 8),
                          Text(
                            _selectedAnnotation is UnderlineAnnotation
                                ? 'تسطير محدد'
                                : _selectedAnnotation is HighlightAnnotation
                                    ? 'تمييز محدد'
                                    : 'عنصر محدد',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: _deleteSelectedAnnotation,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.redAccent),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.delete_outline, size: 14, color: Colors.redAccent),
                                  SizedBox(width: 4),
                                  Text(
                                    'نزع التمييز',
                                    style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              if (_selectedAnnotation != null) {
                                _pdfViewerController.deselectAnnotation(_selectedAnnotation!);
                              }
                              setState(() {
                                _selectedAnnotation = null;
                              });
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.close, size: 16, color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // 8. Dropdown Menu Modal Card (When user clicks "...")
            if (_showMenu) ...[
              // Backdrop click dismiss
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showMenu = false;
                    });
                  },
                  child: Container(
                    color: Colors.black.withOpacity(0.45),
                  ),
                ),
              ),

              // Menu Card
              Positioned(
                top: MediaQuery.of(context).padding.top + 58,
                left: 14,
                child: Container(
                  width: 310,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withOpacity(0.97),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.6),
                        blurRadius: 25,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header: Document info
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF065F46).withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                                  ),
                                  child: Text(
                                    widget.document.category,
                                    style: const TextStyle(
                                      color: Color(0xFF6EE7B7),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.document.titleAR,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() {
                                _showMenu = false;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // === In-Book Search Field (خانة البحث داخل الكتاب) ===
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: hasActiveSearch ? const Color(0xFFF59E0B) : Colors.white.withOpacity(0.15),
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          textInputAction: TextInputAction.search,
                          onSubmitted: (val) => _performInBookSearch(val),
                          decoration: InputDecoration(
                            hintText: 'ابحث عن فقرة أو عنوان أو نص...',
                            hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                            prefixIcon: const Icon(Icons.search, color: Color(0xFFF59E0B), size: 18),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_searchController.text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.white54, size: 15),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: _clearInBookSearch,
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.arrow_forward_ios, color: Color(0xFF34D399), size: 13),
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _performInBookSearch(_searchController.text),
                                ),
                              ],
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),

                      // In-Menu Search Navigation Bar (if search active)
                      if (hasActiveSearch) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF065F46).withOpacity(0.35),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.find_in_page, color: Color(0xFFF59E0B), size: 15),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _searchResult!.isSearchCompleted
                                      ? 'المطابقة ${_searchResult!.currentInstanceIndex} من ${_searchResult!.totalInstanceCount}'
                                      : 'جاري البحث في الصفحات...',
                                  style: const TextStyle(
                                    color: Color(0xFF6EE7B7),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.keyboard_arrow_up, color: Colors.white, size: 18),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'السابق',
                                onPressed: () => _searchResult?.previousInstance(),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'التالي',
                                onPressed: () => _searchResult?.nextInstance(),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),

                      // Button 1: Download Full PDF
                      ElevatedButton.icon(
                        onPressed: _downloadFullPdf,
                        icon: const Icon(Icons.file_download, color: Color(0xFF0F172A), size: 18),
                        label: const Text(
                          'تنزيل ملف الـ PDF كاملاً',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Button 2: Return to Home Page
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showMenu = false;
                          });
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.home, color: Color(0xFF34D399), size: 18),
                        label: const Text(
                          'الرجوع للصفحة الرئيسية',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white.withOpacity(0.2)),
                          backgroundColor: const Color(0xFF1E293B),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Jump to page input
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'الانتقال لصفحة:',
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: 55,
                              height: 30,
                              child: TextField(
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  hintText: '$_currentPage',
                                  hintStyle: const TextStyle(color: Colors.white38),
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                                  ),
                                ),
                                onSubmitted: (value) {
                                  final num = int.tryParse(value);
                                  if (num != null && num >= 1 && num <= _totalPages) {
                                    _pdfViewerController.jumpToPage(num);
                                    setState(() {
                                      _showMenu = false;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // 9. Search Hits Pills (If user came from search hit in home screen)
            if (widget.searchHits.length > 1)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.find_in_page, color: Color(0xFFF59E0B), size: 16),
                          const SizedBox(width: 6),
                          const Text(
                            'المطابقات: ',
                            style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          ...widget.searchHits.map((p) {
                            final isCurrent = p == _currentPage;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: InkWell(
                                onTap: () => _pdfViewerController.jumpToPage(p),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isCurrent ? const Color(0xFFF59E0B) : Colors.white.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'ص $p',
                                    style: TextStyle(
                                      color: isCurrent ? const Color(0xFF0F172A) : Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionActionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final effectiveColor = color ?? Colors.white;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: effectiveColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: effectiveColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 18,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: Colors.white.withOpacity(0.15),
    );
  }
}
