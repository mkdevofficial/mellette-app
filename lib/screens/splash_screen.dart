import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/search_service.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _animController.forward();
    _initializeAndNavigate();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _initializeAndNavigate() async {
    final startTime = DateTime.now();

    // Initialize search service in background
    try {
      await SearchService().init();
    } catch (_) {}

    // Ensure splash is visible for at least 1.5 seconds for pleasant UX
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    if (elapsed < 1500) {
      await Future.delayed(Duration(milliseconds: 1500 - elapsed));
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF064E3B), // Deep Mauritanian Emerald Green
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Stack(
              children: [
                // Center Branding & Logo
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Icon / Emblem
                      Container(
                        width: 130,
                        height: 130,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withOpacity(0.2),
                              blurRadius: 30,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(65),
                          child: Image.asset(
                            'assets/icon/app_icon_512.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.balance,
                                size: 80,
                                color: Color(0xFFF59E0B),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // App Name
                      const Text(
                        'الحقيبة القضائية الموريتانية',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // App Subtitle
                      Text(
                        'محرك البحث ومتصفح القوانين والمراسيم',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFFA7F3D0).withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Subtle Progress Bar
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                        ),
                      ),
                    ],
                  ),
                ),

                // Author Attribution Badge at Bottom
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 24,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFF59E0B).withOpacity(0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.code,
                              size: 15,
                              color: Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'مصنوع بواسطة mokhtar eby',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.95),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                fontFamily: GoogleFonts.cairo().fontFamily,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'الإصدار 1.0.0',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
