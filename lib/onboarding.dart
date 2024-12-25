import 'package:flutter/material.dart';
import 'package:perpustakaan/register.dart';
import 'package:perpustakaan/login.dart';
import 'package:lottie/lottie.dart';

class OnBoarding extends StatefulWidget {
  const OnBoarding({super.key});

  @override
  State<OnBoarding> createState() => _OnBoardingState();
}

class _OnBoardingState extends State<OnBoarding> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  final List<Map<String, String>> _pages = [
    {
      'title': 'Sistem Katalog\nPerpustakaan Digital',
      'description':
          'Akses katalog perpustakaan digital dengan sistem pencarian buku yang komprehensif untuk mendukung kebutuhan akademik Anda.',
      'lottie': 'assets/lottie/library.json',
    },
    {
      'title': 'Koleksi Buku Digital',
      'description':
          'Temukan ribuan koleksi buku digital dari berbagai kategori dan bidang ilmu yang dapat diakses kapan saja.',
      'lottie': 'assets/lottie/ebook.json',
    },
    {
      'title': 'Pencarian Mudah',
      'description':
          'Cari buku dengan mudah menggunakan fitur pencarian canggih berdasarkan judul, penulis, atau kategori.',
      'lottie': 'assets/lottie/search.json',
    },
    {
      'title': 'Bookmark & Catatan',
      'description':
          'Simpan buku favorit dan buat catatan pribadi untuk memudahkan pembelajaran Anda.',
      'lottie': 'assets/lottie/bookmark.json',
    },
    {
      'title': 'Mulai Sekarang',
      'description':
          'Daftar atau masuk untuk mulai menjelajahi perpustakaan digital kami.',
      'lottie': 'assets/lottie/welcome.json',
    },
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenHeight = screenSize.height;
    final double screenWidth = screenSize.width;

    // Calculate responsive dimensions
    final double horizontalPadding = screenWidth * 0.08;
    final double verticalPadding = screenHeight * 0.05;
    final double titleFontSize = screenWidth * 0.06;
    final double descriptionFontSize = screenWidth * 0.04;
    final double buttonHeight = screenHeight * 0.06;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                  _isLoading = true;
                });
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                });
              },
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                // Only build the current page's content
                if (index != _currentPage) {
                  return const SizedBox.shrink();
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: verticalPadding,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Lottie Animation Container
                            SizedBox(
                              height: screenHeight *
                                  0.5, // Increased height for Lottie
                              child: _isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : Lottie.asset(
                                      _pages[_currentPage]['lottie']!,
                                      fit: BoxFit.contain,
                                      repeat: true,
                                    ),
                            ),
                            // Text Container - Positioned closer to page indicator
                            Container(
                              margin:
                                  EdgeInsets.only(bottom: screenHeight * 0.18),
                              child: Column(
                                children: [
                                  Text(
                                    _pages[index]['title']!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: titleFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF053149),
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.02),
                                  Text(
                                    _pages[index]['description']!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: descriptionFontSize,
                                      color: Colors.grey,
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
              },
            ),
            // Page Indicator
            Positioned(
              bottom: screenHeight * 0.15,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.01,
                    ),
                    width: _currentPage == index
                        ? screenWidth * 0.07
                        : screenWidth * 0.02,
                    height: screenHeight * 0.01,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? const Color(0xFF053149)
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(screenWidth * 0.01),
                    ),
                  ),
                ),
              ),
            ),
            // Next Button
            if (_currentPage < _pages.length - 1)
              Positioned(
                bottom: screenHeight * 0.05,
                left: horizontalPadding,
                right: horizontalPadding,
                child: SizedBox(
                  height: buttonHeight,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF053149),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      ),
                    ),
                    child: Text(
                      'Next',
                      style: TextStyle(
                        fontSize: descriptionFontSize,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            // Login and Register Buttons
            if (_currentPage == _pages.length - 1)
              Positioned(
                bottom: screenHeight * 0.03,
                left: horizontalPadding,
                right: horizontalPadding,
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: buttonHeight,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF053149),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(screenWidth * 0.02),
                            ),
                          ),
                          child: Text(
                            'Login',
                            style: TextStyle(
                              fontSize: descriptionFontSize,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.04),
                    Expanded(
                      child: SizedBox(
                        height: buttonHeight,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(screenWidth * 0.02),
                              side: const BorderSide(color: Color(0xFF053149)),
                            ),
                          ),
                          child: Text(
                            'Register',
                            style: TextStyle(
                              fontSize: descriptionFontSize,
                              color: const Color(0xFF053149),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Skip Button - Only show when not on last page
            if (_currentPage < _pages.length - 1)
              Positioned(
                top: screenHeight * 0.02,
                right: horizontalPadding,
                child: TextButton(
                  onPressed: () {
                    _pageController.animateToPage(
                      _pages.length - 1,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: const Color(0xFF053149),
                      fontSize: descriptionFontSize,
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
