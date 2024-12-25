import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BorrowedBooksService {
  static final BorrowedBooksService _instance = BorrowedBooksService._internal();
  factory BorrowedBooksService() => _instance;
  BorrowedBooksService._internal();

  Future<int> getBorrowedBooksCount() async {
    final prefs = await SharedPreferences.getInstance();
    final borrowedBooks = prefs.getStringList('borrowed_books') ?? [];
    
    int count = 0;
    for (String book in borrowedBooks) {
      final Map<String, dynamic> bookData = jsonDecode(book);
      if (bookData['status'] == 'Dipinjam') {
        count++;
      }
    }
    return count;
  }

  static Stream<int> get borrowedBooksCountStream {
    return Stream.periodic(const Duration(seconds: 1)).asyncMap((_) async {
      return await BorrowedBooksService().getBorrowedBooksCount();
    });
  }
}
