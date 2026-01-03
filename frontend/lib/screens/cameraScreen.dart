// ignore_for_file: unused_field

import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:frontend/main.dart';
import 'package:path_provider/path_provider.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  bool _isInitialized = false;
  bool _isCapturing = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _controller = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() => _isInitialized = true);
    });
  }

  // take picture
  Future<void> takePicture() async {
    if (_isCapturing || !_controller.value.isInitialized) return;
    _isInitialized = true;
    try {
      await _controller.pausePreview();
      final XFile file = await _controller.takePicture();
      final dir = await getApplicationDocumentsDirectory();
      final savedImage = File(
        '${dir.path}/${DateTime.now().microsecondsSinceEpoch}',
      );
      await File(file.path).copy(savedImage.path);
      await Future.delayed(Duration(milliseconds: 500));
      if (!mounted) return;
      Navigator.pop(context, savedImage.path);
    } finally {
      _isCapturing = false;
      if (_controller.value.isInitialized) {
        await _controller.resumePreview();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose(); // for buffers
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 10,),
              AutoSizeText(
                "We are loading for you",
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold();
  }
}
