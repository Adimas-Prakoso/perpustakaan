import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:perpustakaan/services/user_preferences.dart';
import 'package:perpustakaan/models/user_level.dart';
import 'package:perpustakaan/pages/notification.dart';
import 'package:perpustakaan/pages/settings/edit_profile.dart';
import 'package:perpustakaan/pages/settings/privacy.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  String userName = '';
  String userEmail = '';
  String userNik = '';
  bool isLoading = true;
  int userPoints = 0;
  bool isEditing = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _loadUserData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await UserPreferences.getUser();
      if (userData != null) {
        setState(() {
          userName = userData.name;
          userEmail = userData.email;
          userNik = userData.nik;
          userPoints = 3000;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memuat data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPointsHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Riwayat Poin'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildPointHistoryItem(
                'Membaca Buku',
                '+50',
                '2 jam yang lalu',
                Icons.book,
              ),
              _buildPointHistoryItem(
                'Menulis Review',
                '+30',
                'Kemarin',
                Icons.rate_review,
              ),
              _buildPointHistoryItem(
                'Login Harian',
                '+10',
                'Kemarin',
                Icons.login,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildPointHistoryItem(
      String title, String points, String time, IconData icon) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color(0xFF0A2647).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Color(0xFF0A2647)),
      ),
      title: Text(title),
      subtitle: Text(time),
      trailing: Text(
        points,
        style: TextStyle(
          color: points.startsWith('+') ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: FadeInUp(
          duration: const Duration(milliseconds: 300),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pengaturan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A2647),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSettingsItem(
                  icon: Icons.person_outline,
                  title: 'Edit Profil',
                  subtitle: 'Perbarui informasi pribadi Anda',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfilePage(),
                      ),
                    );
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifikasi',
                  subtitle: 'Atur preferensi notifikasi',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationPage(),
                      ),
                    );
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.security_outlined,
                  title: 'Keamanan',
                  subtitle: 'Pengaturan privasi dan keamanan',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacyPage(),
                      ),
                    );
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.help_outline,
                  title: 'Bantuan',
                  subtitle: 'Pusat bantuan dan FAQ',
                  onTap: () async {
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 10),
                Divider(),
                const SizedBox(height: 10),
                _buildSettingsItem(
                  icon: Icons.logout,
                  title: 'Keluar',
                  subtitle: 'Keluar dari akun Anda',
                  onTap: () {
                    Navigator.pop(context);
                    _logout();
                  },
                  isDestructive: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withOpacity(0.1)
              : Color(0xFF0A2647).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red : Color(0xFF0A2647),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDestructive ? Colors.red.withOpacity(0.5) : Colors.grey[400],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await UserPreferences.clearUser();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saat logout: ${e.toString()}'),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadUserData,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // Header with gradient
                      FadeInDown(
                        duration: const Duration(milliseconds: 500),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF0A2647),
                                Color.fromRGBO(10, 38, 71, 0.9),
                                Color.fromRGBO(10, 38, 71, 0.8),
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(40),
                              bottomRight: Radius.circular(40),
                            ),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Profil',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.history,
                                            color: Colors.white,
                                          ),
                                          onPressed: _showPointsHistoryDialog,
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.settings_outlined,
                                            color: Colors.white,
                                          ),
                                          onPressed: _showSettingsDialog,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              GestureDetector(
                                onTapDown: (_) => _controller.forward(),
                                onTapUp: (_) => _controller.reverse(),
                                onTapCancel: () => _controller.reverse(),
                                child: ScaleTransition(
                                  scale: _scaleAnimation,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 110,
                                        height: 110,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Hero(
                                        tag: 'profile-picture',
                                        child: FutureBuilder(
                                          future: precacheImage(
                                            NetworkImage(
                                              'https://ui-avatars.com/api/?name=${Uri.encodeComponent(userName)}&background=random&color=fff&size=200&bold=true&format=png',
                                            ),
                                            context,
                                          ),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.done) {
                                              return Container(
                                                width: 100,
                                                height: 100,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  image: DecorationImage(
                                                    image: NetworkImage(
                                                      'https://ui-avatars.com/api/?name=${Uri.encodeComponent(userName)}&background=random&color=fff&size=200&bold=true&format=png',
                                                    ),
                                                    fit: BoxFit.cover,
                                                  ),
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 2,
                                                  ),
                                                ),
                                              );
                                            } else {
                                              return CircularProgressIndicator();
                                            }
                                          },
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.1),
                                                spreadRadius: 1,
                                                blurRadius: 1,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            Icons.edit,
                                            size: 20,
                                            color: Color(0xFF0A2647),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              Text(
                                userName,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                userEmail,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              const SizedBox(height: 25),
                              // Level Info Card
                              Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 10,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          UserLevel.getLevelInfo(
                                                  UserLevel.calculateLevel(
                                                      userPoints))!['icon']
                                              .toString(),
                                          style: const TextStyle(fontSize: 28),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          UserLevel.getLevelInfo(
                                                  UserLevel.calculateLevel(
                                                      userPoints))!['name']
                                              .toString(),
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0A2647),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 15),
                                    Text(
                                      UserLevel.getLevelInfo(
                                              UserLevel.calculateLevel(
                                                  userPoints))!['description']
                                          .toString(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 20),
                                    Container(
                                      padding: const EdgeInsets.all(15),
                                      decoration: BoxDecoration(
                                        color:
                                            Color(0xFF0A2647).withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Column(
                                        children: [
                                          GestureDetector(
                                            onTap: _showPointsHistoryDialog,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.stars_rounded,
                                                  color: Color(0xFF0A2647),
                                                  size: 24,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  '$userPoints Poin',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF0A2647),
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.info_outline,
                                                  color: Color(0xFF0A2647)
                                                      .withOpacity(0.5),
                                                  size: 16,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: LinearProgressIndicator(
                                              value:
                                                  UserLevel.calculateProgress(
                                                      userPoints),
                                              backgroundColor:
                                                  Colors.grey.withOpacity(0.2),
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                Color(UserLevel.getLevelInfo(
                                                        UserLevel
                                                            .calculateLevel(
                                                                userPoints))![
                                                    'color'] as int),
                                              ),
                                              minHeight: 8,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            UserLevel.getNextLevelRequirement(
                                                userPoints,
                                                UserLevel.calculateLevel(
                                                    userPoints)),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 25),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Benefit Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Benefit Level Saat Ini',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0A2647),
                              ),
                            ),
                            const SizedBox(height: 15),
                            ...UserLevel.getLevelRewards(
                                    UserLevel.calculateLevel(userPoints))
                                .map(
                              (reward) => FadeInRight(
                                duration: const Duration(milliseconds: 500),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        spreadRadius: 1,
                                        blurRadius: 10,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Color(0xFF0A2647)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          Icons.card_giftcard,
                                          color: Color(0xFF0A2647),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: Text(
                                          reward,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
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
