import 'package:flutter/material.dart';
import 'package:food_app/screens/home_screen.dart';
import 'admin/admin_screen.dart';
import 'package:food_app/data/account_data.dart';
import 'package:food_app/models/account.dart';
import 'package:food_app/screens/RegisterScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // ─── Palette (warm food theme) ───────────────────────────
  static const _bg1 = Color(0xFF1A0A00);
  static const _bg2 = Color(0xFF2D1200);
  static const _accent = Color(0xFFFF6B00);
  static const _accentEnd = Color(0xFFFF9500);
  static const _text = Colors.white;
  static const _textMuted = Color(0xFFAA8866);
  static const _border = Color(0xFF4A2800);

  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _hidePassword = true;
  bool _isLoading = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _isLoading = false);

    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    try {
      final UserModel user = mockUsers.firstWhere(
        (u) => u.username == username && u.password == password,
      );

      if (user.role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.error_rounded, color: Colors.white),
            SizedBox(width: 10),
            Text("Sai tài khoản hoặc mật khẩu",
                style: TextStyle(fontWeight: FontWeight.w600)),
          ]),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.orange.shade50,
    body: Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    const Icon(
                      Icons.fastfood,
                      size: 90,
                      color: Colors.orange,
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "ĐĂNG NHẬP",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 30),

                    TextFormField(
                      controller: _usernameCtrl,
                      decoration: InputDecoration(
                        labelText: "Username",
                        prefixIcon:
                            const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(15),
                        ),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return "Vui lòng nhập username";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _hidePassword,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon:
                            const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _hidePassword =
                                  !_hidePassword;
                            });
                          },
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(15),
                        ),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty) {
                          return "Vui lòng nhập password";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed:
                            _isLoading ? null : _login,
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.orange,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                                    15),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color:
                                      Colors.white,
                                ),
                              )
                            : const Text(
                                "Đăng nhập",
                                style: TextStyle(
                                  fontSize: 18,
                                  color:
                                      Colors.white,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Chưa có tài khoản?",
                        ),
                        TextButton(
                          onPressed:
                              _goToRegister,
                          child: const Text(
                            "Đăng ký",
                            style: TextStyle(
                              color:
                                  Colors.orange,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "Admin: admin / 123456\nUser: user / 123456",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
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
  );
}

  Widget _label(String text) => Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _text.withOpacity(0.65),
          letterSpacing: 0.2,
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: _text, fontSize: 15),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _text.withOpacity(0.28), fontSize: 14),
        prefixIcon: Icon(icon, color: _textMuted, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        errorStyle: const TextStyle(color: Color(0xFFEF4444), fontSize: 11),
      ),
    );
  }
}