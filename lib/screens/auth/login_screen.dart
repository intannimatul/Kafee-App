import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../home/home_screen.dart';
import 'signup_screen.dart';
import '../admin/admin_home_screen.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final String? prefillEmail;
  const LoginScreen({super.key, this.prefillEmail});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailC = TextEditingController();
  final _passC = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    //auto isi email kalau dikirim dari SignUp
    final prefill = widget.prefillEmail;
    if (prefill != null && prefill.trim().isNotEmpty) {
      _emailC.text = prefill.trim();
    }
  }

  void _goToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _goToSignUp() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SignUpScreen()),
    );
  }

  //biar error "Exception: ..." jadi rapi
  String _prettyError(Object e) {
    final s = e.toString();
    return s.replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final email = _emailC.text.trim();
      final pass = _passC.text;

      if (email.isEmpty || pass.isEmpty) {
        throw Exception("Email dan password wajib diisi.");
      }

      final data = await AuthService().login(email: email, password: pass);

      //ambil role dari response backend
      final role = (data['user']?['role'] ?? 'user').toString();

      if (!mounted) return;

      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
        );
      } else {
        _goToHome();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _prettyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailC.dispose();
    _passC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // HEADER FOTO
          ClipPath(
            clipper: TopCurveClipper(),
            child: Container(
              height: 255,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/header_bg.jpeg'),
                  fit: BoxFit.cover,
                  alignment: Alignment(0, -1.35),
                ),
              ),
            ),
          ),

          // DEKORASI
          Positioned(
            bottom: -8,
            left: -10,
            child: Image.asset('assets/images/coffee_beans.png', width: 170),
          ),
          Positioned(
            bottom: -10,
            right: -12,
            child: Image.asset('assets/images/chocolate.png', width: 185),
          ),

          // MAIN CONTENT
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 125),

                const Text(
                  "K A F E E",
                  style: TextStyle(
                    fontSize: 28,
                    letterSpacing: 5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Crafting moments, one cup at a time",
                  style: TextStyle(fontSize: 12, color: AppColors.textDark),
                ),

                const SizedBox(height: 20),

                // ========== LOGIN CARD ==========
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    children: [
                      // ========= TAB LOGIN / SIGNUP =========
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: AppColors.primary),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.only(right: 4),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(26),
                                ),
                                child: const Center(
                                  child: Text(
                                    "Login",
                                    style: TextStyle(
                                      color: AppColors.textLight,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(26),
                                onTap: _goToSignUp,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  child: const Center(
                                    child: Text(
                                      "Sign Up",
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      if (_error != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // INPUT EMAIL
                      TextField(
                        controller: _emailC,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: "Email",
                          labelStyle: TextStyle(color: AppColors.primary),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // INPUT PASSWORD
                      TextField(
                        controller: _passC,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Password",
                          labelStyle: TextStyle(color: AppColors.primary),
                          suffixIcon: Icon(
                            Icons.visibility_off,
                            color: AppColors.primary,
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "Forgot password?",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // LOGIN BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _loading ? null : _handleLogin,
                          child: _loading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "Login",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textLight,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 90),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// CLIPPER HEADER
class TopCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    path.lineTo(0, size.height - 85);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 85,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
