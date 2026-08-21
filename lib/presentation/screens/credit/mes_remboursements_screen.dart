import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/passenger_service.dart';

class MesRemboursementsScreen extends StatefulWidget {
  const MesRemboursementsScreen({Key? key}) : super(key: key);

  @override
  State<MesRemboursementsScreen> createState() =>
      _MesRemboursementsScreenState();
}

class _MesRemboursementsScreenState extends State<MesRemboursementsScreen> {
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'fr_FR');

  bool _isLoading = true;
  int _totalReimbursed = 0;
  int _totalDebt = 0;
  List<Map<String, dynamic>> _reimbursements = [];

  @override
  void initState() {
    super.initState();
    _loadReimbursements();
  }

  Future<void> _loadReimbursements() async {
    setState(() => _isLoading = true);
    final data = await PassengerService.getPassengerReimbursements();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (data['success'] == true) {
          _totalReimbursed = data['totalReimbursed'] ?? 0;
          _totalDebt = data['totalDebt'] ?? 0;
          _reimbursements = data['reimbursements'] ?? [];
        }
      });
    }
  }

  Widget _buildRefundCard(Map<String, dynamic> item) {
    final String description = 'Remboursement Crédit';
    final String date = item['date']?.toString() ?? 'Récemment';
    final String mode = item['paymentMethod']?.toString() ?? 'Mobile Money';
    final int amount =
        (item['amount'] is num) ? (item['amount'] as num).toInt() : 0;
    final bool isSuccess =
        (item['status']?.toString().toUpperCase() ?? 'SUCCESS') == 'SUCCESS';

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: isSuccess
                      ? AppColors.secondary.withOpacity(0.15)
                      : AppColors.error.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                  color: isSuccess ? AppColors.secondary : AppColors.error,
                  size: 24.w,
                ),
              ),
              SizedBox(width: 16.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '$date • $mode',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isSuccess
                    ? '+ ${_currencyFormat.format(amount)} F'
                    : '${_currencyFormat.format(amount)} F',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15.sp,
                  color: isSuccess ? AppColors.secondary : AppColors.error,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                isSuccess ? 'Succès' : 'Échoué',
                style: TextStyle(
                  color: isSuccess ? AppColors.secondary : AppColors.error,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
          'MES REMBOURSEMENTS',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w900,
            fontSize: 16.sp,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadReimbursements,
        color: AppColors.primary,
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30.r),
                  bottomRight: Radius.circular(30.r),
                ),
              ),
              child: Column(
                children: [
                  Text('Total Remboursé',
                      style:
                          TextStyle(color: Colors.grey[600], fontSize: 14.sp)),
                  SizedBox(height: 8.h),
                  Text(
                    '${_currencyFormat.format(_totalReimbursed)} F',
                    style: TextStyle(
                      fontSize: 36.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.secondary,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      'Reste à payer : ${_currencyFormat.format(_totalDebt)} F',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Historique des remboursements',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                        color: AppColors.textPrimary),
                  ),
                  SizedBox(height: 16.h),
                  if (_isLoading)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.h),
                      child: const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary),
                      ),
                    )
                  else if (_reimbursements.isEmpty)
                    Container(
                      padding: EdgeInsets.all(32.w),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 48.w, color: Colors.grey[400]),
                          SizedBox(height: 12.h),
                          Text(
                            'Aucun remboursement effectué',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Vos paiements pour le remboursement de votre crédit apparaîtront ici.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12.sp, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._reimbursements
                        .map((item) => _buildRefundCard(item))
                        .toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
