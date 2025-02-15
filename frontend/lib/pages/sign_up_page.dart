import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/network_service.dart';
import 'home.dart';

const Color kLoginSignUpBg = Color(0xFFD9E2EC);

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FocusNode passwordFocus = FocusNode();
  final FocusNode emailFocus = FocusNode();
  final FocusNode nameFocus = FocusNode();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isPasswordFocused = false;
  bool isEmailFocused = false;
  bool isNameFocused = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _errorMessage = '';

  Artboard? _artboard;
  SMIBool? _isHandsUpInput;
  SMIBool? _isCheckingInput;
  SMINumber? _numLookInput;

  @override
  void initState() {
    super.initState();
    passwordFocus.addListener(() {
      setState(() {
        isPasswordFocused = passwordFocus.hasFocus;
        _isHandsUpInput?.value = passwordFocus.hasFocus && _obscurePassword;
      });
    });
    emailFocus.addListener(() {
      setState(() {
        isEmailFocused = emailFocus.hasFocus;
        _isCheckingInput?.value = emailFocus.hasFocus;
      });
    });
    nameFocus.addListener(() {
      setState(() {
        isNameFocused = nameFocus.hasFocus;
        _isCheckingInput?.value = nameFocus.hasFocus || emailFocus.hasFocus;
      });
    });
    _loadRiveFile();
  }

  Future<void> _loadRiveFile() async {
    try {
      final data = await rootBundle.load('assets/animated_login_character.riv');
      final file = RiveFile.import(data);
      final artboard = file.mainArtboard;
      final controller =
          StateMachineController.fromArtboard(artboard, 'Login Machine');
      if (controller == null) {
        debugPrint("State Machine 'Login Machine' not found in the Rive file.");
        return;
      }
      artboard.addController(controller);
      _isHandsUpInput = controller.findInput<bool>('isHandsUp') as SMIBool?;
      _isCheckingInput = controller.findInput<bool>('isChecking') as SMIBool?;
      final rawNumLook = controller.findInput<double>('numLook');
      if (rawNumLook is SMINumber) {
        _numLookInput = rawNumLook;
      }
      _isHandsUpInput?.value = isPasswordFocused && _obscurePassword;
      _isCheckingInput?.value = isEmailFocused || isNameFocused;
      setState(() {
        _artboard = artboard;
      });
    } catch (e) {
      debugPrint("Error loading Rive file in SignUpPage: $e");
    }
  }

  @override
  void dispose() {
    passwordFocus.dispose();
    emailFocus.dispose();
    nameFocus.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String name = nameController.text.trim();

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      setState(() {
        _errorMessage = "All fields are required.";
        _isLoading = false;
      });
      return;
    }

    try {
      Map<String, dynamic> response =
          await NetworkService.signUp(email, password);

      if (response.containsKey("uid")) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("uid", response["uid"]);

        Navigator.pushReplacement(
          context,
          // Removed const before DashboardScreen if its constructor isn’t const.
          MaterialPageRoute(builder: (context) => DashboardScreen()),
        );
      } else {
        setState(() {
          _errorMessage = response["error"] ?? "Sign-up failed. Try again.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "An error occurred. Please try again.";
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isChecking = isNameFocused || isEmailFocused;
    _isHandsUpInput?.value = isPasswordFocused && _obscurePassword;
    _isCheckingInput?.value = isChecking;

    return Scaffold(
      backgroundColor: kLoginSignUpBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: Transform.translate(
                offset: const Offset(0, 30),
                child: _artboard != null
                    ? Rive(artboard: _artboard!, fit: BoxFit.contain)
                    : const Center(child: CircularProgressIndicator()),
              ),
            ),
            const SizedBox(height: 120),
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                child: _buildTextField(
                  icon: Icons.person,
                  hintText: 'Name',
                  focusNode: nameFocus,
                  obscureText: false,
                  controller: nameController,
                ),
              ),
            ),
            const SizedBox(height: 25),
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                child: _buildTextField(
                  icon: Icons.email,
                  hintText: 'Email',
                  focusNode: emailFocus,
                  obscureText: false,
                  controller: emailController,
                ),
              ),
            ),
            const SizedBox(height: 25),
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                child: _buildTextField(
                  icon: Icons.lock,
                  hintText: 'Password',
                  focusNode: passwordFocus,
                  obscureText: _obscurePassword,
                  controller: passwordController,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Switch(
                    value: !_obscurePassword,
                    onChanged: (value) {
                      setState(() {
                        _obscurePassword = !value;
                        _isHandsUpInput?.value =
                            passwordFocus.hasFocus && _obscurePassword;
                      });
                    },
                  ),
                  const Text(
                    'Show Password',
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 20),
                    textStyle: const TextStyle(fontSize: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _isLoading ? null : _signUp,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text('Sign Up'),
                ),
              ),
            ),
            if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper method for text fields
  Widget _buildTextField({
    required IconData icon,
    required String hintText,
    required bool obscureText,
    required FocusNode focusNode,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.black),
      focusNode: focusNode,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: hintText,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        prefixIcon: Icon(icon, color: Colors.black),
      ),
    );
  }
}
