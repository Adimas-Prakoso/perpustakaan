import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  static const String _baseUrl = 'https://api-beige-six.vercel.app';

  static Future<bool> sendOTPEmail({
    required String email,
    required String otp,
  }) async {
    try {
      print('Attempting to send OTP to: $email');

      // Create a custom HTTP client with security settings
      final client = http.Client();
      try {
        final response = await client.post(
          Uri.parse('$_baseUrl/send-email'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode({
            'to': email,
            'subject': 'Kode Verifikasi Perpustakaan',
            'htmlContent': '''
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <style>
                    body {
                        font-family: 'Segoe UI', Arial, sans-serif;
                        line-height: 1.6;
                        color: #333333;
                        margin: 0;
                        padding: 0;
                        background-color: #f5f5f5;
                    }
                    .container {
                        max-width: 600px;
                        margin: 20px auto;
                        background-color: #ffffff;
                        border-radius: 10px;
                        overflow: hidden;
                        box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
                    }
                    .header {
                        background: linear-gradient(135deg, #053149 0%, #1a4d6d 100%);
                        color: white;
                        padding: 30px 20px;
                        text-align: center;
                    }
                    .header h1 {
                        margin: 0;
                        font-size: 28px;
                        font-weight: 600;
                        letter-spacing: 1px;
                    }
                    .header p {
                        margin: 10px 0 0;
                        opacity: 0.9;
                        font-size: 16px;
                    }
                    .content {
                        padding: 40px 30px;
                        background-color: white;
                    }
                    .greeting {
                        font-size: 18px;
                        color: #053149;
                        margin-bottom: 20px;
                    }
                    .otp-box {
                        background: linear-gradient(135deg, #f0f7ff 0%, #e6f3ff 100%);
                        border: 2px solid #053149;
                        border-radius: 12px;
                        padding: 25px;
                        margin: 30px 0;
                        text-align: center;
                    }
                    .otp-code {
                        font-family: 'Courier New', monospace;
                        font-size: 36px;
                        font-weight: bold;
                        color: #053149;
                        letter-spacing: 8px;
                        margin: 10px 0;
                        text-shadow: 1px 1px 1px rgba(0, 0, 0, 0.1);
                    }
                    .otp-label {
                        font-size: 14px;
                        color: #666666;
                        margin-bottom: 10px;
                    }
                    .expiry-notice {
                        background-color: #fff3e0;
                        border-left: 4px solid #ff9800;
                        padding: 15px;
                        margin: 20px 0;
                        font-size: 14px;
                        color: #e65100;
                    }
                    .footer {
                        background-color: #f8f9fa;
                        padding: 20px;
                        text-align: center;
                        font-size: 12px;
                        color: #666666;
                    }
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        <h1>Kode Verifikasi</h1>
                        <p>Perpustakaan Digital</p>
                    </div>
                    <div class="content">
                        <div class="greeting">Halo,</div>
                        <p>Berikut adalah kode verifikasi Anda untuk mendaftar di Perpustakaan Digital:</p>
                        <div class="otp-box">
                            <div class="otp-label">Kode Verifikasi Anda</div>
                            <div class="otp-code">$otp</div>
                        </div>
                        <div class="expiry-notice">
                            Kode verifikasi ini akan kadaluarsa dalam 5 menit.
                        </div>
                    </div>
                    <div class="footer">
                        <p>Email ini dikirim secara otomatis. Mohon jangan membalas email ini.</p>
                        <p>&copy; 2024 Perpustakaan Digital. All rights reserved.</p>
                    </div>
                </div>
            </body>
            </html>
            '''
          }),
        );

        if (response.statusCode == 200) {
          print('OTP sent successfully to: $email');
          return true;
        }

        print('Failed to send OTP. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');

        final responseData = json.decode(response.body);
        throw Exception(responseData['error'] ?? 'Failed to send OTP');
      } finally {
        client.close();
      }
    } catch (e) {
      print('Error sending OTP to $email: $e');
      return false;
    }
  }
}
