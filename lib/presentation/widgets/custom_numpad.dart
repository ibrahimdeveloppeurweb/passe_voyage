import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomNumpad extends StatelessWidget {
  final Function(String) onKeyPressed;
  final VoidCallback onDelete;
  final Widget? leftActionKey;

  const CustomNumpad({
    Key? key,
    required this.onKeyPressed,
    required this.onDelete,
    this.leftActionKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRow(['1', '2', '3']),
        SizedBox(height: 16.h),
        _buildRow(['4', '5', '6']),
        SizedBox(height: 16.h),
        _buildRow(['7', '8', '9']),
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            leftActionKey ?? _buildEmptyKey(),
            _buildKey('0'),
            _buildDeleteKey(),
          ],
        ),
      ],
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) => _buildKey(key)).toList(),
    );
  }

  Widget _buildKey(String value) {
    return InkWell(
      onTap: () => onKeyPressed(value),
      borderRadius: BorderRadius.circular(40.r),
      child: Container(
        width: 80.w,
        height: 80.h,
        alignment: Alignment.center,
        child: Text(
          value,
          style: TextStyle(
            fontSize: 28.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteKey() {
    return InkWell(
      onTap: onDelete,
      borderRadius: BorderRadius.circular(40.r),
      child: Container(
        width: 80.w,
        height: 80.h,
        alignment: Alignment.center,
        child: Icon(
          Icons.backspace,
          size: 24.w,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildEmptyKey() {
    return SizedBox(
      width: 80.w,
      height: 80.h,
    );
  }
}
