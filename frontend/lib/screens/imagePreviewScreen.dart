// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ImagePreviewScreen extends StatefulWidget {
  final String imagePath;

  const ImagePreviewScreen({super.key, required this.imagePath});

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  Map<String, dynamic>? plantData;
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = "";

  String get _cacheKey => "plant_data_${widget.imagePath}";

  @override
  void initState() {
    super.initState();
    _loadFromCacheOrGenerate();
  }

  // cache handle
  Future<void> _loadFromCacheOrGenerate() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);

    if (cached != null) {
      setState(() {
        plantData = json.decode(cached);
        isLoading = false;
      });
    } else {
      await _generateAndSave();
    }
  }

  // generate data
  Future<bool> _generateAndSave() async {
    try {
      final uri = Uri.parse("http://localhost:3000/scan");
      final request = http.MultipartRequest("POST", uri);

      request.files.add(
        await http.MultipartFile.fromPath("photo", widget.imagePath),
      );

      request.fields['latitude'] = "20.2961";
      request.fields['longitude'] = "85.8245";

      final response = await request.send().timeout(
        const Duration(seconds: 35),
      );
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        throw Exception(responseBody);
      }

      final jsonResponse = json.decode(responseBody);
      final data = jsonResponse['plant_data'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, json.encode(data));

      setState(() {
        plantData = data;
        isLoading = false;
        hasError = false;
      });

      return true;
    } catch (e) {
      errorMessage = e.toString();
      hasError = true;
      isLoading = false;
      return false;
    }
  }

  // retry analysis
  Future<void> retryAnalysis() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });
    await _generateAndSave();
  }

  // delete plant picture
  Future<void> deleteImageAndData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_cacheKey); // remove the key

    final images = prefs.getStringList('images') ?? [];
    images.remove(widget.imagePath);
    await prefs.setStringList('images', images);

    final discoveries = prefs.getStringList('discoveries') ?? [];
    discoveries.removeWhere((d) {
      final jsonData = json.decode(d);
      return jsonData['imagePath'] == widget.imagePath;
    });
    await prefs.setStringList('discoveries', discoveries);

    final file = File(widget.imagePath);
    if (await file.exists()) {
      await file.delete();
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  // card widget
  Widget _card(String title, IconData icon, Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A).withOpacity(0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.greenAccent),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _confidenceBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label ${(value * 100).toStringAsFixed(0)}%",
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: value,
          minHeight: 12,
          backgroundColor: Colors.white24,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ],
    );
  }

  Widget _authenticityBar(
    String title,
    String subtitle,
    double value,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white)),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: value,
          minHeight: 12,
          backgroundColor: Colors.white24,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ],
    );
  }

  // -------------------- BUILD --------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.file(File(widget.imagePath), fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.85),
                  ],
                ),
              ),
            ),
          ),

          /// DELETE BUTTON (ALWAYS VISIBLE)
          Positioned(
            top: 34,
            right: 24,
            child: OutlinedButton.icon(
              onPressed: deleteImageAndData,
              icon: const Icon(Icons.delete),
              label: const Text("Delete"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
              ),
            ),
          ),

          SafeArea(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  )
                : hasError || plantData == null
                ? _errorView()
                : _contentSheet(),
          ),
        ],
      ),
    );
  }

  // -------------------- CONTENT --------------------
  Widget _contentSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: const Color(0xFF1E1E1E).withOpacity(0.85),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 90),
                children: [
                  Center(
                    child: Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white54,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _card(
                    "Identification Confidence",
                    Icons.verified,
                    _confidenceBar(
                      "Accuracy",
                      plantData!["confidence"].toDouble(),
                      Colors.greenAccent,
                    ),
                  ),

                  _card(
                    "Image Authenticity",
                    Icons.image,
                    Column(
                      children: [
                        _authenticityBar(
                          "Real Plant",
                          "Photo of a real plant",
                          plantData!["imageSourceConfidence"]["realPlant"]
                              .toDouble(),
                          Colors.greenAccent,
                        ),
                        const SizedBox(height: 12),
                        _authenticityBar(
                          "Screen / Image",
                          "Possibly taken from screen",
                          plantData!["imageSourceConfidence"]["screenOrPhoto"]
                              .toDouble(),
                          Colors.orangeAccent,
                        ),
                      ],
                    ),
                  ),

                  _card(
                    "About",
                    Icons.info_outline,
                    Text(
                      plantData!["description"] ?? "",
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.6,
                      ),
                    ),
                  ),

                  _card(
                    "Rarity",
                    Icons.public,
                    Text(
                      plantData!["rarity"]["note"] ?? "",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),

                  _card(
                    "Growing Tips",
                    Icons.spa,
                    Text(
                      plantData!["growingTips"]["easyCareTips"] ?? "",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),

                  ElevatedButton.icon(
                    onPressed: retryAnalysis,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Regenerate Details"),
                  ),

                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Delete this image?"),
                          content: const Text(
                            "This will permanently delete the image and its generated details.",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("Delete"),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await deleteImageAndData();
                      }
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text("Delete Image"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Helper for the Care Guide rows ---
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white54, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorView() {
    return const Center(
      child: Text(
        "Failed to load plant data",
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
