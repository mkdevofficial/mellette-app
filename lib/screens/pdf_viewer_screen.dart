import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/document.dart';
import '../services/download_helper.dart';

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
  late PdfViewerController _pdfViewerController;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoading = true;
  bool _isDownloading = false;
  bool _showMenu = false;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pdfViewerController = PdfViewerController();
  }

  @override
  void dispose() {
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
      _pdfViewerController.searchText(widget.searchQuery);
    }
  }

  void _onPageChanged(PdfPageChangedDetails details) {
    setState(() {
      _currentPage = details.newPageNumber;
    });
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

  Future<void> _downloadFullPdf() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final byteData = await rootBundle.load(widget.document.assetPath);
      final bytes = byteData.buffer.asUint8List();
      final fileName = widget.document.fileName.isNotEmpty
          ? widget.document.fileName
          : '${widget.document.category}_${widget.document.id}.pdf';

      await downloadPdfFile(bytes, fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(child: Text('تم تنزيل ملف الـ PDF: $fileName')),
              ],
            ),
            backgroundColor: const Color(0xFF065F46),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر تنزيل الملف: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      controller: _pdfViewerController,
                      canShowScrollHead: false,
                      canShowScrollStatus: false,
                      enableDoubleTapZooming: true,
                      pageLayoutMode: PdfPageLayoutMode.continuous,
                      onDocumentLoaded: _onDocumentLoaded,
                      onPageChanged: _onPageChanged,
                      onTextSelectionChanged: (details) {},
                    )
                  : const Center(
                      child: Text(
                        'ملف الـ PDF غير متوفر محلياً',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
            ),

            // Loading indicator
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: const Color(0xFF0F172A).withOpacity(0.85),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF10B981)),
                        SizedBox(height: 16),
                        Text(
                          'جارٍ تحميل الوثيقة بصيغة PDF...',
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

            // 3. Subtle Floating Page Indicator (Top Center)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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

            // 4. Floating "..." Menu Button (Top Left)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
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
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withOpacity(0.85),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.more_horiz,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ),

            // 5. Dropdown Menu Modal Card (When user clicks "...")
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
                top: MediaQuery.of(context).padding.top + 64,
                left: 14,
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withOpacity(0.96),
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
                      const SizedBox(height: 16),

                      // Button 1: Download Full PDF
                      ElevatedButton.icon(
                        onPressed: _isDownloading
                            ? null
                            : () {
                                setState(() {
                                  _showMenu = false;
                                });
                                _downloadFullPdf();
                              },
                        icon: _isDownloading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                              )
                            : const Icon(Icons.file_download, color: Color(0xFF0F172A)),
                        label: const Text(
                          'تنزيل ملف الـ PDF كاملاً',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Button 2: Return to Home Page
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showMenu = false;
                          });
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.home, color: Color(0xFF34D399)),
                        label: const Text(
                          'الرجوع للصفحة الرئيسية',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white.withOpacity(0.2)),
                          backgroundColor: const Color(0xFF1E293B),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

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
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: 60,
                              height: 32,
                              child: TextField(
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
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

            // 6. Search Hits Pills (If user came from search hit)
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
}
