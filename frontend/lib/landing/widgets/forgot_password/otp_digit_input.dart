import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/colors.dart';

/// OTP digit input widget with 6 individual boxes
class OtpDigitInput extends StatefulWidget {
  final Function(String) onOtpChanged;
  final bool isLoading;
  final Function(OtpDigitInputController)? onControllerReady;

  const OtpDigitInput({
    super.key,
    required this.onOtpChanged,
    required this.isLoading,
    this.onControllerReady,
  });

  @override
  State<OtpDigitInput> createState() => _OtpDigitInputState();
}

class OtpDigitInputController {
  final List<TextEditingController> _controllers;
  final List<FocusNode> _focusNodes;

  OtpDigitInputController(this._controllers, this._focusNodes);

  String getOtp() {
    return _controllers.map((c) => c.text).join();
  }

  void clearOtp() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }
}

class _OtpDigitInputState extends State<OtpDigitInput> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  late OtpDigitInputController _controller;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(6, (index) => TextEditingController());
    _focusNodes = List.generate(6, (index) => FocusNode());
    _controller = OtpDigitInputController(_controllers, _focusNodes);
    widget.onControllerReady?.call(_controller);
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _handleInput(String value, int index) {
    if (value.isEmpty) {
      // Handle backspace
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    } else if (value.length == 1 && value.isNotEmpty) {
      // Move to next field if input is valid
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Last field - unfocus
        _focusNodes[index].unfocus();
      }
      _notifyOtpChange();
    }
  }

  void _notifyOtpChange() {
    final otp = _controllers.map((c) => c.text).join();
    widget.onOtpChanged(otp);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Calculate box size: (available width - spacing) / 6
    final availableWidth = screenWidth - 28; // Account for reduced modal padding (12*2 + 4 margin)
    final boxSize = availableWidth / 6;
    final finalBoxSize = boxSize > 50 ? 50.0 : boxSize < 28 ? 28.0 : boxSize;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Enter 6-digit code',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              6,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: SizedBox(
                  width: finalBoxSize,
                  height: finalBoxSize,
                  child: TextFormField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    enabled: !widget.isLoading,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: finalBoxSize > 40 ? 16 : 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: EdgeInsets.all(finalBoxSize > 40 ? 4 : 2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide(
                          color: AppColors.primaryBlue,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    onChanged: (value) => _handleInput(value, index),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
