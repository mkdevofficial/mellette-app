import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class GitHubIcon extends StatelessWidget {
  final double size;
  final Color color;

  const GitHubIcon({
    super.key,
    this.size = 24.0,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GitHubLogoPainter(color),
    );
  }
}

class _GitHubLogoPainter extends CustomPainter {
  final Color color;
  _GitHubLogoPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final scale = size.width / 16.0;
    canvas.save();
    canvas.scale(scale, scale);

    // Standard GitHub Octocat SVG Path (16x16 viewport)
    final path = Path();
    path.moveTo(8, 0);
    path.cubicTo(3.58, 0, 0, 3.58, 0, 8);
    path.cubicTo(0, 11.54, 2.29, 14.53, 5.47, 15.59);
    path.cubicTo(5.87, 15.66, 6.02, 15.42, 6.02, 15.21);
    path.cubicTo(6.02, 15.02, 6.01, 14.39, 6.01, 13.72);
    path.cubicTo(4.0, 14.09, 3.48, 13.23, 3.32, 12.78);
    path.cubicTo(3.23, 12.55, 2.84, 11.84, 2.5, 11.65);
    path.cubicTo(2.22, 11.5, 1.82, 11.13, 2.49, 11.12);
    path.cubicTo(3.12, 11.11, 3.57, 11.7, 3.72, 11.94);
    path.cubicTo(4.44, 13.15, 5.59, 12.81, 6.05, 12.6);
    path.cubicTo(6.12, 12.08, 6.33, 11.73, 6.56, 11.53);
    path.cubicTo(4.78, 11.33, 2.92, 10.64, 2.92, 7.58);
    path.cubicTo(2.92, 6.71, 3.23, 5.99, 3.74, 5.43);
    path.cubicTo(3.66, 5.23, 3.38, 4.41, 3.82, 3.31);
    path.cubicTo(3.82, 3.31, 4.49, 3.1, 6.02, 4.13);
    path.cubicTo(6.66, 3.95, 7.34, 3.86, 8.02, 3.86);
    path.cubicTo(8.7, 3.86, 9.38, 3.95, 10.02, 4.13);
    path.cubicTo(11.55, 3.09, 12.22, 3.31, 12.22, 3.31);
    path.cubicTo(12.66, 4.41, 12.38, 5.23, 12.3, 5.43);
    path.cubicTo(12.81, 5.99, 13.12, 6.7, 13.12, 7.58);
    path.cubicTo(13.12, 10.65, 11.25, 11.33, 9.47, 11.53);
    path.cubicTo(9.76, 11.78, 10.01, 12.26, 10.01, 13.01);
    path.cubicTo(10.01, 14.08, 10.0, 14.94, 10.0, 15.21);
    path.cubicTo(10.0, 15.42, 10.15, 15.67, 10.55, 15.59);
    path.cubicTo(13.73, 14.53, 16.02, 11.53, 16.02, 8.0);
    path.cubicTo(16.02, 3.58, 12.44, 0, 8.0, 0);
    path.close();

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GitHubLogoPainter oldDelegate) => oldDelegate.color != color;
}

Future<void> openUrl(BuildContext context, String url) async {
  try {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر فتح الرابط: $url'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ أثناء فتح الرابط: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}

void showGitHubReposDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: Colors.white,
        elevation: 6,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 390),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with GitHub Icon
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const GitHubIcon(size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مستودعات المشروع على GitHub',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'كود المصدر وتفاصيل المشروع',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              const Text(
                'اختر المشروع الذي ترغب في تصفح مستودعه:',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF334155),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),

              // Option 1: Mallette (Next.js)
              _buildRepoOption(
                context: dialogContext,
                title: 'Mallette (Next.js)',
                badge: 'موقع ويب',
                badgeColor: const Color(0xFF0284C7),
                description: 'موقع الويب لنفس الفكرة مبني بـ Next.js و PDF.js',
                url: 'https://github.com/mkdevofficial/Mallette',
                icon: Icons.language,
              ),

              const SizedBox(height: 8),

              // Option 2: mallette-app (Flutter)
              _buildRepoOption(
                context: dialogContext,
                title: 'mallette-app (Flutter)',
                badge: 'تطبيق هاتف وويب',
                badgeColor: const Color(0xFF059669),
                description: 'هذا التطبيق الذي نعمل عليه مبني بالكامل بـ Flutter',
                url: 'https://github.com/mkdevofficial/mellette-app',
                icon: Icons.phone_android,
              ),

              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 10),

              // Author attribution
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified, color: Color(0xFF059669), size: 13),
                    SizedBox(width: 6),
                    Text(
                      'مصنوع بواسطة mokhtar eby',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildRepoOption({
  required BuildContext context,
  required String title,
  required String badge,
  required Color badgeColor,
  required String description,
  required String url,
  required IconData icon,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () {
        openUrl(context, url);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: badgeColor, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 9,
                            color: badgeColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.open_in_new,
              color: Color(0xFF94A3B8),
              size: 15,
            ),
          ],
        ),
      ),
    ),
  );
}
