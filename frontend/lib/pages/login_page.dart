import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/network_service.dart';
import 'home.dart';

const Color kLoginSignUpBg = Color(0xFFD9E2EC);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FocusNode passwordFocus = FocusNode();
  final FocusNode emailFocus = FocusNode();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isEmailFocused = false;
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
    emailFocus.addListener(() {
      setState(() {
        isEmailFocused = emailFocus.hasFocus;
        _isCheckingInput?.value = isEmailFocused;
      });
    });

    passwordFocus.addListener(() {
      setState(() {
        _isHandsUpInput?.value = passwordFocus.hasFocus && _obscurePassword;
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
      _isHandsUpInput?.value = passwordFocus.hasFocus && _obscurePassword;
      _isCheckingInput?.value = isEmailFocused;
      setState(() {
        _artboard = artboard;
      });
    } catch (e) {
      debugPrint("Error loading Rive file in LoginPage: $e");
    }
  }

  @override
  void dispose() {
    passwordFocus.dispose();
    emailFocus.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = "Please enter your email and password.";
        _isLoading = false;
      });
      return;
    }

    try {
      // Ensure you are calling the correctly named method from NetworkService.
      Map<String, dynamic> response =
          await NetworkService.signIn(email, password);

      if (response.containsKey("uid")) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("uid", response["uid"]);

        Navigator.pushReplacement(
          context,
          // Removed const before DashboardScreen if its constructor is not const.
          MaterialPageRoute(builder: (context) => DashboardScreen()),
        );
      } else {
        setState(() {
          _errorMessage = response["error"] ?? "Login failed. Try again.";
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
    _isHandsUpInput?.value = passwordFocus.hasFocus && _obscurePassword;
    _isCheckingInput?.value = isEmailFocused;

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
                child: TextField(
                  controller: emailController,
                  style: const TextStyle(color: Colors.black),
                  focusNode: emailFocus,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                    ),
                    prefixIcon: Icon(Icons.email, color: Colors.black),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                child: TextField(
                  controller: passwordController,
                  style: const TextStyle(color: Colors.black),
                  focusNode: passwordFocus,
                  obscureText: _obscurePassword,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                    ),
                    prefixIcon: Icon(Icons.lock, color: Colors.black),
                  ),
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
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text('Log In'),
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
}
