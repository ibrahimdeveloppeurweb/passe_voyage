import 'package:flutter/material.dart';
import '../../widgets/custom_numpad.dart';
import '../../../config/routes.dart';
import '../../../core/theme/app_colors.dart';

class OtpValidationScreen extends StatefulWidget {
  final String phoneNumber;
  
  const OtpValidationScreen({Key? key, required this.phoneNumber}) : super(key: key);

  @override
  State<OtpValidationScreen> createState() => _OtpValidationScreenState();
}

class _OtpValidationScreenState extends State<OtpValidationScreen> {
  String _otpCode = '';

  void _onKeyPressed(String value) {
    if (_otpCode.length < 4) {
      setState(() {
        _otpCode += value;
      });
      
      // Auto-validate and navigate when 4 digits are entered
      if (_otpCode.length == 4) {
        Future.delayed(const Duration(milliseconds: 200), () {
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.pinEntry,
            arguments: {'phoneNumber': widget.phoneNumber},
          );
        });
      }
    }
  }

  void _onDelete() {
    if (_otpCode.isNotEmpty) {
      setState(() {
        _otpCode = _otpCode.substring(0, _otpCode.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            
            // Icon Bubble
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary, // Purple color from screenshot
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.chat_bubble,
                color: Colors.white,
                size: 24,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Text Message
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                'Entrez le code de validation envoyé\npar SMS au ${widget.phoneNumber}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  height: 1.3,
                ),
              ),
            ),
            
            const Spacer(),
            
            // 4 Digit Slots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                bool isActive = index == _otpCode.length;
                bool isFilled = index < _otpCode.length;

                return Container(
                  width: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isActive ? AppColors.primary : Colors.black54,
                        width: isActive ? 2.0 : 1.5,
                      ),
                    ),
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.only(bottom: 8),
                  child: isFilled
                      ? Text(
                          _otpCode[index],
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        )
                      : isActive
                          ? Container(
                              width: 2,
                              height: 32,
                              color: AppColors.primary,
                            )
                          : const SizedBox(height: 32),
                );
              }),
            ),
            
            const Spacer(),
            
            // Resend SMS Button
            TextButton(
              onPressed: () {
                // TODO: Implement resend logic
              },
              child: Text(
                'Renvoyer SMS',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Custom Numpad
            CustomNumpad(
              onKeyPressed: _onKeyPressed,
              onDelete: _onDelete,
            ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
