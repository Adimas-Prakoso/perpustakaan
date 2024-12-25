class UserLevel {
  static const Map<int, Map<String, dynamic>> levels = {
    0: {
      'name': 'Pembaca Pemula',
      'description': 'Mulai perjalanan membaca Anda',
      'minPoints': 0,
      'maxPoints': 99,
      'pointsToNext': 100,
      'icon': '📚',
      'color': 0xFFBBDEFB, // Light Blue
      'benefits': [
        "Waktu Peminjaman Minimal 3 hari",
        "Hanya Dapat Meminjam 1 buku"
      ]
    },
    1: {
      'name': 'Pembaca Antusias',
      'description': 'Terus tingkatkan semangat membaca',
      'minPoints': 100,
      'maxPoints': 299,
      'pointsToNext': 300,
      'icon': '📖',
      'color': 0xFF90CAF9, // Light Blue variant
      'benefits': [
        'Waktu peminjaman 7 hari',
        'Dapat meminjam 2 buku',
        'Akses Layanan Fotocopy'
      ]
    },
    2: {
      'name': 'Pembaca Berdedikasi',
      'description': 'Rajin membaca dan mengeksplorasi berbagai genre',
      'minPoints': 300,
      'maxPoints': 799,
      'pointsToNext': 800,
      'icon': '🎯',
      'color': 0xFF64B5F6, // Blue variant
      'benefits': [
        'Waktu peminjaman 14 hari',
        'Dapat meminjam 3 buku',
        'Akses Layanan Fotocopy',
        'Akses Internet Gratis Saat Di Perpustakaan'
      ]
    },
    3: {
      'name': 'Cendekiawan Muda',
      'description': 'Pembaca aktif dengan wawasan luas',
      'minPoints': 800,
      'maxPoints': 1499,
      'pointsToNext': 1500,
      'icon': '🎓',
      'color': 0xFF42A5F5, // Blue variant
      'benefits': [
        'Waktu peminjaman 21 hari',
        'Dapat meminjam 4 buku',
        'Akses Layanan Fotocopy',
        'Akses Internet Gratis Saat Di Perpustakaan',
        'Gratis Parkir Di Perpustakaan'
      ]
    },
    4: {
      'name': 'Sarjana Literasi',
      'description': 'Pencapaian luar biasa dalam membaca',
      'minPoints': 1500,
      'maxPoints': 2999,
      'pointsToNext': 3000,
      'icon': '🏆',
      'color': 0xFF2196F3, // Blue
      'benefits': [
        'Waktu peminjaman 30 hari',
        'Dapat meminjam 5 buku',
        'Akses Layanan Fotocopy',
        'Akses Internet Gratis Saat Di Perpustakaan',
        'Gratis Parkir Di Perpustakaan',
        'Diskon 10% Jika Membeli Buku'
      ]
    },
    5: {
      'name': 'Guru Pustaka',
      'description': 'Level tertinggi dengan pengetahuan mendalam',
      'minPoints': 3000,
      'maxPoints': double.infinity,
      'pointsToNext': double.infinity,
      'icon': '👑',
      'color': 0xFF1E88E5, // Blue variant
      'benefits': [
        'Waktu peminjaman 60 hari',
        'Dapat meminjam 6 buku',
        'Akses Layanan Fotocopy',
        'Akses Internet Gratis Saat Di Perpustakaan',
        'Gratis Parkir Di Perpustakaan',
        'Diskon 20% Jika Membeli Buku',
        'Akses Ruang Komputer'
      ]
    },
  };

  static Map<String, dynamic>? getLevelInfo(int level) {
    return levels[level];
  }

  static int calculateLevel(int points) {
    for (var entry in levels.entries) {
      if (points >= entry.value['minPoints'] &&
          (entry.value['maxPoints'] == double.infinity ||
              points <= entry.value['maxPoints'])) {
        return entry.key;
      }
    }
    return 0;
  }

  static double calculateProgress(int points) {
    int currentLevel = calculateLevel(points);
    var levelInfo = levels[currentLevel];
    if (levelInfo == null) return 0.0;

    int minPoints = levelInfo['minPoints'];
    var maxPoints = levelInfo['maxPoints'];

    if (maxPoints == double.infinity) {
      // For the highest level, we'll consider progress as 100%
      return 1.0;
    }

    int pointsInLevel = points - minPoints;
    int totalPointsForLevel = levelInfo['pointsToNext'] - minPoints;

    return pointsInLevel / totalPointsForLevel;
  }

  static String getNextLevelRequirement(int points, int currentLevel) {
    if (currentLevel >= 5) {
      return 'Anda telah mencapai level tertinggi!';
    }

    var nextLevel = levels[currentLevel + 1];
    if (nextLevel == null) return '';

    var nextLevelMinPoints = nextLevel['minPoints'] as int;
    return 'Butuh ${nextLevelMinPoints - points} poin lagi untuk mencapai level ${currentLevel + 1}';
  }

  static List<String> getLevelRewards(int level) {
    var levelInfo = levels[level];
    if (levelInfo == null) return [];
    return List<String>.from(levelInfo['benefits'] as List<dynamic>);
  }

  static String getPointsRange(int level) {
    var levelInfo = levels[level];
    if (levelInfo == null) return '';

    int minPoints = levelInfo['minPoints'];
    var maxPoints = levelInfo['maxPoints'];

    if (maxPoints == double.infinity) {
      return '$minPoints+ poin';
    }

    return '$minPoints - $maxPoints poin';
  }
}
