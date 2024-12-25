import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:animate_do/animate_do.dart';
import '../services/notification_service.dart';
import '../services/borrowed_books_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Constants for colors and styles
class HistoryStyles {
  static const Color primaryColor = Color(0xFF2C3E50);
  static const Color secondaryColor = Color(0xFF34495E);
  static const Color selectedColor = Color(0xFF3498DB);
  static const Color borrowedColor = Color(0xFFE67E22);
  static const Color returnedColor = Color(0xFF27AE60);
  static const Color textColor = Colors.white;

  static const double tabletBreakpoint = 600.0;
  static const double cardElevation = 8.0;
  static const double borderRadius = 16.0;

  static final cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, secondaryColor],
  );
}

// Data model for history items
class BorrowHistory {
  final String title;
  final String author;
  final DateTime borrowDate;
  final DateTime returnDate;
  String status;
  DateTime? actualReturnDate;

  BorrowHistory({
    required this.title,
    required this.author,
    required this.borrowDate,
    required this.returnDate,
    required this.status,
    this.actualReturnDate,
  });

  factory BorrowHistory.fromMap(Map<String, dynamic> map) {
    return BorrowHistory(
      title: map['title'] as String,
      author: map['author'] as String,
      borrowDate: DateTime.parse(map['borrowDate']),
      returnDate: DateTime.parse(map['returnDate']),
      status: map['status'] as String,
      actualReturnDate: map['actualReturnDate'] != null
          ? DateTime.parse(map['actualReturnDate'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'borrowDate': borrowDate.toIso8601String(),
      'returnDate': returnDate.toIso8601String(),
      'status': status,
      'actualReturnDate': actualReturnDate?.toIso8601String(),
    };
  }
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late DateFormat _dateFormat;
  List<BorrowHistory> _historyItems = [];
  final Set<int> _selectedItems = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _initializeLocale();
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('id');
    setState(() {
      _dateFormat = DateFormat('dd MMMM yyyy', 'id');
    });
    _loadBorrowedBooks();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadBorrowedBooks() async {
    final prefs = await SharedPreferences.getInstance();
    final borrowedBooks = prefs.getStringList('borrowed_books') ?? [];

    setState(() {
      _historyItems = borrowedBooks.map((item) {
        final Map<String, dynamic> data = jsonDecode(item);
        return BorrowHistory(
          title: data['title'],
          author: data['author'],
          borrowDate: DateTime.parse(data['borrowDate']),
          returnDate: DateTime.parse(data['returnDate']),
          status: data['status'],
          actualReturnDate: data['actualReturnDate'] != null
              ? DateTime.parse(data['actualReturnDate'])
              : null,
        );
      }).toList();
    });
  }

  Future<void> _returnBook(int index) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> borrowedBooks = prefs.getStringList('borrowed_books') ?? [];

    if (index < borrowedBooks.length) {
      Map<String, dynamic> book = jsonDecode(borrowedBooks[index]);
      book['status'] = 'Dikembalikan';
      book['actualReturnDate'] = DateTime.now().toIso8601String();
      borrowedBooks[index] = jsonEncode(book);

      await prefs.setStringList('borrowed_books', borrowedBooks);

      setState(() {
        _historyItems[index].status = 'Dikembalikan';
        _historyItems[index].actualReturnDate = DateTime.now();
      });

      // Trigger borrowed books count update
      await BorrowedBooksService().getBorrowedBooksCount();

      if (!mounted) return;

      NotificationService().addNotification(
        context: context,
        title: 'Pengembalian Buku',
        message: 'Buku "${_historyItems[index].title}" berhasil dikembalikan',
        type: NotificationType.returnSuccess,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Buku berhasil dikembalikan'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _deleteSelected() async {
    bool canDelete = _selectedItems
        .every((index) => _historyItems[index].status == 'Dikembalikan');

    if (!canDelete) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Hanya buku yang sudah dikembalikan yang dapat dihapus'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    List<String> borrowedBooks = prefs.getStringList('borrowed_books') ?? [];

    final sortedIndexes = _selectedItems.toList()
      ..sort((a, b) => b.compareTo(a));

    for (var index in sortedIndexes) {
      borrowedBooks.removeAt(index);
    }
    await prefs.setStringList('borrowed_books', borrowedBooks);

    // Trigger borrowed books count update
    await BorrowedBooksService().getBorrowedBooksCount();

    setState(() {
      for (var index in sortedIndexes) {
        _historyItems.removeAt(index);
      }
      _selectedItems.clear();
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Riwayat peminjaman berhasil dihapus'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showHistoryDetail(BorrowHistory item, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.book,
              color: const Color(0xFF0A2647),
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(
                  color: Color(0xFF0A2647),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Penulis: ${item.author}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Dipinjam: ${_dateFormat.format(item.borrowDate)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.event_available, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Batas Kembali: ${_dateFormat.format(item.returnDate)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            if (item.actualReturnDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    item.actualReturnDate != null
                        ? 'Dikembalikan: ${_dateFormat.format(item.actualReturnDate!)}'
                        : 'Batas Kembali: ${_dateFormat.format(item.returnDate)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: item.status == 'Dipinjam'
                    ? HistoryStyles.borrowedColor
                    : HistoryStyles.returnedColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.status == 'Dipinjam'
                        ? Icons.access_time
                        : Icons.check_circle,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (item.status == 'Dipinjam')
            TextButton.icon(
              onPressed: () {
                _returnBook(index);
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.assignment_return),
              label: const Text('Kembalikan'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: HistoryStyles.borrowedColor,
              ),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF0A2647),
            ),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isTablet = screenSize.width > HistoryStyles.tabletBreakpoint;
    final double cardPadding = isTablet ? 16.0 : 12.0;
    final double fontSize = isTablet ? 16.0 : 14.0;
    final double iconSize = isTablet ? 28.0 : 24.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A2647),
        title: _isSelectionMode
            ? Text('${_selectedItems.length} item dipilih',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white))
            : const Text('Riwayat Peminjaman',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(
                Icons.delete,
                color: Colors.white,
              ),
              onPressed: _selectedItems.isNotEmpty ? _deleteSelected : null,
            ),
            IconButton(
              icon: const Icon(
                Icons.close,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _isSelectionMode = false;
                  _selectedItems.clear();
                });
              },
            ),
          ],
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (isTablet) {
            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              padding: EdgeInsets.all(cardPadding),
              itemCount: _historyItems.length,
              itemBuilder: (context, index) => FadeInUp(
                duration: Duration(milliseconds: 300 + (index * 100)),
                child: Stack(
                  children: [
                    _buildHistoryCard(index, fontSize, iconSize, cardPadding),
                    if (_isSelectionMode)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _selectedItems.contains(index)
                                ? Colors.blue
                                : Colors.grey.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              _selectedItems.contains(index)
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: _historyItems.length,
            padding: EdgeInsets.all(cardPadding),
            itemBuilder: (context, index) => FadeInUp(
              duration: Duration(milliseconds: 300 + (index * 100)),
              child: Stack(
                children: [
                  _buildHistoryCard(index, fontSize, iconSize, cardPadding),
                  if (_isSelectionMode)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedItems.contains(index)
                              ? Colors.blue
                              : Colors.grey.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            _selectedItems.contains(index)
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(
    int index,
    double fontSize,
    double iconSize,
    double padding,
  ) {
    final item = _historyItems[index];
    final bool isSelected = _selectedItems.contains(index);

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          setState(() {
            if (_selectedItems.contains(index)) {
              _selectedItems.remove(index);
              if (_selectedItems.isEmpty) {
                _isSelectionMode = false;
              }
            } else {
              _selectedItems.add(index);
            }
          });
        } else {
          _showHistoryDetail(item, index);
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          setState(() {
            _isSelectionMode = true;
            _selectedItems.add(index);
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: EdgeInsets.symmetric(vertical: padding / 2),
        child: ZoomIn(
          duration: const Duration(milliseconds: 200),
          child: Card(
            elevation: isSelected
                ? HistoryStyles.cardElevation + 2
                : HistoryStyles.cardElevation,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HistoryStyles.borderRadius),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(HistoryStyles.borderRadius),
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          HistoryStyles.selectedColor,
                          HistoryStyles.selectedColor.withAlpha(204)
                        ],
                      )
                    : HistoryStyles.cardGradient,
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? HistoryStyles.selectedColor.withAlpha(77)
                        : Colors.black.withAlpha(51),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (_isSelectionMode) {
                      setState(() {
                        if (_selectedItems.contains(index)) {
                          _selectedItems.remove(index);
                          if (_selectedItems.isEmpty) {
                            _isSelectionMode = false;
                          }
                        } else {
                          _selectedItems.add(index);
                        }
                      });
                    } else {
                      _showHistoryDetail(item, index);
                    }
                  },
                  onLongPress: () {
                    if (!_isSelectionMode) {
                      setState(() {
                        _isSelectionMode = true;
                        _selectedItems.add(index);
                      });
                    }
                  },
                  borderRadius:
                      BorderRadius.circular(HistoryStyles.borderRadius),
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                isSelected
                                    ? Icons.check_circle_rounded
                                    : Icons.menu_book_rounded,
                                color: Colors.white,
                                size: iconSize,
                                key: ValueKey(isSelected),
                              ),
                            ),
                            SizedBox(width: padding),
                            Expanded(
                              child: Text(
                                item.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: fontSize * 1.2,
                                  letterSpacing: 0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: padding / 1.5),
                        Text(
                          'Penulis: ${item.author}',
                          style: TextStyle(
                            color: Colors.white.withAlpha(230),
                            fontSize: fontSize,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: fontSize,
                              color: Colors.white.withAlpha(179),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Pinjam: ${_dateFormat.format(item.borrowDate)}',
                              style: TextStyle(
                                color: Colors.white.withAlpha(230),
                                fontSize: fontSize,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.event_rounded,
                              size: fontSize,
                              color: Colors.white.withAlpha(179),
                            ),
                            SizedBox(width: 4),
                            Text(
                              item.status == 'Dipinjam'
                                  ? 'Batas Kembali: ${_dateFormat.format(item.returnDate)}'
                                  : item.actualReturnDate != null
                                      ? 'Dikembalikan: ${_dateFormat.format(item.actualReturnDate!)}'
                                      : 'Batas Kembali: ${_dateFormat.format(item.returnDate)}',
                              style: TextStyle(
                                color: Colors.white.withAlpha(230),
                                fontSize: fontSize,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: padding / 1.5),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: padding,
                            vertical: padding / 2,
                          ),
                          decoration: BoxDecoration(
                            color: item.status == 'Dipinjam'
                                ? HistoryStyles.borrowedColor
                                : HistoryStyles.returnedColor,
                            borderRadius: BorderRadius.circular(
                                HistoryStyles.borderRadius / 2),
                            boxShadow: [
                              BoxShadow(
                                color: (item.status == 'Dipinjam'
                                        ? HistoryStyles.borrowedColor
                                        : HistoryStyles.returnedColor)
                                    .withAlpha(77),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item.status == 'Dipinjam'
                                    ? Icons.access_time_rounded
                                    : Icons.check_circle_rounded,
                                size: fontSize,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                item.status,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
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
            ),
          ),
        ),
      ),
    );
  }
}
