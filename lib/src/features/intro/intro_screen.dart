import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Widgets
import 'package:students_reminder/src/widgets/animated_intro_slide.dart';
import 'package:students_reminder/src/widgets/animated_page_indicator.dart';

// ✅ Route names
import 'package:students_reminder/src/shared/routes.dart';

// ✅ Session manager to remember intro seen
import 'package:students_reminder/src/services/session_manager.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController();
  int currentIndex = 0;
  double pageOffset = 0.0;
  bool swipeEnabled = true;

  // 👋 Slides for intro
  final List<Map<String, String>> _slides = [
    {
      'image': 'assets/images/intro1.png',
      'title': 'Welcome to Student Reminder',
      'description': 'Stay accountable with GPS-based attendance',
    },
    {
      'image': 'assets/images/intro3.png',
      'title': 'Clock in, Clock out',
      'description': 'Location, time, and notes synced to school',
    },
    {
      'image': 'assets/images/intro2.png',
      'title': 'You’re ready!',
      'description': 'Let’s track your success, every day.',
    },
  ];

  // 🎨 Background color transitions
  final List<Color> _backgroundColors = [
    Colors.blue.shade900,
    Colors.deepPurple.shade800,
    Colors.teal.shade800,
  ];

  /// ✅ When user presses "Get Started"
  Future<void> _handleGetStarted() async {
    // Save that intro has been seen so we skip it next time
    await SessionManager.setIntroSeen();
    if (!mounted) return;

    // Move to login screen
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        pageOffset = _pageController.page ?? 0.0;
      });
    });
  }

  // 🔥 Interpolates between background colors as user swipes
  Color _getBackgroundColor(double offset) {
    final lowerIndex = offset.floor();
    final upperIndex = (lowerIndex + 1).clamp(0, _backgroundColors.length - 1);
    final t = offset - lowerIndex;
    return Color.lerp(
      _backgroundColors[lowerIndex],
      _backgroundColors[upperIndex],
      t,
    )!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getBackgroundColor(pageOffset),
      body: Column(
        children: [
          // 📊 Top progress indicator
          Padding(
            padding: const EdgeInsets.only(top: 48, left: 16, right: 16),
            child: LinearProgressIndicator(
              value: (currentIndex + 1) / _slides.length,
              backgroundColor: Colors.white30,
              color: Colors.greenAccent[400],
              minHeight: 4,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // 🖼️ Slides
          Expanded(
            child: AbsorbPointer(
              absorbing: !swipeEnabled,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() {
                    currentIndex = index;
                    swipeEnabled = false;
                  });
                  // Avoid too fast swipe
                  Future.delayed(const Duration(milliseconds: 800), () {
                    if (mounted) setState(() => swipeEnabled = true);
                  });
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  final parallax = (pageOffset - index);
                  return AnimatedIntroSlide(
                    imagePath: slide['image']!,
                    title: slide['title']!,
                    description: slide['description']!,
                    isCurrent: index == currentIndex,
                    isLast: index == _slides.length - 1,
                    onGetStarted: _handleGetStarted, // ✅ goes to login
                    parallaxOffset: parallax,
                    titleStyle: GoogleFonts.poppins(
                      fontSize: 26,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    descriptionStyle: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 🔘 Animated dots
          AnimatedPageIndicator(
            count: _slides.length,
            currentIndex: currentIndex,
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
