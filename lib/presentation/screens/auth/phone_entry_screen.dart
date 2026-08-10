import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
          title: Text(
            'Sélectionnez un pays',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 10.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          content: SizedBox(
            width: double.maxFinite,
            height: 400.h,
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
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    child: Row(
                      children: [
                        Text(country['flag']!, style: TextStyle(fontSize: 24.sp)),
                        SizedBox(width: 12.w),
                        Text(
                          country['name']!,
                          style: TextStyle(fontSize: 16.sp, color: AppColors.textPrimary),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          country['code']!,
                          style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
                        ),
                        const Spacer(),
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 40.h),
            // Title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0.w),
              child: Text(
                'Bienvenue chez Passe Voyage ! Pour commencer, entrez votre numéro mobile',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Spacer(),
            
            // Input Field
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.0.w),
              child: Row(
                children: [
                  // Country Code Selection
                  GestureDetector(
                    onTap: _showCountryDialog,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      color: Colors.transparent,
                      child: Row(
                        children: [
                          Text(_selectedFlag, style: TextStyle(fontSize: 22.sp)),
                          SizedBox(width: 8.w),
                          Text(
                            _selectedCode,
                            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w500),
                          ),
                          Icon(Icons.keyboard_arrow_down, size: 20.w),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  // Phone Number TextField
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      readOnly: true, // Prevents system keyboard
                      showCursor: true, // Forces cursor to blink
                      cursorColor: AppColors.textPrimary,
                      cursorWidth: 2.0,
                      style: TextStyle(
                        fontSize: 22.sp,
                        letterSpacing: 2.0,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: _currentHint,
                        hintStyle: TextStyle(
                          fontSize: 22.sp,
                          letterSpacing: 2.0,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.normal,
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primary, width: 2.w),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primary, width: 2.w),
                        ),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8.h),
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
            
            SizedBox(height: 20.h),
            
            // Next Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 16.0.h),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _rawPhoneNumber.length == _maxLength ? _onNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                  ),
                  child: Text(
                    'Suivant',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.background,
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
