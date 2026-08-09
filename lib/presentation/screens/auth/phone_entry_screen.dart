import 'package:flutter/material.dart';
import '../../widgets/custom_numpad.dart';
import '../../../config/routes.dart';
import '../../../core/theme/app_colors.dart';

class PhoneEntryScreen extends StatefulWidget {
  const PhoneEntryScreen({Key? key}) : super(key: key);

  @override
  State<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends State<PhoneEntryScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // Selected country state
  String _selectedFlag = '🇨🇮';
  String _selectedCode = '+225';
  int _maxLength = 10;
  String _currentHint = '0X XX XX XX XX';
  String _rawPhoneNumber = '';

  final List<Map<String, dynamic>> _countries = [
    {'name': 'Burkina Faso', 'code': '+226', 'flag': '🇧🇫', 'length': 8, 'hint': 'XX XX XX XX'},
    {'name': 'Cameroun', 'code': '+237', 'flag': '🇨🇲', 'length': 9, 'hint': 'X XX XX XX XX'},
    {'name': 'Congo-Kinshasa', 'code': '+243', 'flag': '🇨🇩', 'length': 9, 'hint': 'X XX XX XX XX'},
    {'name': 'Côte d\'Ivoire', 'code': '+225', 'flag': '🇨🇮', 'length': 10, 'hint': '0X XX XX XX XX'},
    {'name': 'Gambie', 'code': '+220', 'flag': '🇬🇲', 'length': 7, 'hint': 'XXX XXXX'},
    {'name': 'Guinée', 'code': '+224', 'flag': '🇬🇳', 'length': 9, 'hint': 'X XX XX XX XX'},
    {'name': 'Malawi', 'code': '+265', 'flag': '🇲🇼', 'length': 9, 'hint': 'X XX XX XX XX'},
    {'name': 'Mali', 'code': '+223', 'flag': '🇲🇱', 'length': 8, 'hint': 'XX XX XX XX'},
    {'name': 'Niger', 'code': '+227', 'flag': '🇳🇪', 'length': 8, 'hint': 'XX XX XX XX'},
    {'name': 'Ouganda', 'code': '+256', 'flag': '🇺🇬', 'length': 9, 'hint': 'X XX XX XX XX'},
    {'name': 'Sierra Leone', 'code': '+232', 'flag': '🇸🇱', 'length': 8, 'hint': 'XX XX XX XX'},
    {'name': 'Sénégal', 'code': '+221', 'flag': '🇸🇳', 'length': 9, 'hint': '7X XXX XX XX'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _formatPhoneNumber(String digits) {
    if (digits.isEmpty) return '';
    String result = '';
    int digitIndex = 0;
    for (int i = 0; i < _currentHint.length; i++) {
      if (digitIndex >= digits.length) break;
      if (_currentHint[i] == ' ') {
        result += ' ';
      } else {
        result += digits[digitIndex];
        digitIndex++;
      }
    }
    return result;
  }

  int _getCursorPositionInFormatted(String formattedText, int digitIndex) {
    int count = 0;
    for (int i = 0; i < formattedText.length; i++) {
      if (count == digitIndex) return i;
      if (formattedText[i] != ' ') {
        count++;
      }
    }
    return formattedText.length;
  }

  void _onKeyPressed(String value) {
    if (_rawPhoneNumber.length < _maxLength) {
      setState(() {
        int cursorPosition = _controller.selection.baseOffset;
        if (cursorPosition == -1) cursorPosition = _controller.text.length;
        
        String textBeforeCursor = _controller.text.substring(0, cursorPosition);
        int digitCursorPos = textBeforeCursor.replaceAll(' ', '').length;
        
        _rawPhoneNumber = _rawPhoneNumber.substring(0, digitCursorPos) + value + _rawPhoneNumber.substring(digitCursorPos);
        
        String newText = _formatPhoneNumber(_rawPhoneNumber);
        int newCursorPosition = _getCursorPositionInFormatted(newText, digitCursorPos + 1);
        
        _controller.text = newText;
        _controller.selection = TextSelection.collapsed(offset: newCursorPosition);
      });
    }
  }

  void _onDelete() {
    setState(() {
      int cursorPosition = _controller.selection.baseOffset;
      if (cursorPosition == -1) cursorPosition = _controller.text.length;
      
      if (cursorPosition == 0) return;
      
      // If we are about to delete a space, jump back to delete the digit before it
      if (_controller.text[cursorPosition - 1] == ' ') {
        cursorPosition--;
      }
      if (cursorPosition == 0) return;
      
      String textBeforeCursor = _controller.text.substring(0, cursorPosition);
      int digitCursorPos = textBeforeCursor.replaceAll(' ', '').length;
      
      if (digitCursorPos > 0) {
        _rawPhoneNumber = _rawPhoneNumber.substring(0, digitCursorPos - 1) + _rawPhoneNumber.substring(digitCursorPos);
        
        String newText = _formatPhoneNumber(_rawPhoneNumber);
        int newCursorPosition = _getCursorPositionInFormatted(newText, digitCursorPos - 1);
        
        _controller.text = newText;
        _controller.selection = TextSelection.collapsed(offset: newCursorPosition);
      }
    });
  }

  void _onNext() {
    // Check if entered length matches expected length for selected country
    if (_rawPhoneNumber.length == _maxLength) {
      Navigator.pushNamed(
        context,
        AppRoutes.otpValidation,
        arguments: {'phoneNumber': _controller.text},
      );
    }
  }

  void _showCountryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Sélectionnez un pays',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: _countries.length,
              itemBuilder: (context, index) {
                final country = _countries[index];
                final isSelected = _selectedCode == country['code'] && _selectedFlag == country['flag'];
                
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedFlag = country['flag']!;
                      _selectedCode = country['code']!;
                      _maxLength = country['length']!;
                      _currentHint = country['hint']!;
                      _rawPhoneNumber = ''; // Reset raw input
                      _controller.clear(); // Reset text input when country changes
                    });
                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        Text(country['flag']!, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Text(
                          country['name']!,
                          style: const TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          country['code']!,
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const Spacer(),
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: isSelected ? AppColors.primary : Colors.grey,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Bienvenue chez Passe Voyage ! Pour commencer, entrez votre numéro mobile',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            const Spacer(),
            
            // Input Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Row(
                children: [
                  // Country Code Selection
                  GestureDetector(
                    onTap: _showCountryDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      color: Colors.transparent,
                      child: Row(
                        children: [
                          Text(_selectedFlag, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 8),
                          Text(
                            _selectedCode,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                          const Icon(Icons.keyboard_arrow_down, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Phone Number TextField
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      readOnly: true, // Prevents system keyboard
                      showCursor: true, // Forces cursor to blink
                      cursorColor: Colors.black87,
                      cursorWidth: 2.0,
                      style: const TextStyle(
                        fontSize: 22,
                        letterSpacing: 2.0,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: _currentHint,
                        hintStyle: const TextStyle(
                          fontSize: 22,
                          letterSpacing: 2.0,
                          color: Colors.grey,
                          fontWeight: FontWeight.normal,
                        ),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primary, width: 2),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primary, width: 2),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Custom Numpad
            CustomNumpad(
              onKeyPressed: _onKeyPressed,
              onDelete: _onDelete,
            ),
            
            const SizedBox(height: 20),
            
            // Next Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _rawPhoneNumber.length == _maxLength ? _onNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Suivant',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
