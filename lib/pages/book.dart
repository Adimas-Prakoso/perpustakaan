import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:perpustakaan/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/borrowed_books_service.dart';

class BookDetailPage extends StatefulWidget {
  final Map<String, dynamic> book;
  const BookDetailPage({super.key, required this.book});

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  List<ReviewData> reviews = [
    ReviewData(
      username: "John Doe",
      rating: 4.5,
      comment: "Buku yang sangat menarik dan informatif!",
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
    ),
    ReviewData(
      username: "Jane Smith",
      rating: 5.0,
      comment: "Sangat recommended untuk dibaca!",
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  double get averageRating {
    if (reviews.isEmpty) return 0;
    return reviews.map((r) => r.rating).reduce((a, b) => a + b) /
        reviews.length;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _showBorrowDialog() {
    int borrowDays = 1;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Pilih Durasi Peminjaman'),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      if (borrowDays > 1) {
                        setState(() {
                          borrowDays--;
                        });
                      }
                    },
                    icon: const Icon(Icons.remove),
                  ),
                  Text('$borrowDays hari'),
                  IconButton(
                    onPressed: () {
                      if (borrowDays < 14) {
                        setState(() {
                          borrowDays++;
                        });
                      }
                    },
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _borrowBook(borrowDays);
                  },
                  child: const Text('Pinjam'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showReviewDialog() {
    double rating = 0;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Beri Rating & Komentar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rating'),
            const SizedBox(height: 8),
            Center(
              child: RatingBar.builder(
                initialRating: 0,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemSize: 36,
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (value) => rating = value,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Komentar'),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Tulis komentar Anda...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A2647),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              if (_commentController.text.isNotEmpty && rating > 0) {
                setState(() {
                  reviews.insert(
                    0,
                    ReviewData(
                      username: 'User', // Replace with actual username
                      rating: rating,
                      comment: _commentController.text,
                      timestamp: DateTime.now(),
                    ),
                  );
                  _commentController.clear();
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Review berhasil ditambahkan'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  Future<void> _borrowBook(int days) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final returnDate = now.add(Duration(days: days));

    // Create borrow history object
    final borrowHistory = {
      'title': widget.book['title'],
      'author': widget.book['author'],
      'borrower': 'User', // Replace with actual user name later
      'borrowDate': now.toIso8601String(),
      'returnDate': returnDate.toIso8601String(),
      'status': 'Dipinjam',
    };

    // Get existing history or create new list
    List<String> borrowedBooks = prefs.getStringList('borrowed_books') ?? [];
    borrowedBooks.add(jsonEncode(borrowHistory));

    // Save updated history
    await prefs.setStringList('borrowed_books', borrowedBooks);

    // Trigger borrowed books count update
    await BorrowedBooksService().getBorrowedBooksCount();

    if (!mounted) return;

    NotificationService().addNotification(
      context: context,
      title: 'Peminjaman Buku',
      message: 'Buku "${widget.book['title']}" berhasil dipinjam',
      type: NotificationType.borrow,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book['title']),
        backgroundColor: const Color(0xFF0A2647),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Hero(
                  tag: 'book-${widget.book['title']}',
                  child: Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(widget.book['cover']),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.book['title'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.book['author'],
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: widget.book['rating'].toDouble(),
                        itemBuilder: (context, index) => const Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        itemCount: 5,
                        itemSize: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.book['rating'].toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Deskripsi',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.book['description'],
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showBorrowDialog,
                          icon: const Icon(Icons.book),
                          label: const Text('Pinjam Buku'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A2647),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showReviewDialog,
                          icon: const Icon(Icons.rate_review),
                          label: const Text('Beri Review'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0A2647),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFF0A2647)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Review',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...reviews.map((review) => ReviewCard(review: review)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReviewData {
  final String username;
  final double rating;
  final String comment;
  final DateTime timestamp;

  ReviewData({
    required this.username,
    required this.rating,
    required this.comment,
    required this.timestamp,
  });
}

class ReviewCard extends StatelessWidget {
  final ReviewData review;

  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF0A2647),
                child: Text(
                  review.username[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (index) => Icon(
                            Icons.star,
                            size: 16,
                            color: index < review.rating
                                ? Colors.amber
                                : Colors.grey[300],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          review.rating.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                _getTimeAgo(review.timestamp),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.comment,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} menit yang lalu';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} jam yang lalu';
    } else {
      return '${difference.inDays} hari yang lalu';
    }
  }
}
