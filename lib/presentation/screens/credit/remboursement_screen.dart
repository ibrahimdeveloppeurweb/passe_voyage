import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/passenger_service.dart';
import '../../../config/routes.dart';

class RemboursementScreen extends StatefulWidget {
  const RemboursementScreen({Key? key}) : super(key: key);

  @override
  State<RemboursementScreen> createState() => _RemboursementScreenState();
}

class _RemboursementScreenState extends State<RemboursementScreen> {
  final TextEditingController _amountController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'fr_FR');

  bool _isLoading = false;
  int _availableCredit = 0;
  int _totalDebt = 0;
  String? _creditUuid;

  int get _maxDebt => _totalDebt > 0 ? _totalDebt : _availableCredit;

  int get _enteredAmount {
    final text = _amountController.text.replaceAll(' ', '').trim();
    return int.tryParse(text) ?? 0;
  }

  bool get _isValidAmount {
    if (_maxDebt <= 0) return false;
    if (_enteredAmount < 100) return false;
    if (_enteredAmount > _maxDebt) return false;
    return true;
  }

  @override
  void initState() {
    super.initState();
    _fetchPassengerDebt();
    _amountController.addListener(_onAmountChanged);
  }

  void _onAmountChanged() {
    setState(() {});
  }

  Future<void> _fetchPassengerDebt() async {
    final data = await PassengerService.getDashboardData();
    if (mounted && data['success'] == true) {
      setState(() {
        _availableCredit = data['availableCredit'] ?? 0;
        _totalDebt = data['totalDebt'] ?? _availableCredit;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      if (_amountController.text.isEmpty && args.containsKey('amount')) {
        _amountController.text = args['amount'].toString();
      }
      if (args.containsKey('creditUuid')) {
        _creditUuid = args['creditUuid'] as String?;
      }
    }
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    super.dispose();
  }

  void _quickSelectAmount(int amount) {
    setState(() {
      _amountController.text = amount.toString();
    });
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

    _showPaymentMethodBottomSheet(amount);
  }

  void _showPaymentMethodBottomSheet(int amount) {
    String selectedMethod = 'Wave';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
                top: 24.h,
                left: 24.w,
                right: 24.w,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Moyen de Paiement',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Montant à payer : ${_currencyFormat.format(amount)} F CFA',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Payment Options
                  _buildPaymentOptionTile(
                    title: 'Wave',
                    subtitle: 'Paiement instantané Wave',
                    icon: Icons.waves,
                    badgeColor: const Color(0xFF1DC4FF),
                    value: 'Wave',
                    groupValue: selectedMethod,
                    onChanged: (val) => setModalState(() => selectedMethod = val!),
                  ),
                  _buildPaymentOptionTile(
                    title: 'Orange Money',
                    subtitle: 'Paiement Mobile Money Orange',
                    icon: Icons.phone_android,
                    badgeColor: const Color(0xFFFF6600),
                    value: 'Orange Money',
                    groupValue: selectedMethod,
                    onChanged: (val) => setModalState(() => selectedMethod = val!),
                  ),
                  _buildPaymentOptionTile(
                    title: 'MTN Mobile Money',
                    subtitle: 'Paiement Mobile Money MTN',
                    icon: Icons.account_balance_wallet,
                    badgeColor: const Color(0xFFFFCC00),
                    value: 'MTN Mobile Money',
                    groupValue: selectedMethod,
                    onChanged: (val) => setModalState(() => selectedMethod = val!),
                  ),
                  _buildPaymentOptionTile(
                    title: 'Moov Money',
                    subtitle: 'Paiement Mobile Money Moov',
                    icon: Icons.smartphone,
                    badgeColor: const Color(0xFF0055A5),
                    value: 'Moov Money',
                    groupValue: selectedMethod,
                    onChanged: (val) => setModalState(() => selectedMethod = val!),
                  ),
                  _buildPaymentOptionTile(
                    title: 'Carte Bancaire',
                    subtitle: 'Paiement par carte bancaire',
                    icon: Icons.credit_card,
                    badgeColor: AppColors.primary,
                    value: 'Carte Bancaire',
                    groupValue: selectedMethod,
                    onChanged: (val) => setModalState(() => selectedMethod = val!),
                  ),

                  SizedBox(height: 24.h),

                  // Confirm Payment Button
                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.pop(context);
                              _processPayment(amount, selectedMethod);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 24.w,
                              height: 24.w,
                              child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(
                              'CONFIRMER LE PAIEMENT',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color badgeColor,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    final bool isSelected = value == groupValue;
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.06) : Colors.grey[50],
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.grey[200]!,
          width: isSelected ? 2.w : 1.w,
        ),
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        activeColor: AppColors.primary,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: badgeColor, size: 22.w),
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment(int amount, String paymentMethod) async {
    setState(() => _isLoading = true);

    // Call API endpoint
    final res = await PassengerService.submitReimbursement(
      amount: amount,
      paymentMethod: paymentMethod,
      creditUuid: _creditUuid,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (res['success'] == true) {
      _showSuccessDialog(
        amount: amount,
        paymentMethod: paymentMethod,
        formattedCredit: res['formattedCredit'] ?? '0',
        transactionId: res['payment']?['transactionId'] ?? '',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Erreur lors du paiement.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showSuccessDialog({
    required int amount,
    required String paymentMethod,
    required String formattedCredit,
    required String transactionId,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 12.h),
              Container(
                width: 72.w,
                height: 72.w,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded, color: Colors.white, size: 44.w),
              ),
              SizedBox(height: 20.h),
              Text(
                'Remboursement Réussi !',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Votre paiement par $paymentMethod de ${_currencyFormat.format(amount)} F CFA a été validé avec succès.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]),
              ),
              SizedBox(height: 20.h),

              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  children: [
                    _buildInfoRow('Solde crédit restant', '$formattedCredit FCFA'),
                    if (transactionId.isNotEmpty)
                      _buildInfoRow('N° Transaction', transactionId),
                  ],
                ),
              ),

              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Return to previous screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    'TERMINER',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13.sp,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
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
                    // Solde dû badge
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Solde crédit à rembourser',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                '${_currencyFormat.format(_totalDebt > 0 ? _totalDebt : _availableCredit)} FCFA',
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary, size: 32.w),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Montant à rembourser (Minimum 100 F CFA)',
                            style: TextStyle(color: Colors.grey, fontSize: 13.sp),
                          ),
                        ),
                        SizedBox(width: 8.w),
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
                    SizedBox(height: 16.h),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            'XOF',
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
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
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: '0',
                              hintStyle: TextStyle(
                                fontSize: 40.sp,
                                fontWeight: FontWeight.w900,
                                color: Colors.grey[300],
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey[200]!, width: 2.w),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: AppColors.primary, width: 3.w),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_maxDebt <= 0) ...[
                      SizedBox(height: 8.h),
                      Text(
                        'Vous n\'avez aucun solde de crédit en cours à rembourser.',
                        style: TextStyle(color: Colors.red[700], fontSize: 12.sp, fontWeight: FontWeight.bold),
                      ),
                    ] else if (_enteredAmount > _maxDebt) ...[
                      SizedBox(height: 8.h),
                      Text(
                        'Le montant à rembourser ne peut pas dépasser ${_currencyFormat.format(_maxDebt)} F CFA.',
                        style: TextStyle(color: Colors.red[700], fontSize: 12.sp, fontWeight: FontWeight.bold),
                      ),
                    ],
                    SizedBox(height: 24.h),

                    // Quick Select Buttons
                    Text(
                      'Montants rapides',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        _buildQuickAmountChip(1000),
                        _buildQuickAmountChip(2000),
                        _buildQuickAmountChip(5000),
                        _buildQuickAmountChip(10000),
                        if (_maxDebt > 0)
                          ActionChip(
                            label: Text(
                              'Tout rembourser',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 12.sp,
                              ),
                            ),
                            backgroundColor: AppColors.primary,
                            onPressed: () => _quickSelectAmount(_maxDebt),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Submit Button
            Padding(
              padding: EdgeInsets.all(24.0.w),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: (_isValidAmount && !_isLoading) ? AppColors.brandGradient : null,
                  color: (_isValidAmount && !_isLoading) ? null : Colors.grey[300],
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: (_isValidAmount && !_isLoading)
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: ElevatedButton(
                  onPressed: (_isLoading || !_isValidAmount) ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(vertical: 18.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 24.w,
                          height: 24.w,
                          child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          'CONTINUER',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: (_isValidAmount && !_isLoading) ? Colors.white : Colors.grey[600],
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

  Widget _buildQuickAmountChip(int amount) {
    final bool isChipDisabled = _maxDebt <= 0 || amount > _maxDebt;
    return ActionChip(
      label: Text(
        '${_currencyFormat.format(amount)} F',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isChipDisabled ? Colors.grey[400] : AppColors.textPrimary,
          fontSize: 12.sp,
        ),
      ),
      backgroundColor: isChipDisabled ? Colors.grey[200] : Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
        side: BorderSide(color: isChipDisabled ? Colors.grey[200]! : Colors.grey[300]!),
      ),
      onPressed: isChipDisabled ? null : () => _quickSelectAmount(amount),
    );
  }
}
