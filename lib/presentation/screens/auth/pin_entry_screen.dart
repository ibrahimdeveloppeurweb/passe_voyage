import 'package:flutter/material.dart';
import '../../widgets/custom_numpad.dart';
import '../../../config/routes.dart';
import '../../../core/theme/app_colors.dart';

class PinEntryScreen extends StatefulWidget {
  final String phoneNumber;
  
  const PinEntryScreen({Key? key, required this.phoneNumber}) : super(key: key);

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  String _pinCode = '';

  void _onKeyPressed(String value) {
    if (_pinCode.length < 4) {
      setState(() {
        _pinCode += value;
      });
      
      // Auto-validate and navigate when 4 digits are entered
      if (_pinCode.length == 4) {
        Future.delayed(const Duration(milliseconds: 200), () {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.dashboard,
            (route) => false, // Remove all previous routes
          );
        });
      }
    }
  }

  void _onDelete() {
    if (_pinCode.isNotEmpty) {
      setState(() {
        _pinCode = _pinCode.substring(0, _pinCode.length - 1);
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
            
            // Lock Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary, // Dark blue from screenshot
                  width: 3,
                ),
              ),
              child: const Icon(
                Icons.lock,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Text Message
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                'Entrez votre code secret pour le\ncompte ${widget.phoneNumber}',
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
            
            // 4 Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _pinCode.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? AppColors.primary : const Color(0xFFB3E5FC), // Light blue for empty, primary for filled
                  ),
                );
              }),
            ),
            
            const Spacer(),
            
            // Custom Numpad with "OUBLIÉ?"
            CustomNumpad(
              onKeyPressed: _onKeyPressed,
              onDelete: _onDelete,
              leftActionKey: InkWell(
                onTap: () {
                  // TODO: Implement forgot PIN logic
                },
                borderRadius: BorderRadius.circular(40),
                child: Container(
                  width: 80,
                  height: 80,
                  alignment: Alignment.center,
                  child: const Text(
                    'OUBLIÉ?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
