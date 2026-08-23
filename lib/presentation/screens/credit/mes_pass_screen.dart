import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../core/services/passenger_service.dart';
import '../../../core/theme/app_colors.dart';

class MesPassScreen extends StatefulWidget {
  const MesPassScreen({Key? key}) : super(key: key);

  @override
  State<MesPassScreen> createState() => _MesPassScreenState();
}

class _MesPassScreenState extends State<MesPassScreen> {
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'fr_FR');
  bool _isLoading = true;
  bool _isOffline = false;
  bool _isExpired = false;
  int _remainingHours = 72;
  List<Map<String, dynamic>> _passes = [];

  final List<Map<String, dynamic>> _defaultPasses = [];

  @override
  void initState() {
    super.initState();
    _fetchPasses();
  }

  Future<void> _fetchPasses() async {
    setState(() => _isLoading = true);
    final result = await PassengerService.getPassengerPassesData();
    if (mounted) {
      setState(() {
        _isOffline = result['isOffline'] == true;
        _isExpired = result['isExpired'] == true;
        _remainingHours = (result['remainingHours'] as num?)?.toInt() ?? 72;

        final rawPasses = result['passes'];
        if (rawPasses is List<Map<String, dynamic>>) {
          _passes = rawPasses;
        } else if (rawPasses is List) {
          _passes = rawPasses.map((e) => Map<String, dynamic>.from(e)).toList();
        } else {
          _passes = _defaultPasses;
        }
        _isLoading = false;
      });
    }
  }

  Widget _buildQrCodeWidget(String? qrCodeContent, String ticketStatus) {
    if (qrCodeContent != null && qrCodeContent.contains('base64,')) {
      try {
        final cleanBase64 = qrCodeContent
            .substring(qrCodeContent.indexOf('base64,') + 7)
            .trim();
        final Uint8List bytes = base64Decode(cleanBase64);
        return Image.memory(
          bytes,
          width: 280.w,
          height: 280.w,
          fit: BoxFit.contain,
        );
      } catch (e) {
        debugPrint('Error decoding base64 QR: $e');
      }
    }
    return Icon(
      Icons.qr_code_2,
      size: 280.w,
      color:
          ticketStatus == 'Valide' ? AppColors.textPrimary : Colors.grey[300],
    );
  }

  void _showTicketModal(BuildContext context, Map<String, dynamic> pass) {
    final String compagnie = pass['compagnie']?.toString() ?? 'Passage';
    final String trajet = pass['trajet']?.toString() ?? '';
    final String date = pass['date']?.toString() ?? '';
    final int prix = (pass['prix'] as num?)?.toInt() ?? 0;
    final int unitPrice = (pass['unitPrice'] as num?)?.toInt() ??
        (prix / ((pass['numberOfTickets'] as num?)?.toInt() ?? 1)).round();
    final String ticketStatus =
        pass['ticketStatus']?.toString() ?? 'En validation';
    final String? rejectionReason = pass['rejectionReason']?.toString() ??
        pass['rejection_reason']?.toString() ??
        pass['motif']?.toString();
    final String refundStatus =
        pass['refundStatus']?.toString() ?? 'Non remboursé';
    final int repaidAmount = (pass['repaidAmount'] as num?)?.toInt() ?? 0;
    final int remainingAmount =
        (pass['remainingAmount'] as num?)?.toInt() ?? max(0, prix - repaidAmount);
    final int numberOfTickets = (pass['numberOfTickets'] as num?)?.toInt() ?? 1;
    final List<dynamic> rawTickets =
        pass['tickets'] is List ? pass['tickets'] : [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 16.0.h, right: 16.0.w),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon:
                          Icon(Icons.close, size: 24.w, color: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  itemCount: numberOfTickets,
                  itemBuilder: (context, index) {
                    final ticketNumber = index + 1;
                    Map<String, dynamic> ticketData = {};
                    if (index < rawTickets.length && rawTickets[index] is Map) {
                      ticketData = Map<String, dynamic>.from(rawTickets[index]);
                    }

                    final String ticketCode =
                        ticketData['ticketNumber']?.toString() ??
                            (ticketStatus == 'Valide'
                                ? 'PASS-V-847291-$ticketNumber'
                                : '*** *** ***');
                    final String? qrContent =
                        ticketData['qrCodeContent']?.toString();
                    
                    final String actualTicketStatus = ticketData['status']?.toString().toUpperCase() ?? 'PENDING';
                    final bool isScanned = actualTicketStatus == 'SCANNED' || ticketData['isUsed'] == true;
                    final bool isRefused = actualTicketStatus == 'REFUSED';
                    final bool isValidated = actualTicketStatus == 'VALIDATED';

                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(height: 10.h),
                          if (numberOfTickets > 1)
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16.w, vertical: 8.h),
                              margin: EdgeInsets.only(bottom: 16.h),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Text(
                                'Billet $ticketNumber / $numberOfTickets',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          Text(
                            compagnie,
                            style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            trajet,
                            style:
                                TextStyle(fontSize: 16.sp, color: Colors.grey),
                          ),
                          SizedBox(height: 30.h),
                          Opacity(
                            opacity: (isScanned || isRefused) ? 0.3 : 1.0,
                            child: _buildQrCodeWidget((isScanned || isRefused) ? null : qrContent, ticketStatus),
                          ),
                          SizedBox(height: 16.h),
                          if (isScanned)
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 24.w, vertical: 12.h),
                              decoration: BoxDecoration(
                                color: Colors.red.shade600,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                'SCANNÉ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                            )
                          else if (ticketStatus == 'En validation' && !isScanned && !isRefused)
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 24.w, vertical: 12.h),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                'EN ATTENTE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                            )
                          else if (isRefused)
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 24.w, vertical: 12.h),
                              decoration: BoxDecoration(
                                color: Colors.red.shade800,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                'REFUSÉ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                            )
                          else if (isValidated && !isScanned && !isRefused)
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                'NON SCANNÉ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          SizedBox(height: 20.h),
                          Text(
                            'CODE TICKET',
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12.sp,
                                letterSpacing: 1.5),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            (!isScanned && !isRefused && (ticketStatus == 'Valide' || ticketStatus == 'Utilisé'))
                                ? ticketCode
                                : '*** *** ***',
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              color: (ticketStatus == 'Valide' ||
                                      ticketStatus == 'Utilisé')
                                  ? AppColors.textPrimary
                                  : Colors.grey,
                            ),
                          ),
                          SizedBox(height: 30.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 40.w, vertical: 20.h),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Date : $date',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'Montant : ${unitPrice.toStringAsFixed(1)} F (Unité)',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 24.w),
                            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
                            decoration: BoxDecoration(
                              color: refundStatus == 'Remboursé'
                                  ? Colors.green[50]
                                  : (refundStatus == 'Partiellement remboursé'
                                      ? Colors.orange[50]
                                      : Colors.grey[100]),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: refundStatus == 'Remboursé'
                                    ? Colors.green[200]!
                                    : (refundStatus == 'Partiellement remboursé'
                                        ? Colors.orange[200]!
                                        : Colors.grey[300]!),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Statut remboursement :', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.grey[800])),
                                    Text(
                                      refundStatus,
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold,
                                        color: refundStatus == 'Remboursé'
                                            ? AppColors.success
                                            : (refundStatus == 'Partiellement remboursé' ? Colors.orange[800] : AppColors.error),
                                      ),
                                    ),
                                  ],
                                ),
                                if (repaidAmount > 0) ...[
                                  SizedBox(height: 8.h),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Montant déjà payé :', style: TextStyle(fontSize: 12.sp, color: Colors.grey[700])),
                                      Text('${_currencyFormat.format(repaidAmount)} F CFA', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.green[700])),
                                    ],
                                  ),
                                  SizedBox(height: 4.h),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Reste à payer :', style: TextStyle(fontSize: 12.sp, color: Colors.grey[700])),
                                      Text('${_currencyFormat.format(remainingAmount)} F CFA', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.orange[800])),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (ticketStatus == 'Refusé') ...[
                            SizedBox(height: 20.h),
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 24.w),
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(color: Colors.red[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.error_outline,
                                          color: Colors.red[700], size: 20.w),
                                      SizedBox(width: 8.w),
                                      Text(
                                        'Motif du refus',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red[800],
                                          fontSize: 14.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    (rejectionReason != null &&
                                            rejectionReason.trim().isNotEmpty)
                                        ? rejectionReason
                                        : 'Demande refusée par l\'administrateur.',
                                    style: TextStyle(
                                      color: Colors.red[900],
                                      fontSize: 13.sp,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          SizedBox(height: 30.h),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (numberOfTickets > 1)
                Padding(
                  padding: EdgeInsets.only(bottom: 24.0.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.swipe, color: Colors.grey, size: 16.w),
                      SizedBox(width: 8.w),
                      Text(
                        'Glissez pour voir les autres billets',
                        style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPassCard(BuildContext context, Map<String, dynamic> pass) {
    final String compagnie = pass['compagnie']?.toString() ?? 'Compagnie';
    final String trajet = pass['trajet']?.toString() ?? '';
    final String date = pass['date']?.toString() ?? '';
    final String ticketStatus =
        pass['ticketStatus']?.toString() ?? 'En validation';
    final String refundStatus =
        pass['refundStatus']?.toString() ?? 'Non remboursé';
    final int prix = (pass['prix'] as num?)?.toInt() ?? 0;
    final int serviceFee = (pass['serviceFee'] as num?)?.toInt() ?? 0;
    final int amountToRepay = (pass['amountToRepay'] as num?)?.toInt() ??
        (pass['amountRequested'] as num?)?.toInt() ??
        max(0, prix - serviceFee);
    final int numberOfTickets = (pass['numberOfTickets'] as num?)?.toInt() ?? 1;
    final int repaidAmount = (pass['repaidAmount'] as num?)?.toInt() ?? 0;
    final int remainingAmount =
        (pass['remainingAmount'] as num?)?.toInt() ?? max(0, amountToRepay - repaidAmount);

    Color statusColor;
    Color statusBgColor;
    if (ticketStatus == 'Valide') {
      statusColor = AppColors.success;
      statusBgColor = AppColors.success.withOpacity(0.15);
    } else if (ticketStatus == 'Utilisé') {
      statusColor = Colors.grey[600]!;
      statusBgColor = Colors.grey[200]!;
    } else if (ticketStatus == 'Refusé') {
      statusColor = AppColors.error;
      statusBgColor = AppColors.error.withOpacity(0.15);
    } else {
      statusColor = Colors.orange;
      statusBgColor = Colors.orange.withOpacity(0.15);
    }

    Color refundColor;
    if (refundStatus == 'Remboursé') {
      refundColor = AppColors.success;
    } else if (refundStatus == 'Partiellement remboursé') {
      refundColor = Colors.orange;
    } else {
      refundColor = AppColors.error;
    }

    return GestureDetector(
      onTap: () => _showTicketModal(context, pass),
      child: Container(
        margin: EdgeInsets.only(bottom: 20.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: statusColor, width: 6.w),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12.w),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(14.r),
                                  ),
                                  child: Icon(Icons.directions_bus,
                                      color: Colors.white, size: 24.w),
                                ),
                                SizedBox(width: 16.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        compagnie,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 18.sp,
                                            color: AppColors.textPrimary),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        trajet,
                                        style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.w500),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(
                              ticketStatus,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11.sp,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Icon(
                            refundStatus == 'Remboursé'
                                ? Icons.check_circle
                                : (refundStatus == 'Partiellement remboursé'
                                    ? Icons.timelapse
                                    : Icons.error),
                            size: 16.w,
                            color: refundColor,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Remboursement : $refundStatus',
                                  style: TextStyle(
                                    color: refundColor,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (refundStatus == 'Partiellement remboursé') ...[
                                  SizedBox(height: 2.h),
                                  Text(
                                    'Payé : ${_currencyFormat.format(repaidAmount)} F  |  Reste à payer : ${_currencyFormat.format(remainingAmount)} F',
                                    style: TextStyle(
                                      color: Colors.orange[800],
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Ticket divider line
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    children: List.generate(
                      40,
                      (index) => Expanded(
                        child: Container(
                          height: 1.5.h,
                          color: index.isEven
                              ? Colors.grey[300]
                              : Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20.r),
                      bottomRight: Radius.circular(20.r),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Date de départ',
                              style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w500)),
                          SizedBox(height: 6.h),
                          Row(
                            children: [
                              Text(date,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15.sp,
                                      color: AppColors.textPrimary)),
                              if (numberOfTickets > 1) ...[
                                SizedBox(width: 8.w),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Text(
                                    '$numberOfTickets billets',
                                    style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Crédit Transport',
                              style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w500)),
                          SizedBox(height: 4.h),
                          Text(
                            '${_currencyFormat.format(amountToRepay)} F',
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15.sp,
                                color: AppColors.textPrimary),
                          ),
                          if (refundStatus == 'Partiellement remboursé') ...[
                            SizedBox(height: 4.h),
                            Text(
                              'Reste dû : ${_currencyFormat.format(remainingAmount)} F',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.sp,
                                  color: Colors.orange[800]),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
          'MES PASS',
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
      body: RefreshIndicator(
        onRefresh: _fetchPasses,
        color: AppColors.primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (_isExpired)
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.red[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.wifi_off_rounded, color: Colors.red[700], size: 24.w),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Accès Hors-Ligne Expiré (72h)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red[900],
                                    fontSize: 13.sp,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  'Veuillez vous connecter à Internet pour synchroniser vos Pass.',
                                  style: TextStyle(
                                    color: Colors.red[800],
                                    fontSize: 11.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _fetchPasses,
                            style: TextButton.styleFrom(padding: EdgeInsets.zero),
                            child: Text(
                              'Réessayer',
                              style: TextStyle(
                                color: Colors.red[900],
                                fontWeight: FontWeight.bold,
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_isOffline)
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.offline_pin_rounded, color: AppColors.primary, size: 20.w),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              'Mode Hors-Ligne',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: _passes.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.confirmation_number_outlined, size: 64.w, color: Colors.grey[400]),
                                    SizedBox(height: 16.h),
                                    Text(
                                      'Aucun Pass disponible',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      'Vos pass apparaîtront ici dès qu’une demande sera approuvée.',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: Colors.grey[500],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.all(20.w),
                                itemCount: _passes.length,
                                itemBuilder: (context, index) {
                                  return _buildPassCard(context, _passes[index]);
                                },
                              ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
