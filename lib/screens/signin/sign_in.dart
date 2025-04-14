import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:leaderboard_app/services/auth_service.dart';
import 'package:leaderboard_app/shared/colors.dart';
import 'package:leaderboard_app/screens/signin/sign_up.dart';
import 'package:leaderboard_app/screens/signin/login_success.dart';
import 'package:leaderboard_app/providers/auth_provider.dart';

class SignIn extends ConsumerStatefulWidget {
  const SignIn({super.key});

  @override
  ConsumerState<SignIn> createState() => _SignInState();
}

class _SignInState extends ConsumerState<SignIn> {
  // Form key and controllers
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // State variables
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;

  // Handle sign-in logic
  void _handleSignIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _emailError = null;
        _passwordError = null;
        _isLoading = true;
      });

      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      try {
        final user = await AuthService.signIn(email, password);

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }

        if (user != null) {
          if (mounted) {
            // Navigate to login success screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginSuccessScreen(),
              ),
            );
          }
        }
      } on Exception catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            if (e.toString().contains('authentication credential')) {
              _passwordError = 'Wrong password or email.';
            }
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginSuccessScreen(),
              ),
            );
          });
        }
        return MaterialApp(
          debugShowCheckedModeBanner: false, // Disable debug banner
          routes: {'/signin': (context) => const SignIn()},
          home: Scaffold(
            backgroundColor: AppColors.primaryBgColor,
            body:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Center(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Title
                                const Text(
                                  'Student Login',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),

                                // Email field
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    border: const OutlineInputBorder(),
                                    prefixIcon: Icon(
                                      Icons.email,
                                      color: AppColors.secondaryAccentColor,
                                    ),
                                    errorText:
                                        _emailError, // Dynamically set error
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    final emailRegex = RegExp(
                                      r'^[^@]+@[^@]+\.[^@]+',
                                    );
                                    if (!emailRegex.hasMatch(value)) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Password field
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: !_isPasswordVisible,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    border: const OutlineInputBorder(),
                                    prefixIcon: Icon(
                                      Icons.lock,
                                      color: AppColors.secondaryAccentColor,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordVisible
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: AppColors.secondaryAccentColor,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordVisible =
                                              !_isPasswordVisible;
                                        });
                                      },
                                    ),
                                    errorText:
                                        _passwordError, // Dynamically set error
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters long';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Sign-in button
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        AppColors.secondaryAccentColor,
                                    foregroundColor: AppColors.primaryBgColor,
                                  ),
                                  onPressed: _handleSignIn,
                                  child: const Text('Sign In'),
                                ),
                                const SizedBox(height: 10),

                                // Navigate to sign-up page
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => const SignUpForm(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    "Don't have an account? Sign Up",
                                    style: TextStyle(
                                      color: AppColors.secondaryAccentColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
}
