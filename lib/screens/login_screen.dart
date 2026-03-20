
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  final AuthService _authService = AuthService();
  String? _errorMessage;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// Runs [authAction] with loading state and error handling.
  Future<void> _handleAuth(Future<void> Function() authAction, String errorPrefix) async {
    setState(() {
      isLoading = true;
      _errorMessage = null;
    });
    try {
      await authAction();
      // TODO: Navigate to home/profile screen
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '$errorPrefix: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F2027), Color(0xFF2C5364)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Text(
                    'Voom',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent.shade400,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(
                          blurRadius: 16,
                          color: Colors.cyanAccent.shade400,
                          offset: Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  _buildTextField(
                    controller: emailController,
                    hint: 'Email',
                    icon: Icons.email,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: passwordController,
                    hint: 'Password',
                    icon: Icons.lock,
                    obscure: true,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {},
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildNeonButton(
                    text: 'Sign In',
                    onTap: _handleEmailSignIn,
                  ),
                  const SizedBox(height: 16),
                  _buildNeonButton(
                    text: 'Sign in with Google',
                    onTap: _handleGoogleSignIn,
                    icon: Icons.g_mobiledata,
                  ),
                  const SizedBox(height: 16),
                  _buildNeonButton(
                    text: 'Sign in with Apple',
                    onTap: _handleAppleSignIn,
                    icon: Icons.apple,
                  ),
                  const SizedBox(height: 16),
                  _buildNeonButton(
                    text: 'Continue as Guest',
                    onTap: _handleGuestSignIn,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleEmailSignIn() async {
    await _handleAuth(
      () => _authService.signInWithEmail(
        emailController.text.trim(),
        passwordController.text.trim(),
      ),
      'Email sign in failed',
    );
  }

  Future<void> _handleGoogleSignIn() async {
    await _handleAuth(
      () => _authService.signInWithGoogle(),
      'Google sign in failed',
    );
  }

  Future<void> _handleAppleSignIn() async {
    await _handleAuth(
      () => _authService.signInWithApple(),
      'Apple sign in failed',
    );
  }

  Future<void> _handleGuestSignIn() async {
    await _handleAuth(
      () => _authService.signInAnonymously(),
      'Guest sign in failed',
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.cyanAccent),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildNeonButton({
    required String text,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.6),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 1.2,
                shadows: [
                  Shadow(
                    blurRadius: 8,
                    color: Colors.cyanAccent,
                    offset: Offset(0, 0),
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
