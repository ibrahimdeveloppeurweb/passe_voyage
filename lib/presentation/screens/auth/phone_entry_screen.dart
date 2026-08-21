import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../widgets/custom_numpad.dart';
import '../../../config/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/contact_sync_service.dart';

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
  bool _isLoading = false;

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final storage = await StorageService.getInstance();
      
      // Si l'utilisateur est déjà connecté/authentifié -> Direction directe vers le Dashboard
      if (storage.isLoggedIn()) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
          return;
        }
      } 
      // Sinon s'il a un compte enregistré sur l'appareil -> Écran de verrouillage PIN Login
      else if (storage.hasSavedAccount()) {
        final savedPhone = storage.getPhoneNumber() ?? storage.getPassengerData()?['phoneNumber'] ?? '';
        if (mounted && savedPhone.isNotEmpty) {
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.login,
            arguments: {
              'phoneNumber': savedPhone,
            },
          );
          return;
        }
      }
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

  Future<void> _onNext() async {
    if (_rawPhoneNumber.length != _maxLength || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final fullPhone = '$_selectedCode$_rawPhoneNumber';
    final result = await AuthService.sendOtp(_rawPhoneNumber, _selectedCode);

    setState(() {
      _isLoading = false;
    });

    final isAccountExist = result['accountExists'] == true || 
        (result['message'] != null && result['message'].toString().toLowerCase().contains('existe déj'));

    if (result['success'] == true || isAccountExist) {
      if (isAccountExist) {
        // Le numéro possède déjà un compte passager -> Redirection directe et silencieuse vers LoginScreen
        if (mounted) {
          Navigator.pushNamed(
            context,
            AppRoutes.login,
            arguments: {
              'phoneNumber': fullPhone,
              'countryCode': _selectedCode,
            },
          );
        }
      } else {
        // Nouveau numéro -> Demander obligatoirement la permission d'accès aux contacts AU STADE OTP
        final bool isGranted = await ContactSyncService.syncContactsIfPermitted(
          overridePhone: fullPhone,
        );

        if (!isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                backgroundColor: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                margin: EdgeInsets.all(16.w),
                duration: const Duration(seconds: 4),
                content: Row(
                  children: [
                    Icon(Icons.shield_outlined, color: Colors.orangeAccent, size: 24.w),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Accès aux contacts refusé : Le processus s\'arrête à l\'étape OTP. L\'accès est obligatoire.',
                        style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return; // STOP STRICT AU STADE OTP ! Impossible de continuer sans permission
        }

        final String? otpCode = result['otpCode']?.toString();
        if (mounted) {
          await _showOtpDevModal(otpCode ?? '1234');
        }
      }
    } else {
      // Échec de la vérification réseau (Pas d'Internet)
      final storage = await StorageService.getInstance();
      final savedPhone = storage.getPhoneNumber() ?? storage.getPassengerData()?['phoneNumber'] ?? '';
      
      final cleanTyped = fullPhone.replaceAll(RegExp(r'[^0-9]'), '');
      final cleanSaved = savedPhone.replaceAll(RegExp(r'[^0-9]'), '');

      // Si le numéro saisi correspond au compte enregistré sur ce téléphone -> Connexion PIN Hors-Ligne
      if (cleanSaved.isNotEmpty && (cleanSaved == cleanTyped || cleanTyped.endsWith(cleanSaved) || cleanSaved.endsWith(cleanTyped))) {
        if (mounted) {
          Navigator.pushNamed(
            context,
            AppRoutes.login,
            arguments: {
              'phoneNumber': fullPhone,
              'countryCode': _selectedCode,
            },
          );
        }
      } else {
        // Sinon -> Message SnackBar informant que la connexion Internet est requise pour créer ou vérifier un nouveau compte
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? 'Connexion Internet requise. Veuillez vérifier votre réseau puis réessayer.',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.black87,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  Future<void> _showOtpDevModal(String otpCode) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          title: Row(
            children: [
              Icon(Icons.sms_rounded, color: AppColors.primary, size: 28.w),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Code SMS (Mode Dev)',
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'En mode démonstration sans SMS externe, voici votre code OTP :',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: Text(
                  otpCode,
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8.0,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                final bool isGranted = await ContactSyncService.syncContactsIfPermitted(
                  overridePhone: '$_selectedCode$_rawPhoneNumber',
                );

                if (!isGranted) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFF1E293B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                        margin: EdgeInsets.all(16.w),
                        duration: const Duration(seconds: 4),
                        content: Row(
                          children: [
                            Icon(Icons.shield_outlined, color: Colors.orangeAccent, size: 24.w),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                'Accès aux contacts refusé : La saisie du code OTP est bloquée.',
                                style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return; // STOP STRICT !
                }

                if (mounted) {
                  Navigator.pop(context); // Fermer le modal
                  Navigator.pushNamed(
                    context,
                    AppRoutes.otpValidation,
                    arguments: {
                      'phoneNumber': _rawPhoneNumber,
                      'countryCode': _selectedCode,
                      'formattedPhone': _controller.text,
                      'otpCode': otpCode,
                    },
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
              child: Text(
                'Saisir le code',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15.sp),
              ),
            ),
          ],
        );
      },
    );
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
                      _rawPhoneNumber = '';
                      _controller.clear();
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
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0.w),
              child: Text(
                'Bienvenue chez Pass Voyage ! Pour commencer, entrez votre numéro mobile',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Spacer(),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0.w),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _showCountryDialog,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
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
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        readOnly: true,
                        showCursor: true,
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
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            CustomNumpad(
              onKeyPressed: _onKeyPressed,
              onDelete: _onDelete,
            ),

            SizedBox(height: 20.h),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 24.0.h),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: _rawPhoneNumber.length == _maxLength && !_isLoading ? AppColors.brandGradient : null,
                  color: _rawPhoneNumber.length == _maxLength && !_isLoading ? null : AppColors.primary.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(30.r),
                  boxShadow: _rawPhoneNumber.length == _maxLength && !_isLoading ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ] : null,
                ),
                child: ElevatedButton(
                  onPressed: _rawPhoneNumber.length == _maxLength && !_isLoading ? _onNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 24.h,
                          width: 24.w,
                          child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          'Suivant',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.0,
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
