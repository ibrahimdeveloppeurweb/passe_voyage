import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../widgets/custom_numpad.dart';
import '../../../config/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final String phoneNumber;
  final String countryCode;

  const LoginScreen({
    Key? key,
    required this.phoneNumber,
    this.countryCode = '+225',
  }) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _pinCode = '';
  bool _isLoading = false;

  Future<void> _onKeyPressed(String value) async {
    if (_pinCode.length < 4 && !_isLoading) {
      setState(() {
        _pinCode += value;
      });

      if (_pinCode.length == 4) {
        await _handleLogin();
      }
    }
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
    });

    final result = await AuthService.loginPassenger(
      phone: widget.phoneNumber,
      pinCode: _pinCode,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        if (result['offline'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mode hors-ligne : Données locales chargées.'),
              backgroundColor: Colors.orangeAccent,
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Redirection directe vers le Dashboard
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.dashboard,
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Code secret PIN incorrect'),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() {
          _pinCode = '';
        });
      }
    }
  }

  void _onDelete() {
    if (_pinCode.isNotEmpty && !_isLoading) {
      setState(() {
        _pinCode = _pinCode.substring(0, _pinCode.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, AppRoutes.phoneEntry);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 10.h),

            // Logo applicatif (assets/images/logo.png)
            Center(
              child: Image.asset(
                'assets/images/logo.png',
                height: 90.h,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 80.h,
                    width: 80.w,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_rounded, color: Colors.white, size: 40),
                  );
                },
              ),
            ),

            SizedBox(height: 35.h),

            // Libellé officiel de déverrouillage
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.0.w),
              child: Text(
                'Votre code secret est requis pour déverrouiller',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                  height: 1.4.h,
                ),
              ),
            ),

            const Spacer(),

            // Pastilles / Dots PIN avec dégradé AppColors.brandGradient (Bleu à Vert)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _pinCode.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: EdgeInsets.symmetric(horizontal: 10.w),
                  width: 16.w,
                  height: 16.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? null : AppColors.primary.withOpacity(0.12),
                    gradient: isFilled ? AppColors.brandGradient : null,
                    boxShadow: isFilled
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                );
              }),
            ),

            if (_isLoading) ...[
              SizedBox(height: 20.h),
              SizedBox(
                height: 24.h,
                width: 24.w,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2.5,
                ),
              ),
            ],

            const Spacer(),

            // Pavé numérique avec bouton OUBLIÉ?
            CustomNumpad(
              onKeyPressed: _onKeyPressed,
              onDelete: _onDelete,
              leftActionKey: InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pour réinitialiser votre code PIN, veuillez contacter le support ou recommencer par SMS.'),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(40.r),
                child: Container(
                  width: 80.w,
                  height: 80.h,
                  alignment: Alignment.center,
                  child: Text(
                    'OUBLIÉ?',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}
