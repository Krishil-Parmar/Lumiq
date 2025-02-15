import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';

class AnimatedLoginCharacter extends StatefulWidget {
  final bool isHandsUp;
  final bool isChecking;

  const AnimatedLoginCharacter({
    super.key,
    required this.isHandsUp,
    required this.isChecking,
  });

  @override
  _AnimatedLoginCharacterState createState() => _AnimatedLoginCharacterState();
}

class _AnimatedLoginCharacterState extends State<AnimatedLoginCharacter> {
  Artboard? _artboard;
  SMIBool? _isHandsUpInput;
  SMIBool? _isCheckingInput;

  @override
  void initState() {
    super.initState();
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
        debugPrint(
            "❌ State Machine 'Login Machine' not found in the Rive file.");
        return;
      }

      artboard.addController(controller);
      _isHandsUpInput = controller.findInput<bool>('isHandsUp') as SMIBool?;
      _isCheckingInput = controller.findInput<bool>('isChecking') as SMIBool?;

      _isHandsUpInput?.value = widget.isHandsUp;
      _isCheckingInput?.value = widget.isChecking;

      setState(() {
        _artboard = artboard;
      });
    } catch (e) {
      debugPrint("❌ Error loading Rive animation: $e");
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedLoginCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isHandsUpInput != null && oldWidget.isHandsUp != widget.isHandsUp) {
      _isHandsUpInput!.value = widget.isHandsUp;
    }
    if (_isCheckingInput != null && oldWidget.isChecking != widget.isChecking) {
      _isCheckingInput!.value = widget.isChecking;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _artboard != null
        ? Rive(artboard: _artboard!, fit: BoxFit.contain)
        : SizedBox(
            height: 250,
            width: 250,
            child: Center(child: CircularProgressIndicator()),
          );
  }
}
