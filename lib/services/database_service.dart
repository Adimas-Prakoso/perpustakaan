import 'package:mysql_client/mysql_client.dart';
import 'package:perpustakaan/models/user_model.dart';

class DatabaseService {
  static Future<MySQLConnection> _getConnection() async {
    final conn = await MySQLConnection.createConnection(
      host: 'localhost',
      port: 3306,
      userName: 'root',
      password: '',
      databaseName: 'perpus',
    );
    await conn.connect();
    return conn;
  }

  static Future<MySQLConnection> getConnection() => _getConnection();

  static Future<UserModel?> login(String email, String password) async {
    final conn = await _getConnection();
    try {
      var result = await conn.execute(
        '''
        SELECT nik, email, name 
        FROM users 
        WHERE email = :email
        AND password = SHA2(:password, 256)
        AND is_verified = true
        ''',
        {
          'email': email,
          'password': password,
        },
      );

      await conn.close();

      if (result.numOfRows > 0) {
        final row = result.rows.first;
        return UserModel(
          nik: row.colByName('nik')?.toString() ?? '',
          email: row.colByName('email')?.toString() ?? '',
          name: row.colByName('name')?.toString() ?? '',
        );
      }
      return null;
    } catch (e) {
      await conn.close();
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> register(
    String nik,
    String email,
    String password,
    String name,
  ) async {
    final conn = await _getConnection();
    try {
      var result = await conn.execute(
        '''
        SELECT nik, email 
        FROM users 
        WHERE email = :email OR nik = :nik
        ''',
        {
          'email': email,
          'nik': nik,
        },
      );

      if (result.numOfRows > 0) {
        await conn.close();
        final row = result.rows.first;
        if (row.colByName('email')?.toString() == email) {
          return {
            'success': false,
            'message': 'Email sudah terdaftar',
          };
        } else if (row.colByName('nik')?.toString() == nik) {
          return {
            'success': false,
            'message': 'NIK sudah terdaftar',
          };
        }
        return {
          'success': false,
          'message': 'Email atau NIK sudah terdaftar',
        };
      }

      // Store user data in temporary table
      await conn.execute(
        '''
        INSERT INTO temp_users 
        (nik, email, password, name, created_at) 
        VALUES 
        (:nik, :email, SHA2(:password, 256), :name, CURRENT_TIMESTAMP)
        ''',
        {
          'nik': nik,
          'email': email,
          'password': password,
          'name': name,
        },
      );

      await conn.close();
      return {
        'success': true,
        'message': 'Silahkan verifikasi email Anda',
      };
    } catch (e) {
      await conn.close();
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> verifyOTP(
      String email, String otp) async {
    final conn = await _getConnection();
    try {
      var result = await conn.execute(
        '''
        SELECT * FROM temp_users 
        WHERE email = :email AND otp = :otp AND 
        created_at >= NOW() - INTERVAL 5 MINUTE
        ''',
        {
          'email': email,
          'otp': otp,
        },
      );

      if (result.numOfRows == 0) {
        await conn.close();
        return {
          'success': false,
          'message': 'Kode OTP tidak valid atau sudah kadaluarsa',
        };
      }

      final userData = result.rows.first;

      // Move user from temp_users to users table
      await conn.execute(
        '''
        INSERT INTO users 
        (nik, email, password, name, created_at, updated_at, is_verified) 
        VALUES 
        (:nik, :email, :password, :name, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, true, 0)
        ''',
        {
          'nik': userData.colByName('nik'),
          'email': userData.colByName('email'),
          'password': userData.colByName('password'),
          'name': userData.colByName('name'),
        },
      );

      // Delete from temp_users
      await conn.execute(
        'DELETE FROM temp_users WHERE email = :email',
        {'email': email},
      );

      await conn.close();
      return {
        'success': true,
        'message': 'Verifikasi berhasil',
      };
    } catch (e) {
      await conn.close();
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> updateOTP(
      String email, String otp) async {
    final conn = await _getConnection();
    try {
      await conn.execute(
        '''
        UPDATE temp_users 
        SET otp = :otp, created_at = CURRENT_TIMESTAMP 
        WHERE email = :email
        ''',
        {
          'email': email,
          'otp': otp,
        },
      );

      await conn.close();
      return {
        'success': true,
        'message': 'OTP berhasil diperbarui',
      };
    } catch (e) {
      await conn.close();
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  static Future<UserModel?> getUserByNik(String nik) async {
    final conn = await _getConnection();
    try {
      var result = await conn.execute(
        '''
        SELECT nik, email, name 
        FROM users 
        WHERE nik = :nik
        AND is_verified = true
        ''',
        {'nik': nik},
      );

      await conn.close();

      if (result.numOfRows > 0) {
        final row = result.rows.first;
        return UserModel(
          nik: row.colByName('nik')?.toString() ?? '',
          email: row.colByName('email')?.toString() ?? '',
          name: row.colByName('name')?.toString() ?? '',
        );
      }
      return null;
    } catch (e) {
      await conn.close();
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getTempUserByNik(String nik) async {
    final conn = await _getConnection();
    try {
      var result = await conn.execute(
        '''
        SELECT nik, email, name 
        FROM temp_users 
        WHERE nik = :nik
        ''',
        {'nik': nik},
      );

      await conn.close();

      if (result.numOfRows > 0) {
        final row = result.rows.first;
        return {
          'nik': row.colByName('nik')?.toString(),
          'email': row.colByName('email')?.toString(),
          'name': row.colByName('name')?.toString(),
        };
      }
      return null;
    } catch (e) {
      await conn.close();
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> updateName(
      String email, String newName) async {
    final conn = await _getConnection();
    try {
      var result = await conn.execute(
        '''
        UPDATE users 
        SET name = :newName
        WHERE email = :email
        AND is_verified = true
        ''',
        {
          'email': email,
          'newName': newName,
        },
      );

      await conn.close();

      if (result.affectedRows.toInt() > 0) {
        return {
          'success': true,
          'message': 'Nama berhasil diperbarui',
        };
      }
      return {
        'success': false,
        'message': 'Gagal memperbarui nama',
      };
    } catch (e) {
      await conn.close();
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> updateEmail(
    String currentEmail,
    String newEmail,
  ) async {
    final conn = await _getConnection();
    try {
      // Check if new email already exists
      var checkResult = await conn.execute(
        'SELECT email FROM users WHERE email = :email',
        {'email': newEmail},
      );

      if (checkResult.numOfRows > 0) {
        await conn.close();
        return {
          'success': false,
          'message': 'Email sudah terdaftar',
        };
      }

      var result = await conn.execute(
        '''
        UPDATE users 
        SET email = :newEmail
        WHERE email = :currentEmail
        AND is_verified = true
        ''',
        {
          'currentEmail': currentEmail,
          'newEmail': newEmail,
        },
      );

      await conn.close();

      if (result.affectedRows.toInt() > 0) {
        return {
          'success': true,
          'message': 'Email berhasil diperbarui',
        };
      }
      return {
        'success': false,
        'message': 'Gagal memperbarui email',
      };
    } catch (e) {
      await conn.close();
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> verifyCurrentPassword(
    String email,
    String password,
  ) async {
    final conn = await _getConnection();
    try {
      var result = await conn.execute(
        '''
        SELECT 1 FROM users 
        WHERE email = :email 
        AND password = SHA2(:password, 256)
        AND is_verified = true
        ''',
        {
          'email': email,
          'password': password,
        },
      );

      await conn.close();

      return {
        'success': result.numOfRows > 0,
        'message': result.numOfRows > 0
            ? 'Password valid'
            : 'Password saat ini tidak valid',
      };
    } catch (e) {
      await conn.close();
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> updatePassword(
    String email,
    String newPassword,
  ) async {
    final conn = await _getConnection();
    try {
      var result = await conn.execute(
        '''
        UPDATE users 
        SET password = SHA2(:newPassword, 256)
        WHERE email = :email
        AND is_verified = true
        ''',
        {
          'email': email,
          'newPassword': newPassword,
        },
      );

      await conn.close();

      if (result.affectedRows.toInt() > 0) {
        return {
          'success': true,
          'message': 'Password berhasil diperbarui',
        };
      }
      return {
        'success': false,
        'message': 'Gagal memperbarui password',
      };
    } catch (e) {
      await conn.close();
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> updatePoints(
      String email, int points) async {
    final conn = await _getConnection();
    try {
      var result = await conn.execute(
        '''
        UPDATE users 
        SET points = points + :points
        WHERE email = :email
        AND is_verified = true
        RETURNING points
        ''',
        {
          'email': email,
          'points': points,
        },
      );

      await conn.close();

      if (result.numOfRows > 0) {
        final newPoints =
            result.rows.first.colByName('points')?.toString() ?? '0';
        return {
          'success': true,
          'message': 'Poin berhasil diperbarui',
          'points': int.parse(newPoints),
        };
      }
      return {
        'success': false,
        'message': 'Gagal memperbarui poin',
      };
    } catch (e) {
      await conn.close();
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  static Future<int> getUserPoints(String email) async {
    final conn = await _getConnection();
    try {
      var result = await conn.execute(
        '''
        SELECT points 
        FROM users 
        WHERE email = :email
        AND is_verified = true
        ''',
        {
          'email': email,
        },
      );

      await conn.close();

      if (result.numOfRows > 0) {
        final points = result.rows.first.colByName('points')?.toString() ?? '0';
        return int.parse(points);
      }
      return 0;
    } catch (e) {
      await conn.close();
      return 0;
    }
  }

  // Book Management Methods
  static Future<List<Map<String, dynamic>>> getAllBooks() async {
    final conn = await _getConnection();
    try {
      final result = await conn.execute('SELECT * FROM books ORDER BY title');
      final books = result.rows.map((row) => row.assoc()).toList();
      return books;
    } catch (e) {
      print('Error getting books: $e');
      return [];
    } finally {
      await conn.close();
    }
  }

  static Future<Map<String, dynamic>?> getBookById(String bookId) async {
    final conn = await _getConnection();
    try {
      final result = await conn
          .execute('SELECT * FROM books WHERE id = :id', {'id': bookId});
      if (result.rows.isEmpty) return null;
      return result.rows.first.assoc();
    } catch (e) {
      print('Error getting book: $e');
      return null;
    } finally {
      await conn.close();
    }
  }

  static Future<List<Map<String, dynamic>>> searchBooks(String query) async {
    final conn = await _getConnection();
    try {
      final result = await conn.execute(
          'SELECT * FROM books WHERE title LIKE :query ORDER BY title',
          {'query': '%$query%'});
      return result.rows.map((row) => row.assoc()).toList();
    } catch (e) {
      print('Error searching books: $e');
      return [];
    } finally {
      await conn.close();
    }
  }

  // Borrowing History Methods
  static Future<List<Map<String, dynamic>>> getBorrowingHistory(
      String userId) async {
    final conn = await _getConnection();
    try {
      final result = await conn.execute('''
        SELECT bh.*, b.title, b.author, b.cover_url 
        FROM borrowing_history bh
        JOIN books b ON bh.book_id = b.id
        WHERE bh.user_id = :userId
        ORDER BY bh.borrow_date DESC
      ''', {'userId': userId});

      return result.rows.map((row) {
        final data = row.assoc();
        return {
          ...data,
          'book': {
            'id': data['book_id'],
            'title': data['title'],
            'author': data['author'],
            'cover_url': data['cover_url']
          }
        };
      }).toList();
    } catch (e) {
      print('Error getting borrowing history: $e');
      return [];
    } finally {
      await conn.close();
    }
  }

  static Future<List<Map<String, dynamic>>> getCurrentBorrowedBooks(
      String userId) async {
    final conn = await _getConnection();
    try {
      final result = await conn.execute('''
        SELECT bh.*, b.title, b.author, b.cover_url 
        FROM borrowing_history bh
        JOIN books b ON bh.book_id = b.id
        WHERE bh.user_id = :userId AND bh.status = 'Dipinjam'
        ORDER BY bh.return_date
      ''', {'userId': userId});

      return result.rows.map((row) {
        final data = row.assoc();
        return {
          ...data,
          'book': {
            'id': data['book_id'],
            'title': data['title'],
            'author': data['author'],
            'cover_url': data['cover_url']
          }
        };
      }).toList();
    } catch (e) {
      print('Error getting current borrowed books: $e');
      return [];
    } finally {
      await conn.close();
    }
  }

  static Future<bool> borrowBook(
      String userId, String bookId, int durationDays) async {
    final conn = await _getConnection();
    try {
      final now = DateTime.now();
      final returnDate = now.add(Duration(days: durationDays));

      // Start a transaction
      await conn.execute('START TRANSACTION');

      // Add borrowing record
      await conn.execute('''
        INSERT INTO borrowing_history 
        (user_id, book_id, borrow_date, return_date, status)
        VALUES 
        (:userId, :bookId, :borrowDate, :returnDate, 'Dipinjam')
      ''', {
        'userId': userId,
        'bookId': bookId,
        'borrowDate': now.toIso8601String(),
        'returnDate': returnDate.toIso8601String()
      });

      // Add 10 points to user
      await conn.execute('''
        UPDATE users 
        SET points = points + 10 
        WHERE id = :userId
      ''', {'userId': userId});

      // Commit transaction
      await conn.execute('COMMIT');
      return true;
    } catch (e) {
      // Rollback on error
      await conn.execute('ROLLBACK');
      print('Error borrowing book: $e');
      return false;
    } finally {
      await conn.close();
    }
  }

  static Future<bool> returnBook(int borrowId) async {
    final conn = await _getConnection();
    try {
      // Start a transaction
      await conn.execute('START TRANSACTION');

      // Get user ID from borrowing record
      final userResult = await conn.execute('''
        SELECT user_id 
        FROM borrowing_history 
        WHERE id = :borrowId
      ''', {'borrowId': borrowId});

      if (userResult.rows.isEmpty) {
        await conn.execute('ROLLBACK');
        return false;
      }

      final userId = userResult.rows.first.assoc()['user_id'];

      // Update borrowing status
      await conn.execute('''
        UPDATE borrowing_history 
        SET status = 'Dikembalikan', 
            actual_return_date = :returnDate
        WHERE id = :id
      ''', {'id': borrowId, 'returnDate': DateTime.now().toIso8601String()});

      // Add 20 points to user
      await conn.execute('''
        UPDATE users 
        SET points = points + 20 
        WHERE id = :userId
      ''', {'userId': userId});

      // Commit transaction
      await conn.execute('COMMIT');
      return true;
    } catch (e) {
      // Rollback on error
      await conn.execute('ROLLBACK');
      print('Error returning book: $e');
      return false;
    } finally {
      await conn.close();
    }
  }

  static Future<bool> deleteBorrowingHistory(List<int> borrowIds) async {
    final conn = await _getConnection();
    try {
      final placeholders =
          List.generate(borrowIds.length, (i) => ':id$i').join(',');
      final params = Map.fromEntries(borrowIds
          .asMap()
          .entries
          .map((e) => MapEntry('id${e.key}', e.value)));

      await conn.execute('''
        DELETE FROM borrowing_history 
        WHERE id IN ($placeholders) 
        AND status = 'Dikembalikan'
      ''', params);
      return true;
    } catch (e) {
      print('Error deleting borrowing history: $e');
      return false;
    } finally {
      await conn.close();
    }
  }
}
