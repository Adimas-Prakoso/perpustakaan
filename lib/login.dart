import 'dart:async';
import 'dart:math';

import 'package:animate_do/animate_do.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:pinput/pinput.dart';

import 'package:perpustakaan/services/database_service.dart';
import 'package:perpustakaan/services/email_service.dart';
import 'package:perpustakaan/services/user_preferences.dart';
import 'package:perpustakaan/widgets/analog_clock.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;
  String _currentOTP = '';
  bool _canResendOTP = true;
  int _resendTimer = 60;
  Timer? _timer;
  final ValueNotifier<int> _resendTimerNotifier = ValueNotifier(60);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _timer?.cancel();
    _resendTimerNotifier.dispose();
    super.dispose();
  }

  String _generateOTP() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)])
        .join();
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

  Future<bool> _sendOTP(String email, String otp) async {
    try {
      print('Sending OTP to email: $email with code: $otp');
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
      print('Error in _sendOTP: $e');
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

  Future<void> _showOTPDialog(String email) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() {
      _isLoading = true;
    });

    try {
      print('Generating OTP for email: $email');
      _currentOTP = _generateOTP();
      print('Generated OTP: $_currentOTP');

      bool sent = await _sendOTP(email, _currentOTP);
      print('OTP send result: $sent');

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

      await DatabaseService.updateOTP(email, _currentOTP);
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
                      print('Generating new OTP for email: $email');
                      print('Generated new OTP: $_currentOTP');
                      bool sent = await _sendOTP(email, _currentOTP);
                      print('New OTP send result: $sent');
                      dialogSetState(() => _isLoading = false);

                      if (sent) {
                        await DatabaseService.updateOTP(email, _currentOTP);
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
                    email,
                    _otpController.text,
                  );
                  print('OTP verification result: ${result['success']}');
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
                            message: 'Verifikasi berhasil',
                            contentType: ContentType.success,
                          ),
                        ),
                      );
                      // Proceed with login after verification
                      _login();
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
      print('Error in _showOTPDialog: $e');
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

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
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

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if user exists in temp_users
      final conn = await DatabaseService.getConnection();
      var tempResult = await conn.execute(
        '''
        SELECT email 
        FROM temp_users 
        WHERE email = :email
        ''',
        {'email': _emailController.text},
      );
      await conn.close();

      if (tempResult.numOfRows > 0) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          // Show OTP dialog for unverified users
          await _showOTPDialog(_emailController.text);
        }
        return;
      }

      final user = await DatabaseService.login(
        _emailController.text,
        _passwordController.text,
      );

      if (user != null) {
        await UserPreferences.saveUser(user);
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
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
                message: 'Email atau password salah',
                contentType: ContentType.failure,
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Error in _login: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: AwesomeSnackbarContent(
              title: 'Error!',
              message: 'Error: ${e.toString()}',
              contentType: ContentType.failure,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
                  height: MediaQuery.of(context).size.height * 0.55,
                  decoration: BoxDecoration(
                      image: DecorationImage(
                          image: AssetImage('assets/images/shape.png'),
                          fit: BoxFit.fill)),
                  child: Stack(
                    children: <Widget>[
                      Positioned(
                        left: MediaQuery.of(context).size.width * 0.06,
                        width: MediaQuery.of(context).size.width * 0.22,
                        height: MediaQuery.of(context).size.height * 0.2,
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
                        left: MediaQuery.of(context).size.width * 0.33,
                        width: MediaQuery.of(context).size.width * 0.22,
                        height: MediaQuery.of(context).size.height * 0.25,
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
                        right: MediaQuery.of(context).size.width * 0.07,
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
                        child: FadeInDown(
                            duration: Duration(milliseconds: 1600),
                            child: Container(
                              margin: EdgeInsets.only(
                                  top: MediaQuery.of(context).size.height *
                                      0.18),
                              child: Center(
                                child: Text(
                                  "Login",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                              0.1,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            )),
                      )
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.08),
                child: Column(
                  children: <Widget>[
                    FadeInDown(
                        duration: Duration(milliseconds: 1800),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: TextField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  hintText: 'Email',
                                  prefixIcon: Icon(Icons.email_outlined),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal:
                                        MediaQuery.of(context).size.width *
                                            0.05,
                                    vertical:
                                        MediaQuery.of(context).size.height *
                                            0.02,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: TextField(
                                controller: _passwordController,
                                obscureText: _obscureText,
                                decoration: InputDecoration(
                                  hintText: 'Kata Sandi',
                                  prefixIcon: const Icon(Icons.lock_outline),
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
                                        MediaQuery.of(context).size.width *
                                            0.05,
                                    vertical:
                                        MediaQuery.of(context).size.height *
                                            0.02,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                    FadeInDown(
                      duration: Duration(milliseconds: 2000),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/register'),
                          child: const Text(
                            'Lupa Password?',
                            style: TextStyle(
                              color: Color(0xFF0A2647),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    FadeInDown(
                      duration: Duration(milliseconds: 2200),
                      child: SizedBox(
                        width: double.infinity,
                        height: MediaQuery.of(context).size.height * 0.06,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A2647),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: LoadingIndicator(
                                    indicatorType: Indicator.ballSpinFadeLoader,
                                    colors: [Colors.white],
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    FadeInDown(
                      duration: Duration(milliseconds: 2400),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Belum punya akun? ',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, '/register'),
                            child: const Text(
                              'Daftar di sini',
                              style: TextStyle(
                                color: Color(0xFF0A2647),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ));
  }
}
