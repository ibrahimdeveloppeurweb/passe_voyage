import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../widgets/premium_background.dart';

class FacturesScreen extends StatelessWidget {
  const FacturesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Factures",
          style: TextStyle(color: Colors.black, fontSize: 20.sp, fontWeight: FontWeight.w500),
        ),
        centerTitle: false,
      ),
      extendBodyBehindAppBar: true,
      body: PremiumBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 10.h),
            
            // Canal+
            _buildFactureItem(
              iconWidget: Container(
                width: 48.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    'CANAL+',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              title: 'Canal+',
              subtitle: 'Service indisponible',
              titleColor: Colors.grey[400],
              subtitleColor: Colors.grey[400],
              onTap: () {},
            ),
            
            // FER Péage
            _buildFactureItem(
              iconWidget: _buildLogoPlaceholder('FER', Colors.black87),
              title: 'FER Péage',
              onTap: () {},
            ),
            
            // Prépayé CIE
            _buildFactureItem(
              iconWidget: _buildCieSodeciLogo('CIE'),
              title: 'Prépayé CIE',
              onTap: () {},
            ),
            
            // Factures CIE
            _buildFactureItem(
              iconWidget: _buildCieSodeciLogo('CIE'),
              title: 'Factures CIE',
              onTap: () {},
            ),
            
            // Factures SODECI
            _buildFactureItem(
              iconWidget: _buildCieSodeciLogo('SODECI', isSodeci: true),
              title: 'Factures SODECI',
              onTap: () {},
              showDivider: false,
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoPlaceholder(String text, Color bgColor) {
    return Container(
      width: 48.w,
      height: 48.h,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(color: bgColor, fontSize: 12.sp, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildCieSodeciLogo(String text, {bool isSodeci = false}) {
    return Container(
      width: 48.w,
      height: 48.h,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text.substring(0, isSodeci ? 3 : 1),
              style: TextStyle(color: isSodeci ? Colors.green[700] : Colors.orange[700], fontSize: 10.sp, fontWeight: FontWeight.bold),
            ),
            Text(
              text.substring(isSodeci ? 3 : 1),
              style: TextStyle(color: isSodeci ? Colors.green[900] : Colors.green[700], fontSize: 10.sp, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFactureItem({
    required Widget iconWidget,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? titleColor,
    Color? subtitleColor,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0.w, vertical: 12.0.h),
            child: Row(
              children: [
                iconWidget,
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: titleColor ?? Colors.black87,
                        ),
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: 4.h),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: subtitleColor ?? Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: EdgeInsets.only(left: 84.0.w, right: 20.0.w),
            child: Divider(height: 1.h, color: Colors.grey[200]),
          ),
      ],
    );
  }
}
