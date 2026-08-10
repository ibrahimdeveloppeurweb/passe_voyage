import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';

class RemboursementScreen extends StatefulWidget {
  const RemboursementScreen({Key? key}) : super(key: key);

  @override
  State<RemboursementScreen> createState() => _RemboursementScreenState();
}

class _RemboursementScreenState extends State<RemboursementScreen> {
  final TextEditingController _amountController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'fr_FR');
  


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_amountController.text.isEmpty) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('amount')) {
        _amountController.text = args['amount'].toString();
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }



  void _submit() {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un montant.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final amount = int.tryParse(_amountController.text.replaceAll(' ', ''));
    if (amount == null || amount < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le montant minimum est de 100 F CFA.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Success logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dépôt initié avec succès.'),
        backgroundColor: AppColors.success, // Assuming we have success color
      ),
    );
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) Navigator.pop(context);
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'REMBOURSER',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w900,
            fontSize: 18.sp,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.0.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Montant à rembourser (Minimum 100 F CFA)',
                          style: TextStyle(color: Colors.grey, fontSize: 13.sp),
                        ),
                        Text(
                          'Frais: 0 F',
                          style: TextStyle(
                            color: AppColors.primary.withOpacity(0.8),
                            fontWeight: FontWeight.bold,
                            fontSize: 13.sp,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'XOF',
                          style: TextStyle(
                            fontSize: 48.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            style: TextStyle(
                              fontSize: 40.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: '0',
                              hintStyle: TextStyle(
                                fontSize: 40.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey[300]!, width: 2.w),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: AppColors.primary, width: 2.w),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32.h),
                    

                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(24.0.w),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 18.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Continuer',
                    style: TextStyle(
                      fontSize: 18.sp,
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
