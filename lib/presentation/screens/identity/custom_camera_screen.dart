import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart'; // for XFile
import '../../../core/theme/app_colors.dart';

class CustomCameraScreen extends StatefulWidget {
  const CustomCameraScreen({Key? key}) : super(key: key);

  @override
  State<CustomCameraScreen> createState() => _CustomCameraScreenState();
}

class _CustomCameraScreenState extends State<CustomCameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  
  bool _isProcessingFrame = false;
  bool _isFaceCentered = false;
  String _feedbackMessage = "Recherche d'un visage...";

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableClassification: false,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      
      // Look for front camera
      CameraDescription? frontCamera;
      for (var camera in _cameras!) {
        if (camera.lensDirection == CameraLensDirection.front) {
          frontCamera = camera;
          break;
        }
      }
      
      // Fallback to first camera if front not available
      frontCamera ??= _cameras!.first;

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
        _controller!.startImageStream(_processCameraFrame);
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  void _processCameraFrame(CameraImage image) async {
    if (_isProcessingFrame) return;
    _isProcessingFrame = true;

    try {
      final int width = image.width;
      final int height = image.height;
      final int ySize = width * height;
      final int uvSize = (width ~/ 2) * (height ~/ 2) * 2;
      Uint8List bytes;

      if (Platform.isAndroid) {
        bytes = Uint8List(ySize + uvSize);
        final yPlane = image.planes.first;
        final int yRowStride = yPlane.bytesPerRow;
        
        if (yRowStride == width) {
          // No padding, copy Y plane directly
          bytes.setRange(0, ySize, yPlane.bytes);
        } else {
          // Remove padding row by row
          for (int i = 0; i < height; i++) {
            final int start = i * yRowStride;
            bytes.setRange(i * width, (i + 1) * width, yPlane.bytes.sublist(start, start + width));
          }
        }
        // We leave UV planes as 0 (green tint) since Face Detection only uses the Y (luma) plane!
      } else {
        // iOS bgra8888 or other
        final WriteBuffer allBytes = WriteBuffer();
        for (final Plane plane in image.planes) {
          allBytes.putUint8List(plane.bytes);
        }
        bytes = allBytes.done().buffer.asUint8List();
      }

      final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final camera = _controller!.description;
      
      InputImageRotation? rotation;
      if (Platform.isIOS) {
        rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
      } else if (Platform.isAndroid) {
        var rotationCompensation = 0; // Device orientation usually 0 (Portrait)
        if (camera.lensDirection == CameraLensDirection.front) {
          rotationCompensation = (camera.sensorOrientation + 0) % 360;
        } else {
          rotationCompensation = (camera.sensorOrientation - 0 + 360) % 360;
        }
        rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
      }
      
      final imageRotation = rotation ?? InputImageRotation.rotation0deg;
      final inputImageFormat = Platform.isAndroid ? InputImageFormat.nv21 : InputImageFormat.bgra8888;
      
      final inputImageData = InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: Platform.isAndroid ? imageSize.width.toInt() : (image.planes.isNotEmpty ? image.planes.first.bytesPerRow : 0),
      );

      final inputImage = InputImage.fromBytes(bytes: bytes, metadata: inputImageData);

      final faces = await _faceDetector.processImage(inputImage);
      
      if (faces.isEmpty) {
        if (_isFaceCentered != false || _feedbackMessage != "Aucun visage détecté") {
          setState(() {
            _isFaceCentered = false;
            _feedbackMessage = "Aucun visage détecté";
          });
        }
      } else if (faces.length > 1) {
        if (_isFaceCentered != false || _feedbackMessage != "Un seul visage est autorisé") {
          setState(() {
            _isFaceCentered = false;
            _feedbackMessage = "Un seul visage est autorisé";
          });
        }
      } else {
        // We have exactly 1 face.
        final face = faces.first;
        final rect = face.boundingBox;
        
        final imageCenterX = imageSize.width / 2;
        final imageCenterY = imageSize.height / 2;
        
        final faceCenterX = rect.center.dx;
        final faceCenterY = rect.center.dy;
        
        // Allow some tolerance
        final bool isCenteredX = (faceCenterX - imageCenterX).abs() < (imageSize.width * 0.25);
        final bool isCenteredY = (faceCenterY - imageCenterY).abs() < (imageSize.height * 0.25);
        
        // Check face size (should fill a decent portion of the frame)
        final faceArea = rect.width * rect.height;
        final imageArea = imageSize.width * imageSize.height;
        final bool isLargeEnough = faceArea > (imageArea * 0.1); // > 10% of the frame

        if (isCenteredX && isCenteredY && isLargeEnough) {
          if (!_isFaceCentered) {
            setState(() {
              _isFaceCentered = true;
              _feedbackMessage = "Parfait, ne bougez plus !";
            });
          }
        } else {
          if (_isFaceCentered || _feedbackMessage != "Centrez votre visage et approchez-vous") {
            setState(() {
              _isFaceCentered = false;
              _feedbackMessage = "Centrez votre visage et approchez-vous";
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Face detection error: $e");
      if (mounted) {
        setState(() {
          _feedbackMessage = "Erreur: ${e.toString().split('\n').first}";
        });
      }
    } finally {
      _isProcessingFrame = false;
    }
  }

  Future<void> _takePicture() async {
    if (!_isFaceCentered) return; // Prevent capture if not centered
    
    if (!_controller!.value.isInitialized) return;
    if (_controller!.value.isTakingPicture) return;

    try {
      await _controller!.stopImageStream();
      XFile file = await _controller!.takePicture();
      if (mounted) {
        Navigator.pop(context, file);
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
    }
  }

  @override
  void dispose() {
    _faceDetector.close();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview
          CameraPreview(_controller!),

          // Overlay Mask
          CustomPaint(
            painter: _FaceMaskPainter(
              borderColor: _isFaceCentered ? AppColors.secondary : AppColors.primary,
            ),
          ),

          // Instructions Text
          Positioned(
            top: 120.h, // Moved down to avoid overlapping with X button
            left: 20.w,
            right: 20.w,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                _feedbackMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _isFaceCentered ? AppColors.secondary : Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Close Button
          Positioned(
            top: 50.h,
            left: 16.w,
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.white, size: 30.w),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Capture Button
          Positioned(
            bottom: 60.h,
            left: 0.w,
            right: 0.w,
            child: Center(
              child: IgnorePointer(
                ignoring: !_isFaceCentered,
                child: GestureDetector(
                  onTap: _takePicture,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 80.h,
                    width: 80.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isFaceCentered ? AppColors.secondary : Colors.grey, 
                        width: 4.w
                      ),
                    ),
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 64.h,
                        width: 64.w,
                        decoration: BoxDecoration(
                          color: _isFaceCentered ? AppColors.secondary : Colors.grey.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaceMaskPainter extends CustomPainter {
  final Color borderColor;

  _FaceMaskPainter({required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    // The background overlay (semi-transparent black)
    final paint = Paint()..color = Colors.black.withOpacity(0.8); // Darker background

    // Create a path that covers the whole screen
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // The oval cutout in the center (made larger)
    final ovalWidth = size.width * 0.85;
    final ovalHeight = size.height * 0.55;
    
    // Position the oval slightly above the center
    final center = Offset(size.width / 2, size.height * 0.45);
    
    final ovalRect = Rect.fromCenter(
      center: center,
      width: ovalWidth,
      height: ovalHeight,
    );

    // Create a path for the oval
    final ovalPath = Path()..addOval(ovalRect);

    // Combine paths to create the cutout (background - oval)
    final combinedPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      ovalPath,
    );

    // Draw the overlay with the cutout
    canvas.drawPath(combinedPath, paint);

    // Draw a border around the oval
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    canvas.drawPath(ovalPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _FaceMaskPainter oldDelegate) {
    return oldDelegate.borderColor != borderColor;
  }
}
