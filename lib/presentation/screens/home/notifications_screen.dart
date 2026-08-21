import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/passenger_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    final notifications = await PassengerService.getNotifications();

    if (mounted) {
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
      // Mark all notifications as read in backend
      PassengerService.markNotificationsRead();
    }
  }

  IconData _getIconForType(String type) {
    switch (type.toUpperCase()) {
      case 'KYC_VERIFIED':
      case 'CREDIT_APPROVED':
        return Icons.task_alt;
      case 'KYC_REJECTED':
      case 'CREDIT_REJECTED':
        return Icons.cancel_outlined;
      case 'KYC_SUBMITTED':
        return Icons.assignment_turned_in_outlined;
      case 'WELCOME':
        return Icons.celebration;
      case 'PASS_SCANNED':
        return Icons.directions_bus;
      case 'REFUND_RECEIVED':
        return Icons.check_circle_outline;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toUpperCase()) {
      case 'KYC_VERIFIED':
      case 'CREDIT_APPROVED':
      case 'REFUND_RECEIVED':
        return AppColors.success;
      case 'KYC_REJECTED':
      case 'CREDIT_REJECTED':
        return AppColors.error;
      case 'KYC_SUBMITTED':
      case 'PASS_SCANNED':
        return AppColors.primary;
      case 'WELCOME':
        return AppColors.secondary;
      default:
        return Colors.orange;
    }
  }

  String _formatNotificationDate(dynamic createdAt) {
    if (createdAt == null) return 'Récemment';
    try {
      DateTime dt;
      if (createdAt is Map && createdAt.containsKey('date')) {
        dt = DateTime.parse(createdAt['date']);
      } else {
        dt = DateTime.parse(createdAt.toString());
      }
      final now = DateTime.now();
      final difference = now.difference(dt);

      if (difference.inMinutes < 60) {
        final mins = difference.inMinutes;
        return mins <= 1 ? 'À l\'instant' : 'Il y a $mins minutes';
      } else if (difference.inHours < 24 && now.day == dt.day) {
        return 'Aujourd\'hui à ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays <= 2 && (now.day - dt.day) == 1) {
        return 'Hier à ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } else {
        return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      }
    } catch (e) {
      return 'Récemment';
    }
  }

  Widget _buildNotificationItem(Map<String, dynamic> notif) {
    final title = notif['title']?.toString() ?? 'Notification';
    final message = notif['message']?.toString() ?? '';
    final type = notif['type']?.toString() ?? 'SYSTEM';
    final isUnread = notif['isRead'] == false;
    final timeStr = _formatNotificationDate(notif['createdAt']);

    final icon = _getIconForType(type);
    final iconColor = _getColorForType(type);

    return Container(
      padding: EdgeInsets.all(16.w),
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isUnread ? Colors.blue[50] : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24.w),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                          fontSize: 15.sp,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8.w,
                        height: 8.h,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13.sp,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  timeStr,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
          'NOTIFICATIONS',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: _notifications.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: 100.h),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_none_rounded, size: 64.w, color: Colors.grey[400]),
                              SizedBox(height: 16.h),
                              Text(
                                'Aucune notification pour le moment',
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Toutes vos activités récentes apparaîtront ici.',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(20.w),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notif = _notifications[index];
                        return _buildNotificationItem(notif);
                      },
                    ),
            ),
    );
  }
}
