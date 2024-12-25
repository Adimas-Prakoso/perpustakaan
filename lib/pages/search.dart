import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'book.dart';

enum SortOption {
  nameAZ,
  nameZA,
  ratingHigh,
  ratingLow,
}

enum BookCategory {
  all,
  nonfiction,
  fiction,
  teen,
  children,
  lifestyle,
  asianLit,
}

extension BookCategoryExtension on BookCategory {
  String get displayName {
    switch (this) {
      case BookCategory.all:
        return 'Semua';
      case BookCategory.nonfiction:
        return 'Nonfiksi';
      case BookCategory.fiction:
        return 'Fiksi & Sastra';
      case BookCategory.teen:
        return 'Remaja';
      case BookCategory.children:
        return 'Anak-anak';
      case BookCategory.lifestyle:
        return 'Craft Kuliner Fashion & Kecantikan';
      case BookCategory.asianLit:
        return 'Sastra Asia';
    }
  }
}

class SearchStyles {
  static const Color primaryColor = Color(0xFF2C3E50);
  static const Color secondaryColor = Color(0xFF34495E);
  static const Color accentColor = Color(0xFF3498DB);
  static const Color backgroundColor = Color(0xFFF5F6F8);
  static const Color textColor = Color(0xFF2C3E50);

  static const double borderRadius = 16.0;
  static const double cardElevation = 8.0;

  static final searchBarDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(borderRadius),
    boxShadow: [
      BoxShadow(
        color: primaryColor.withAlpha(20),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();

  SortOption _currentSort = SortOption.nameAZ;
  BookCategory _currentCategory = BookCategory.all;

  final List<Map<String, dynamic>> _allBooks = [
    {
      'title': 'Aku Yang Sudah Lama Hilang',
      'cover': 'assets/images/test-book.jpg',
      'author': 'Nago Toejene',
      'description':
          '''“Diramu untuk memahami dirimu, ditulis untuk mengembalikan jiwa yang lama kamu abaikan.” —Jiemi Ardian, Psikiater

Kapan terakhir kali kamu merasa bahagia? Bangun dengan perasaan ringan, memiliki semangat untuk pergi bekerja, serta dikelilingi oleh orang-orang yang kamu sayangi?

Tak terasa kehidupan dewasa sering kali menguras diri kita secara perlahan. Tang- gung jawab yang bertambah banyak, berbagai masalah yang datang silih berganti, atau ekspektasi dari lingkungan sekitar yang membebani. Kita pun tetap berusaha melewati seluruh tantangan tersebut... tanpa menyadari kalau kita sedang perlahan menghilang dalam prosesnya.

Apabila kamu sedang berada di posisi ini dan merasa bahwa ini waktu yang pas untuk kembali menemukan dirimu, maka kamu telah bertemu dengan buku yang tepat. Bersama buku ini, kita akan belajar untuk mulai mendengarkan pikiran dan perasaan dari dalam diri, memiliki hubungan yang baik dengan diri, serta membuat pilihan hidup yang terbaik untuk diri.

Terdengar sedikit egois? Memang.''',
      'rating': 4.5,
      'category': BookCategory.nonfiction,
    },
    {
      'title': 'Seorang Pria yang Melalui Duka dengan Mencuci Piring',
      'cover': 'assets/images/test-book2.jpg',
      'author': 'Dr. Andreas Kurniawan, Sp.KJ',
      'description':
          '''“Buku ini akan membantu menuntun kita di proses penerimaan dan perubahan agar arahnya tidak menuju keterpurukan, melainkan menuju pribadi yang lebih kuat dalam menjalani kehidupan dan menikmatinya seapa-adanya.” —Kunto Aji, Musisi

Ketika menyambut pasien yang sedang berduka, seorang psikiater akan menggali keilmuan yang dimiliki. Dia akan mengulik semua teori duka yang pernah dipelajari di masa kuliah dulu dan mengingat pengalaman dari pasien-pasien sebelumnya. Kemudian, dia menyintesis itu untuk membantu pasien yang sedang berduka di hadapannya.

Tapi, ketika Andreas—seorang psikiater—kehilangan anaknya, dia melakukan hal yang berbeda. Dia melemparkan semua teori tersebut ke luar jendela dan memutuskan untuk mencari makna tentang mengapa ini semua terjadi. Dalam pengalamannya, dia menemukan bahwa duka bisa dilalui dengan mencuci piring kotor yang menumpuk di dapur.

Buku ini adalah proses Andreas memaknai kehilangan besar dalam hidupnya. Diceritakan santai dengan tambahan sedikit bumbu humor gelap, buku ini memuat panduan bermanfaat yang langsung bisa diaplikasikan dalam hidup, seperti: “Tutorial Mencuci Piring”, “Tutorial Menyusun Puzzle”, dan tentunya “Tutorial Menerima Kematian Seorang Anak”.

“Hampir semua orang mempertanyakan: apa hubungannya antara duka dan mencuci piring? Jawaban saya adalah duka itu seperti mencuci piring, tidak ada orang yang mau melakukannya, tapi pada akhirnya seseorang perlu melakukannya.”''',
      'rating': 4.2,
      'category': BookCategory.nonfiction,
    },
    {
      'title': 'Yellowface',
      'cover': 'assets/images/test-book3.jpg',
      'author': 'R. F. Kuang',
      'description':
          '''June Hayward dan Athena Liu sama-sama penulis. Athena, keturunan Asia, ternyata lebih ngetop. Sementara June berpendapat tak ada yang akan tertarik pada karyanya, gadis kulit putih biasa.

Ketika Athena mendadak meninggal, June mencuri manuskrip Athena lalu menyerahkannya ke penerbit sebagai karyanya.

Penerbit membuatkan citra baru bagi June, lengkap dengan foto yang ambigu mengenai etnik dirinya.

Di luar dugaan, buku itu sukses besar.

Namun, June tidak bisa lolos dari bayangan Athena, dan bukti-bukti bermunculan, mengancam kesuksesan June.

Saat berpacu untuk menutupi rahasianya, June jadi tahu seberapa jauh ia berani bertindak untuk mempertahankan apa yang menurutnya layak ia dapatkan.

“Sangat memuaskan. Adiktif.” — New York Times Book Review

“Bacaan yang seru. Kriminal, satire, horor, paranoia, masalah etnis. Tapi, pada dasarnya, kisah yang hebat. Sulit diletakkan, sulit dilupakan.”— Stephen King''',
      'rating': 4.8,
      'category': BookCategory.fiction,
    },
    {
      'title': 'Funiculi Funicula 2: Kisah-Kisah yang Baru Terungkap',
      'cover': 'assets/images/test-book4.jpg',
      'author': 'Toshikazu Kawaguchi',
      'description':
          '''Funiculi Funicula, sebuah kafe di gang sempit di Tokyo, masih kerap didatangi orang-orang yang ingin menjelajahi waktu. Peraturan-peraturan yang merepotkan masih berlaku, tetapi itu semua tidak menyurutkan harapan mereka untuk memutar waktu.

Kali ini ada seorang pria yang ingin kembali ke masa lalu untuk menemui sahabat yang putrinya ia besarkan, seorang putra putus asa yang tidak menghadiri pemakaman ibunya, seorang pria sekarat yang ingin melompat ke dua tahun kemudian untuk memastikan kekasihnya bahagia, dan seorang detektif yang ingin memberi istrinya hadiah ulang tahun untuk pertama sekaligus terakhir kalinya.

Kenyataan memang akan tetap sama. Namun dalam singkatnya durasi sampai kopi mendingin, mungkin masih tersisa waktu bagi mereka untuk menghapus penyesalan, membebaskan diri dari rasa bersalah, atau mungkin melihat terwujudnya harapan...''',
      'rating': 4.3,
      'category': BookCategory.asianLit,
    },
    {
      'title': 'Menjadi: Seni Membangun Kesadaran tentang Diri dan Sekitar',
      'cover': 'assets/images/test-book5.jpg',
      'author': 'Afutami',
      'description':
          '''Kemampuan berpikir adalah sebuah perjalanan—bukan tujuan—yang sebagai konsekuensinya akan menumbuhkan pemahaman tentang diri, kemampuan memecahkan masalah secara lebih efektif, sikap terbuka terhadap pemikiran baru, hingga empati yang lebih baik dalam berhubungan dengan manusia lain.

Lewat Menjadi, Afutami menawarkan peta jalan yang membantu penelusuran tersebut. Alih-alih menggurui, buku ini mengajak kita berkaca lewat perjalanan penulisnya dalam memproses disonansi dari berbagai paradoks kehidupan yang ditemuinya, mulai dari privilese dan ketimpangan, nasionalisme dan humanisme, hingga ekonomi dan lingkungan. Di akhir, Menjadi juga menawarkan opsi konkret untuk mengejawantahkan kemampuan berpikir tersebut ke dalam aksi dan kontribusi nyata. Harapannya, buku ini bisa menjadi teman dalam berproses dan penemuan-penemuan internal yang memerdekakan diri serta membantu membangun hubungan lebih sehat dengan sekitar.''',
      'rating': 4.6,
      'category': BookCategory.nonfiction,
    },
  ];
  List<Map<String, dynamic>> _displayedBooks = [];

  @override
  void initState() {
    super.initState();
    _displayedBooks = List.from(_allBooks);
    _sortBooks();
  }

  void _filterAndSortBooks() {
    setState(() {
      // First filter by category
      if (_currentCategory == BookCategory.all) {
        _displayedBooks = List.from(_allBooks);
      } else {
        _displayedBooks = _allBooks
            .where((book) => book['category'] == _currentCategory)
            .toList();
      }

      // Then filter by search query if exists
      if (_searchController.text.isNotEmpty) {
        _displayedBooks = _displayedBooks
            .where((book) => book['title']
                .toString()
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()))
            .toList();
      }

      // Finally apply sorting
      _sortBooks();
    });
  }

  void _sortBooks() {
    setState(() {
      switch (_currentSort) {
        case SortOption.nameAZ:
          _displayedBooks.sort(
              (a, b) => a['title'].toString().compareTo(b['title'].toString()));
          break;
        case SortOption.nameZA:
          _displayedBooks.sort(
              (a, b) => b['title'].toString().compareTo(a['title'].toString()));
          break;
        case SortOption.ratingHigh:
          _displayedBooks.sort((a, b) => b['rating'].compareTo(a['rating']));
          break;
        case SortOption.ratingLow:
          _displayedBooks.sort((a, b) => a['rating'].compareTo(b['rating']));
          break;
      }
    });
  }

  void _handleSearch(String query) {
    _filterAndSortBooks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SearchStyles.backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar Section
            FadeInDown(
              duration: const Duration(milliseconds: 500),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: SlideInLeft(
                            duration: const Duration(milliseconds: 600),
                            child: Container(
                              decoration: SearchStyles.searchBarDecoration,
                              child: TextField(
                                controller: _searchController,
                                onChanged: _handleSearch,
                                style: TextStyle(
                                  color: SearchStyles.textColor,
                                  fontSize: 16,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Cari buku...',
                                  hintStyle: TextStyle(
                                    color:
                                        SearchStyles.textColor.withAlpha(150),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    color: SearchStyles.primaryColor,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear_rounded),
                                          color: SearchStyles.primaryColor,
                                          onPressed: () {
                                            _searchController.clear();
                                            _handleSearch('');
                                          },
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SlideInRight(
                          duration: const Duration(milliseconds: 600),
                          child: Container(
                            decoration: SearchStyles.searchBarDecoration,
                            child: PopupMenuButton<SortOption>(
                              initialValue: _currentSort,
                              onSelected: (SortOption sortOption) {
                                setState(() {
                                  _currentSort = sortOption;
                                  _sortBooks();
                                });
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              position: PopupMenuPosition.under,
                              icon: Icon(
                                Icons.sort_rounded,
                                color: SearchStyles.primaryColor,
                              ),
                              itemBuilder: (BuildContext context) => [
                                PopupMenuItem<SortOption>(
                                  value: SortOption.nameAZ,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.sort_by_alpha,
                                        color: _currentSort == SortOption.nameAZ
                                            ? SearchStyles.primaryColor
                                            : Colors.grey,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('Nama (A - Z)'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem<SortOption>(
                                  value: SortOption.nameZA,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.sort_by_alpha,
                                        color: _currentSort == SortOption.nameZA
                                            ? SearchStyles.primaryColor
                                            : Colors.grey,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('Nama (Z - A)'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem<SortOption>(
                                  value: SortOption.ratingHigh,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: _currentSort ==
                                                SortOption.ratingHigh
                                            ? SearchStyles.primaryColor
                                            : Colors.grey,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('Rating Tertinggi'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem<SortOption>(
                                  value: SortOption.ratingLow,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.star_border,
                                        color:
                                            _currentSort == SortOption.ratingLow
                                                ? SearchStyles.primaryColor
                                                : Colors.grey,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('Rating Terendah'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FadeInUp(
                      duration: const Duration(milliseconds: 700),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: BookCategory.values.map((category) {
                            bool isSelected = _currentCategory == category;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                selected: isSelected,
                                checkmarkColor: Colors.greenAccent,
                                label: Text(
                                  category.displayName,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : SearchStyles.textColor,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                backgroundColor: Colors.white,
                                selectedColor: SearchStyles.primaryColor,
                                onSelected: (bool selected) {
                                  setState(() {
                                    _currentCategory = category;
                                    _filterAndSortBooks();
                                  });
                                },
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected
                                        ? SearchStyles.primaryColor
                                        : Colors.grey.withAlpha(40),
                                  ),
                                ),
                                elevation: isSelected ? 4 : 0,
                                pressElevation: 2,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _displayedBooks.isEmpty
                  ? FadeIn(
                      duration: const Duration(milliseconds: 300),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FadeInDown(
                              duration: const Duration(milliseconds: 400),
                              child: Icon(
                                Icons.search_off_rounded,
                                size: 64,
                                color: SearchStyles.primaryColor.withAlpha(150),
                              ),
                            ),
                            const SizedBox(height: 16),
                            FadeInUp(
                              duration: const Duration(milliseconds: 400),
                              child: Text(
                                'Tidak ada buku yang ditemukan',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: SearchStyles.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _displayedBooks.length,
                      itemBuilder: (context, index) {
                        final book = _displayedBooks[index];
                        return FadeInUp(
                          duration: Duration(milliseconds: 300 + (index * 100)),
                          from: 50,
                          child: SlideInUp(
                            duration:
                                Duration(milliseconds: 400 + (index * 100)),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(
                                  SearchStyles.borderRadius),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        BookDetailPage(book: book),
                                  ),
                                );
                              },
                              child: Card(
                                elevation: SearchStyles.cardElevation,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      SearchStyles.borderRadius),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                        SearchStyles.borderRadius),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        SearchStyles.primaryColor,
                                        SearchStyles.secondaryColor,
                                      ],
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        flex: 4,
                                        child: Hero(
                                          tag: 'book-${book['title']}',
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                top: Radius.circular(16),
                                              ),
                                              image: DecorationImage(
                                                image:
                                                    AssetImage(book['cover']),
                                                fit: BoxFit.cover,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withAlpha(50),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                book['title'],
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                book['author'],
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white
                                                      .withAlpha(200),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.star_rounded,
                                                    size: 16,
                                                    color: Colors.amber
                                                        .withAlpha(230),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    book['rating'].toString(),
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
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
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
