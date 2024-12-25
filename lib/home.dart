import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:perpustakaan/services/user_preferences.dart';
import 'package:perpustakaan/services/database_service.dart';
import 'package:perpustakaan/services/borrowed_books_service.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:perpustakaan/pages/history.dart';
import 'package:perpustakaan/pages/search.dart';
import 'package:perpustakaan/pages/card.dart';
import 'package:perpustakaan/pages/profile.dart';
import 'package:perpustakaan/pages/notification.dart';
import 'package:perpustakaan/services/notification_service.dart';
import 'package:animate_do/animate_do.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  String userName = '';
  String userEmail = '';
  bool isLoading = true;
  int _page = 0;
  int _borrowedBooksCount = 2;
  StreamSubscription<int>? _borrowedBooksSubscription;

  List<Map<String, String>> bookData = [
    {
      "gambar": 'assets/images/test-book.jpg',
      "judul": 'Aku Yang Sudah Lama Hilang',
      "author": 'Nago Toejene',
      "deskripsi":
          '“Diramu untuk memahami dirimu, ditulis untuk mengembalikan jiwa yang lama kamu abaikan.”'
    },
    {
      "gambar": 'assets/images/test-book2.jpg',
      "judul": 'Seorang Pria yang Melalui Duka dengan Mencuci Piring',
      "author": 'dr. Andreas Kurniawan, Sp.KJ',
      "deskripsi":
          'Buku ini akan membantu menuntun kita di proses penerimaan dan perubahan agar arahnya t.....'
    },
    {
      "gambar": 'assets/images/test-book3.jpg',
      "judul": 'Yellowface',
      "author": 'R. F. Kuang',
      "deskripsi":
          'une Hayward dan Athena Liu sama-sama penulis. Athena, keturunan Asia, ternyat....'
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _subscribeToBorrowedBooks();
  }

  @override
  void dispose() {
    _borrowedBooksSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToBorrowedBooks() {
    _borrowedBooksSubscription =
        BorrowedBooksService.borrowedBooksCountStream.listen((count) {
      setState(() {
        _borrowedBooksCount = count;
      });
    });
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await UserPreferences.getUser();
      if (userData != null) {
        // Verifikasi dan update data dari database
        final updatedUser = await DatabaseService.getUserByNik(userData.nik);

        if (updatedUser != null) {
          // Update SharedPreferences dengan data terbaru
          await UserPreferences.saveUser(updatedUser);

          setState(() {
            userName = updatedUser.name;
            userEmail = updatedUser.email;
            isLoading = false;
          });
        } else {
          // User tidak ditemukan di database, logout
          await UserPreferences.clearUser();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Sesi anda telah berakhir. Silakan login kembali.'),
                backgroundColor: Colors.red,
              ),
            );
            Navigator.pushReplacementNamed(context, '/login');
          }
        }
      } else {
        // If no user data is found, redirect to login
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading user data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: CurvedNavigationBar(
        animationCurve: Curves.easeIn,
        backgroundColor: Colors.white,
        color: const Color(0xFF0A2647),
        animationDuration: const Duration(milliseconds: 300),
        onTap: (index) {
          setState(() {
            _page = index;
          });
        },
        items: [
          FadeIn(
            duration: const Duration(milliseconds: 400),
            child: Icon(
              Icons.home,
              color: Colors.white,
              size: 30,
            ),
          ),
          FadeIn(
            duration: const Duration(milliseconds: 500),
            child: Icon(
              Icons.history,
              color: Colors.white,
              size: 30,
            ),
          ),
          FadeIn(
            duration: const Duration(milliseconds: 600),
            child: SvgPicture.asset(
              'assets/icons/svg/search.svg',
              colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
              width: 30,
              height: 30,
            ),
          ),
          FadeIn(
            duration: const Duration(milliseconds: 700),
            child: SvgPicture.asset(
              'assets/icons/svg/card.svg',
              colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
              width: 30,
              height: 30,
            ),
          ),
          FadeIn(
            duration: const Duration(milliseconds: 800),
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildPage(),
    );
  }

  Widget _buildPage() {
    switch (_page) {
      case 0:
        return _buildHomePage();
      case 1:
        return const HistoryPage();
      case 2:
        return const SearchPage();
      case 3:
        return const CardPage();
      case 4:
        return const ProfilePage();
      default:
        return _buildHomePage();
    }
  }

  Widget _buildHomePage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive values
        final screenWidth = constraints.maxWidth;
        final horizontalPadding = screenWidth * 0.04; // 4% of screen width
        final isSmallScreen = screenWidth < 360;

        return RefreshIndicator(
          onRefresh: () async {
            await _loadUserData();
            setState(() {});
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Container(
              padding: EdgeInsets.only(
                left: horizontalPadding,
                right: horizontalPadding,
                top: MediaQuery.of(context).padding.top > 0
                    ? MediaQuery.of(context).padding.top + horizontalPadding
                    : horizontalPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile and Notification Row
                  FadeInDown(
                    duration: const Duration(milliseconds: 600),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              SizedBox(
                                height: screenWidth * 0.12,
                                width: screenWidth * 0.12,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    'https://ui-avatars.com/api/?name=$userName&background=random&color=white',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              SizedBox(width: horizontalPadding * 0.5),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    FadeIn(
                                      duration:
                                          const Duration(milliseconds: 400),
                                      child: Text(
                                        'Hi, $userName',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 16 : 18,
                                          fontWeight: FontWeight.w900,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    FadeIn(
                                      duration:
                                          const Duration(milliseconds: 600),
                                      child: Text(
                                        userEmail,
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 10 : 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: screenWidth * 0.12,
                          height: screenWidth * 0.12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A2647),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: Icon(
                                    Icons.notifications_outlined,
                                    color: Colors.white,
                                    size: screenWidth * 0.08,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const NotificationPage(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              AnimatedBuilder(
                                animation: NotificationService(),
                                builder: (context, child) {
                                  final unreadCount =
                                      NotificationService().unreadCount;
                                  if (unreadCount == 0) {
                                    return const SizedBox.shrink();
                                  }

                                  return Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        unreadCount.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: horizontalPadding),

                  // Favorite Books Section
                  FadeInLeft(
                    duration: const Duration(milliseconds: 600),
                    child: Text(
                      'Buku Tervaforit',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 18 : 20,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0A2647),
                      ),
                    ),
                  ),
                  SizedBox(height: horizontalPadding),

                  // Book Swiper
                  FadeInUp(
                    duration: const Duration(milliseconds: 800),
                    child: SizedBox(
                      height: screenWidth * 0.5,
                      child: Swiper(
                        itemBuilder: (BuildContext context, int index) {
                          final book = bookData[index];
                          return Container(
                            padding: EdgeInsets.all(horizontalPadding),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A2647),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(
                                    book['gambar']!,
                                    height: screenWidth * 0.45,
                                    width: screenWidth * 0.28,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                SizedBox(width: horizontalPadding),
                                Expanded(
                                  child: FadeIn(
                                    duration: const Duration(milliseconds: 600),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          book['judul']!,
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 14 : 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(
                                            height: horizontalPadding * 0.3),
                                        Text(
                                          'Author: ${book['author']!}',
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 10 : 12,
                                            color: Colors.white70,
                                          ),
                                        ),
                                        SizedBox(
                                            height: horizontalPadding * 0.5),
                                        Text(
                                          book['deskripsi']!,
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 9 : 11,
                                            color: Colors.white60,
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        itemCount: bookData.length,
                        viewportFraction: 1,
                        scale: 0.9,
                        pagination: const SwiperPagination(),
                        autoplay: true,
                      ),
                    ),
                  ),
                  SizedBox(height: horizontalPadding),

                  // Statistics Row
                  FadeInUp(
                    duration: const Duration(milliseconds: 900),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: SlideInLeft(
                            duration: const Duration(milliseconds: 600),
                            child: Container(
                              padding: EdgeInsets.all(horizontalPadding),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A2647),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  BounceInDown(
                                    duration: const Duration(milliseconds: 800),
                                    child: Image.asset(
                                      'assets/icons/Book.png',
                                      height: screenWidth * 0.12,
                                      width: screenWidth * 0.12,
                                    ),
                                  ),
                                  SizedBox(width: horizontalPadding * 0.5),
                                  Expanded(
                                    child: FadeIn(
                                      duration:
                                          const Duration(milliseconds: 400),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$_borrowedBooksCount',
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 16 : 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            'Buku Dipinjam',
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 12 : 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: horizontalPadding * 0.5),
                        Expanded(
                          child: SlideInRight(
                            duration: const Duration(milliseconds: 600),
                            child: Container(
                              padding: EdgeInsets.all(horizontalPadding),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A2647),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  BounceInDown(
                                    duration: const Duration(milliseconds: 800),
                                    child: Image.asset(
                                      'assets/icons/Error.png',
                                      height: screenWidth * 0.12,
                                      width: screenWidth * 0.12,
                                    ),
                                  ),
                                  SizedBox(width: horizontalPadding * 0.5),
                                  Expanded(
                                    child: FadeIn(
                                      duration:
                                          const Duration(milliseconds: 400),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '0',
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 16 : 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            'Pelanggaran',
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 12 : 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: horizontalPadding),
                  // Library Visits Container
                  FadeInUp(
                    duration: const Duration(milliseconds: 800),
                    child: SlideInLeft(
                      duration: const Duration(milliseconds: 600),
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        padding: EdgeInsets.all(horizontalPadding),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A2647),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            BounceInLeft(
                              duration: const Duration(milliseconds: 800),
                              child: Image.asset(
                                'assets/icons/Library.png',
                                height: screenWidth * 0.12,
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: horizontalPadding),
                                child: FadeIn(
                                  duration: const Duration(milliseconds: 600),
                                  child: Text(
                                    'Kunjungan Ke Perpustakaan:',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 16 : 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            FadeInRight(
                              duration: const Duration(milliseconds: 700),
                              child: Text(
                                '0',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 18 : 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: horizontalPadding),

                  // Photocopy Services Container
                  FadeInUp(
                    duration: const Duration(milliseconds: 900),
                    child: SlideInRight(
                      duration: const Duration(milliseconds: 600),
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        padding: EdgeInsets.all(horizontalPadding),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A2647),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            BounceInLeft(
                              duration: const Duration(milliseconds: 800),
                              child: Image.asset(
                                'assets/icons/Fotocopy.png',
                                height: screenWidth * 0.12,
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: horizontalPadding),
                                child: FadeIn(
                                  duration: const Duration(milliseconds: 600),
                                  child: Text(
                                    'Layanan Fotocopy:',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 16 : 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            FadeInRight(
                              duration: const Duration(milliseconds: 700),
                              child: Text(
                                '0',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 18 : 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: horizontalPadding),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
