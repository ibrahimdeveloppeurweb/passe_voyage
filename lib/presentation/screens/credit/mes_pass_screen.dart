import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';

class MesPassScreen extends StatelessWidget {
  const MesPassScreen({Key? key}) : super(key: key);

  void _showTicketModal(BuildContext context, String compagnie, String trajet, String date, int prix, String ticketStatus, int numberOfTickets) {
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
                      icon: Icon(Icons.close, size: 24.w, color: Colors.black87),
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
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(height: 20.h),
                          if (numberOfTickets > 1)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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
                            style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            trajet,
                            style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                          ),
                          SizedBox(height: 40.h),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.qr_code_2,
                                size: 250.w,
                                color: ticketStatus == 'Valide' ? AppColors.textPrimary : Colors.grey[300],
                              ),
                              if (ticketStatus == 'Utilisé')
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(
                                    'SCANNÉ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24.sp,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 4,
                                    ),
                                  ),
                                ),
                              if (ticketStatus == 'En validation')
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(
                                    'EN ATTENTE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24.sp,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 4,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 20.h),
                          Text(
                            'CODE TICKET',
                            style: TextStyle(color: Colors.grey, fontSize: 12.sp, letterSpacing: 1.5),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            ticketStatus == 'Valide' ? 'PASSE-V-847291-$ticketNumber' : '*** *** ***',
                            style: TextStyle(
                              fontSize: 24.sp, 
                              fontWeight: FontWeight.w900, 
                              letterSpacing: 2,
                              color: ticketStatus == 'Valide' ? AppColors.textPrimary : Colors.grey,
                            ),
                          ),
                          SizedBox(height: 40.h),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 20.h),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Date : $date',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'Montant : ${prix / numberOfTickets} F (Unité)',
                                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 40.h),
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

  Widget _buildPassCard(BuildContext context, String compagnie, String trajet, String date, String ticketStatus, String refundStatus, int prix, int numberOfTickets) {
    Color statusColor;
    Color statusBgColor;
    if (ticketStatus == 'Valide') {
      statusColor = AppColors.success;
      statusBgColor = AppColors.success.withOpacity(0.1);
    } else if (ticketStatus == 'Utilisé') {
      statusColor = Colors.grey[600]!;
      statusBgColor = Colors.grey[200]!;
    } else {
      statusColor = Colors.orange;
      statusBgColor = Colors.orange.withOpacity(0.1);
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
      onTap: () => _showTicketModal(context, compagnie, trajet, date, prix, ticketStatus, numberOfTickets),
      child: Container(
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
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: AppColors.tertiary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(Icons.directions_bus, color: AppColors.tertiary, size: 20.w),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            compagnie,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
                          ),
                          Text(
                            trajet,
                            style: TextStyle(color: Colors.grey, fontSize: 13.sp),
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
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  ticketStatus,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Icon(
                refundStatus == 'Remboursé' 
                    ? Icons.check_circle 
                    : (refundStatus == 'Partiellement remboursé' ? Icons.timelapse : Icons.error),
                size: 16.w,
                color: refundColor,
              ),
              SizedBox(width: 6.w),
              Text(
                'Remboursement : $refundStatus',
                style: TextStyle(
                  color: refundColor,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Divider(height: 1.h),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date de départ', style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Text(date, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                      if (numberOfTickets > 1) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            '$numberOfTickets billets',
                            style: TextStyle(color: AppColors.primary, fontSize: 10.sp, fontWeight: FontWeight.bold),
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
                  Text('Prix total', style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
                  SizedBox(height: 4.h),
                  Text(
                    '$prix F',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp, color: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
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
      body: ListView(
        padding: EdgeInsets.all(20.w),
        children: [
          _buildPassCard(context, 'UTB', 'Abidjan - Yamoussoukro', '15 Janvier 2026', 'En validation', 'Non remboursé', 5000, 1),
          _buildPassCard(context, 'AVS', 'Yamoussoukro - Bouaké', '10 Janvier 2026', 'Valide', 'Partiellement remboursé', 6000, 2),
          _buildPassCard(context, 'MT', 'Abidjan - San-Pédro', '02 Décembre 2025', 'Utilisé', 'Remboursé', 8000, 1),
          _buildPassCard(context, 'CTE', 'Abidjan - Korhogo', '15 Novembre 2025', 'Utilisé', 'Non remboursé', 30000, 3),
        ],
      ),
    );
  }
}
