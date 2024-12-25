import 'dart:async';
import 'dart:math';

import 'package:animate_do/animate_do.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:pinput/pinput.dart';

import 'package:perpustakaan/services/database_service.dart';
import 'package:perpustakaan/services/email_service.dart';
import 'package:perpustakaan/widgets/analog_clock.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;
  bool _obscureConfirmText = true;
  String _currentOTP = '';
  bool _canResendOTP = true;
  int _resendTimer = 60;
  Timer? _timer;
  final ValueNotifier<int> _resendTimerNotifier = ValueNotifier(60);

  @override
  void dispose() {
    _timer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nikController.dispose();
    _otpController.dispose();
    _resendTimerNotifier.dispose();
    super.dispose();
  }

  String _generateOTP() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  Future<bool> _sendOTP(String email, String otp) async {
    try {
      final success = await EmailService.sendOTPEmail(
        email: email,
        otp: otp,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: AwesomeSnackbarContent(
              title: 'Gagal!',
              message: 'Gagal mengirim kode OTP',
              contentType: ContentType.failure,
            ),
          ),
        );
      }

      return success;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: AwesomeSnackbarContent(
              title: 'Error!',
              message: 'Gagal mengirim kode OTP: $e',
              contentType: ContentType.failure,
            ),
          ),
        );
      }
      return false;
    }
  }

  void _startResendTimer() {
    setState(() {
      _canResendOTP = false;
      _resendTimer = 60;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
          _resendTimerNotifier.value = _resendTimer;
        } else {
          _canResendOTP = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _showOTPDialog() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() {
      _isLoading = true;
    });

    try {
      _currentOTP = _generateOTP();
      bool sent = await _sendOTP(_emailController.text, _currentOTP);
      if (!sent) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              elevation: 0,
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.transparent,
              content: AwesomeSnackbarContent(
                title: 'Gagal!',
                message: 'Gagal mengirim kode OTP',
                contentType: ContentType.failure,
              ),
            ),
          );
        }
        return;
      }

      await DatabaseService.updateOTP(_emailController.text, _currentOTP);
      _startResendTimer();

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
          builder: (context, dialogSetState) => AlertDialog(
            title: const Text('Verifikasi Email'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildOTPInput(),
                const SizedBox(height: 8),
                if (!_canResendOTP)
                  ValueListenableBuilder<int>(
                    valueListenable: _resendTimerNotifier,
                    builder: (context, value, child) {
                      return Text('$value detik');
                    },
                  ),
                if (_canResendOTP)
                  TextButton(
                    onPressed: () async {
                      dialogSetState(() => _isLoading = true);
                      _currentOTP = _generateOTP();
                      bool sent =
                          await _sendOTP(_emailController.text, _currentOTP);
                      dialogSetState(() => _isLoading = false);

                      if (sent) {
                        await DatabaseService.updateOTP(
                            _emailController.text, _currentOTP);
                        _startResendTimer();
                        if (mounted) {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              elevation: 0,
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.transparent,
                              content: AwesomeSnackbarContent(
                                title: 'Berhasil!',
                                message: 'Kode OTP baru telah dikirim',
                                contentType: ContentType.success,
                              ),
                            ),
                          );
                        }
                      } else {
                        if (mounted) {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              elevation: 0,
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.transparent,
                              content: AwesomeSnackbarContent(
                                title: 'Gagal!',
                                message: 'Gagal mengirim kode OTP',
                                contentType: ContentType.failure,
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Kirim Ulang Kode'),
                  ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  if (_otpController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        elevation: 0,
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.transparent,
                        content: AwesomeSnackbarContent(
                          title: 'Perhatian!',
                          message: 'Masukkan kode OTP',
                          contentType: ContentType.warning,
                        ),
                      ),
                    );
                    return;
                  }

                  dialogSetState(() => _isLoading = true);
                  final result = await DatabaseService.verifyOTP(
                    _emailController.text,
                    _otpController.text,
                  );
                  dialogSetState(() => _isLoading = false);

                  if (result['success']) {
                    if (mounted) {
                      navigator.pop();
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          elevation: 0,
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.transparent,
                          content: AwesomeSnackbarContent(
                            title: 'Berhasil!',
                            message: 'Registrasi berhasil',
                            contentType: ContentType.success,
                          ),
                        ),
                      );
                      navigator.pushReplacementNamed('/login');
                    }
                  } else {
                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          elevation: 0,
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.transparent,
                          content: AwesomeSnackbarContent(
                            title: 'Gagal!',
                            message: result['message'],
                            contentType: ContentType.failure,
                          ),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Verifikasi'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: AwesomeSnackbarContent(
              title: 'Error!',
              message: 'Gagal mengirim kode OTP: $e',
              contentType: ContentType.failure,
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildOTPInput() {
    final defaultPinTheme = PinTheme(
      width: 45,
      height: 45,
      textStyle: const TextStyle(
        fontSize: 20,
        color: Colors.black,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.transparent),
      ),
    );

    return Pinput(
      length: 8,
      controller: _otpController,
      defaultPinTheme: defaultPinTheme,
      focusedPinTheme: defaultPinTheme.copyWith(
        decoration: defaultPinTheme.decoration!.copyWith(
          border: Border.all(color: Colors.grey),
        ),
      ),
      submittedPinTheme: defaultPinTheme,
      errorPinTheme: defaultPinTheme.copyWith(
        decoration: defaultPinTheme.decoration!.copyWith(
          border: Border.all(color: Colors.red),
        ),
      ),
      onChanged: (value) {
        setState(() {});
      },
    );
  }

  Future<void> _register() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty ||
        _nikController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: 'Perhatian!',
            message: 'Harap isi semua field',
            contentType: ContentType.warning,
          ),
        ),
      );
      return;
    }

    if (_nikController.text.length != 16) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: 'Perhatian!',
            message: 'NIK harus 16 digit',
            contentType: ContentType.warning,
          ),
        ),
      );
      return;
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(_nikController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: 'Perhatian!',
            message: 'NIK hanya boleh berisi angka',
            contentType: ContentType.warning,
          ),
        ),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: 'Perhatian!',
            message: 'Password tidak cocok',
            contentType: ContentType.warning,
          ),
        ),
      );
      return;
    }

    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: 'Perhatian!',
            message: 'Password harus minimal 6 karakter',
            contentType: ContentType.warning,
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await DatabaseService.register(
        _nikController.text,
        _emailController.text,
        _passwordController.text,
        _nameController.text,
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        if (mounted) {
          await _showOTPDialog();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              elevation: 0,
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.transparent,
              content: AwesomeSnackbarContent(
                title: 'Gagal!',
                message: result['message'],
                contentType: ContentType.failure,
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: AwesomeSnackbarContent(
              title: 'Error!',
              message: e.toString(),
              contentType: ContentType.failure,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            FadeInDown(
              duration: Duration(milliseconds: 800),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.4,
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage('assets/images/shape-2.png'),
                        fit: BoxFit.fill)),
                child: Stack(
                  children: <Widget>[
                    Positioned(
                      left: MediaQuery.of(context).size.width * 0.06,
                      top: MediaQuery.of(context).size.height * 0.03,
                      width: MediaQuery.of(context).size.width * 0.3,
                      height: MediaQuery.of(context).size.height * 0.25,
                      child: FadeInDown(
                        duration: Duration(milliseconds: 1400),
                        child: Container(
                          alignment: Alignment.center,
                          child: AnalogClock(
                            size: MediaQuery.of(context).size.width * 0.45,
                            hourHandColor: Colors.white,
                            minuteHandColor: Colors.white,
                            secondHandColor: Colors.white,
                            borderColor: Colors.white,
                            numberColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: MediaQuery.of(context).size.width * 0.07,
                      width: MediaQuery.of(context).size.width * 0.17,
                      height: MediaQuery.of(context).size.height * 0.15,
                      child: FadeInDown(
                          duration: Duration(milliseconds: 1000),
                          child: Container(
                            decoration: BoxDecoration(
                                image: DecorationImage(
                                    image: AssetImage(
                                        'assets/images/lamp-1.png'))),
                          )),
                    ),
                    Positioned(
                      right: MediaQuery.of(context).size.width * 0.28,
                      width: MediaQuery.of(context).size.width * 0.17,
                      height: MediaQuery.of(context).size.height * 0.19,
                      child: FadeInDown(
                          duration: Duration(milliseconds: 1200),
                          child: Container(
                            decoration: BoxDecoration(
                                image: DecorationImage(
                                    image: AssetImage(
                                        'assets/images/lamp-2.png'))),
                          )),
                    ),
                    Positioned(
                      child: FadeInDown(
                          duration: Duration(milliseconds: 1600),
                          child: Container(
                            margin: EdgeInsets.only(
                                top: MediaQuery.of(context).size.height * 0.12),
                            child: Center(
                              child: Text(
                                "Register",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.09,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          )),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.08),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  FadeInDown(
                    duration: Duration(milliseconds: 1800),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Nama Lengkap',
                          prefixIcon: Icon(Icons.person),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal:
                                MediaQuery.of(context).size.width * 0.05,
                            vertical: MediaQuery.of(context).size.height * 0.02,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  FadeInDown(
                    duration: Duration(milliseconds: 2000),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextField(
                        controller: _nikController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'NIK',
                          prefixIcon: Icon(Icons.badge),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal:
                                MediaQuery.of(context).size.width * 0.05,
                            vertical: MediaQuery.of(context).size.height * 0.02,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  FadeInDown(
                    duration: Duration(milliseconds: 2200),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal:
                                MediaQuery.of(context).size.width * 0.05,
                            vertical: MediaQuery.of(context).size.height * 0.02,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  FadeInDown(
                    duration: Duration(milliseconds: 2400),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextField(
                        controller: _passwordController,
                        obscureText: _obscureText,
                        decoration: InputDecoration(
                          hintText: 'Kata Sandi',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal:
                                MediaQuery.of(context).size.width * 0.05,
                            vertical: MediaQuery.of(context).size.height * 0.02,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  FadeInDown(
                    duration: Duration(milliseconds: 2600),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmText,
                        decoration: InputDecoration(
                          hintText: 'Konfirmasi Kata Sandi',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmText
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmText = !_obscureConfirmText;
                              });
                            },
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal:
                                MediaQuery.of(context).size.width * 0.05,
                            vertical: MediaQuery.of(context).size.height * 0.02,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                  FadeInDown(
                    duration: Duration(milliseconds: 2800),
                    child: SizedBox(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.06,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF053149),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.025,
                                width:
                                    MediaQuery.of(context).size.height * 0.025,
                                child: const LoadingIndicator(
                                  indicatorType: Indicator.ballPulse,
                                  colors: [Colors.white],
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Daftar',
                                style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.04,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                  FadeInDown(
                    duration: Duration(milliseconds: 3000),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Sudah punya akun? ',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: MediaQuery.of(context).size.width * 0.035,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, '/login');
                          },
                          child: Text(
                            'Masuk di sini',
                            style: TextStyle(
                              color: Color(0xFF053149),
                              fontWeight: FontWeight.bold,
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.035,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
