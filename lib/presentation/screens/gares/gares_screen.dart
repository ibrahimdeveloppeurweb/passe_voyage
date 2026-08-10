import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';

class GareLocation {
  final double lat;
  final double lng;
  final String title;
  final bool isStarred;

  GareLocation(this.lat, this.lng, this.title, this.isStarred);
}

class GaresScreen extends StatefulWidget {
  const GaresScreen({Key? key}) : super(key: key);

  @override
  State<GaresScreen> createState() => _GaresScreenState();
}

class _GaresScreenState extends State<GaresScreen> {
  String _searchQuery = "";
  final MapController _mapController = MapController();
  final LatLng _userLocation = const LatLng(5.345317, -4.024429); // User's simulated GPS position (Cocody)
  
  final List<GareLocation> _allGares = [
    GareLocation(5.355317, -4.014429, "Gare UTB Adjamé", true),
    GareLocation(5.328317, -4.012429, "Gare AVS Plateau", false),
    GareLocation(5.301317, -3.992429, "Gare MT Marcory", true),
    GareLocation(5.295317, -4.008429, "Gare CTE Treichville", false),
    GareLocation(5.335317, -4.064429, "Gare UTB Yopougon", true),
    GareLocation(5.345317, -4.024429, "Gare AVS Cocody", false),
  ];

  @override
  Widget build(BuildContext context) {
    final filteredGares = _allGares.where((gare) {
      return gare.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // 1. Real Map with flutter_map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.agir.transfert',
              ),
              MarkerLayer(
                markers: [
                  // User Location Marker
                  Marker(
                    point: _userLocation,
                    width: 60.w,
                    height: 60.h,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 16.w,
                          height: 16.h,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.w),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Gare Markers
                  ...filteredGares.map((gare) {
                    return _buildMapMarker(gare.lat, gare.lng, gare.title, gare.isStarred);
                  }).toList(),
                ],
              ),
            ],
          ),

          // 3. Top Search Bar and Back Button
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0.w, vertical: 8.0.h),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back, color: Color(0xFF0F3A4B)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Text(
                          'Trouver une gare partenaire',
                          style: TextStyle(
                            color: Color(0xFF0F3A4B),
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Container(
                    height: 54.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(27.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Rechercher une compagnie ou gare...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15.sp),
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. FAB (My Location)
          Positioned(
            bottom: 40.h,
            right: 20.w,
            child: FloatingActionButton(
              onPressed: () {
                _mapController.move(_userLocation, 14.0);
              },
              backgroundColor: AppColors.primary,
              child: Icon(Icons.my_location, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Marker _buildMapMarker(double lat, double lng, String title, bool isStarred) {
    return Marker(
      point: LatLng(lat, lng),
      width: 120.w,
      height: 90.h,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Custom Pin Shape
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36.w,
                    height: 36.h,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.w),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.directions_bus,
                        color: Colors.white,
                        size: 20.w,
                      ),
                    ),
                  ),
                  // The triangle tip of the pin
                  Container(
                    width: 0.w,
                    height: 0.h,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(width: 8.w, color: AppColors.primary),
                        left: BorderSide(width: 6.w, color: Colors.transparent),
                        right: BorderSide(width: 6.w, color: Colors.transparent),
                      ),
                    ),
                  ),
                ],
              ),
              if (isStarred)
                Positioned(
                  top: -4,
                  right: -6,
                  child: Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 16.w,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F3A4B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
