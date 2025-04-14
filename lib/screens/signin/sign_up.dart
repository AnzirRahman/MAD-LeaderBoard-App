import 'package:cloud_firestore/cloud_firestore.dart'; // Add Firestore import
import 'package:flutter/material.dart';
import 'package:leaderboard_app/services/auth_service.dart';
import 'package:leaderboard_app/shared/colors.dart';
import 'package:leaderboard_app/screens/signin/signup_success.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;
  String? _selectedRole;

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> _isValidAdminOrFaculty(String email, String role) async {
    if (role != 'admin' && role != 'faculty') {
      return true; // No validation needed for students
    }

    try {
      // Query the users collection for the email
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .where('role', isEqualTo: role)
          .limit(1)
          .get();

      // Return true if a matching document is found
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking predefined user: $e');
      return false;
    }
  }

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _emailError = null;
        _passwordError = null;
      });

      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() {
          _passwordError = 'Passwords do not match';
          _isLoading = false;
        });
        return;
      }

      if (_selectedRole == null) {
        setState(() {
          _emailError = 'Please select a role';
          _isLoading = false;
        });
        return;
      }

      final email = _emailController.text.trim();
      final role = _selectedRole!;

      // Check if the email and role are valid for admin or faculty
      final isValidRole = await _isValidAdminOrFaculty(email, role);
      if (!isValidRole) {
        setState(() {
          _emailError = 'This email is not authorized for the selected role';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final password = _passwordController.text.trim();
      final name = _nameController.text.trim();
      final designation = _designationController.text.trim();

      try {
        final appUser = await AuthService.signUp(
          email,
          password,
          role,
          name,
          designation,
        );

        setState(() {
          _isLoading = false;
        });

        if (appUser != null) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const SignUpSuccessScreen(),
              ),
            );
          }
        }
      } on Exception catch (e) {
        setState(() {
          _isLoading = false;
          if (e.toString().contains('The email address is already in use')) {
            _emailError =
                'The email address is already in use by another account.';
          } else {
            _emailError = 'An error occurred during sign-up. Please try again.';
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {'/signup': (context) => const SignUpForm()},
      home: Scaffold(
        backgroundColor: AppColors.primaryBgColor,
        appBar: AppBar(
          backgroundColor: AppColors.secondaryAccentColor,
          title: const Text('Sign Up'),
          centerTitle: true,
        ),
        body: _isLoading
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
                          const Text(
                            'Create an Account',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(
                                Icons.person,
                                color: AppColors.secondaryAccentColor,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Select Role',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(
                                Icons.group,
                                color: AppColors.secondaryAccentColor,
                              ),
                            ),
                            value: _selectedRole,
                            items: ['student', 'faculty', 'admin']
                                .map((role) => DropdownMenuItem(
                                      value: role,
                                      child: Text(role.capitalize()),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedRole = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a role';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _designationController,
                            decoration: const InputDecoration(
                              labelText: 'Designation (Optional for Students & Admin)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(
                                Icons.work,
                                color: AppColors.secondaryAccentColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
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
                              errorText: _emailError,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                              if (!emailRegex.hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
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
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
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
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
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
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                              errorText: _passwordError,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondaryAccentColor,
                              foregroundColor: AppColors.primaryBgColor,
                            ),
                            onPressed: _handleSignUp,
                            child: const Text('Sign Up'),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              "Already have an account? Sign In",
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
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}