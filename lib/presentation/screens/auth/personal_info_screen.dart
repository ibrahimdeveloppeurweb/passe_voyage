import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../config/routes.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({Key? key}) : super(key: key);

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  String? _selectedGender; // 'Homme' or 'Femme'
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _residenceController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  Widget _buildGenderSelector() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedGender = 'Homme'),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: _selectedGender == 'Homme' ? AppColors.primary : Colors.grey[300]!,
                  width: _selectedGender == 'Homme' ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person, color: _selectedGender == 'Homme' ? AppColors.primary : Colors.blueGrey),
                  SizedBox(width: 8.w),
                  Text(
                    'Un Homme',
                    style: TextStyle(
                      color: _selectedGender == 'Homme' ? AppColors.primary : Colors.blueGrey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedGender = 'Femme'),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: _selectedGender == 'Femme' ? AppColors.primary : Colors.grey[300]!,
                  width: _selectedGender == 'Femme' ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_3, color: _selectedGender == 'Femme' ? AppColors.primary : Colors.blueGrey),
                  SizedBox(width: 8.w),
                  Text(
                    'Une Femme',
                    style: TextStyle(
                      color: _selectedGender == 'Femme' ? AppColors.primary : Colors.blueGrey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    Widget? suffixIcon,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: label,
            hintStyle: TextStyle(color: Colors.blueGrey[300], fontSize: 16.sp),
            suffixIcon: suffixIcon,
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: AppColors.primary, width: 2.w),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ce champ est requis';
            }
            return null;
          },
        ),
        SizedBox(height: 8.h),
        Text(
          hint,
          style: TextStyle(color: Colors.grey[400], fontSize: 12.sp),
        ),
        SizedBox(height: 24.h),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, AppRoutes.pinEntry);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24.0.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vous êtes ...',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 32.h),
                      
                      _buildGenderSelector(),
                      if (_selectedGender == null) ...[
                        SizedBox(height: 8.h),
                        Text(
                          'Veuillez sélectionner votre genre',
                          style: TextStyle(color: Colors.transparent, fontSize: 12.sp), // Placeholder for spacing or actual error
                        ),
                      ],
                      SizedBox(height: 32.h),
                      
                      _buildTextField(
                        controller: _nomController,
                        label: 'Nom de famille',
                        hint: 'Par exemple, Kouadio',
                      ),
                      
                      _buildTextField(
                        controller: _prenomController,
                        label: 'Prénoms',
                        hint: 'Par exemple, Olivia',
                      ),
                      
                      _buildTextField(
                        controller: _residenceController,
                        label: 'Lieu de résidence',
                        hint: 'Par exemple, Cocody Angré',
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(24.0.w),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate() && _selectedGender != null) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.dashboard,
                          (route) => false,
                        );
                      } else if (_selectedGender == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Veuillez sélectionner si vous êtes un Homme ou une Femme')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 18.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Continuer',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
