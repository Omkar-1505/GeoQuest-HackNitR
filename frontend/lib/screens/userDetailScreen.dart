import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/models/discovery.dart';
import 'package:frontend/services/api.service.dart';
import 'package:frontend/screens/imagePreviewScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserDetailScreen extends StatefulWidget {
  const UserDetailScreen({super.key});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  String userName = "Explorer";
  String? userPhoto;
  int userLevel = 1;
  int userXp = 0;
  List<Discovery> discoveries = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
              ),
            ),
          ),
          
          SafeArea(
            child: isLoading 
                ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
                : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  const SizedBox(height: 40), // Space for back button
                  _buildProfileHeader(),
                  const SizedBox(height: 30),
                  _buildStatsRow(),
                  const SizedBox(height: 30),
                  _buildPlantsSection(),
                ],
              ),
            ),
          ),

          // Custom Back Button
          Positioned(
            top: 40,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool isLoading = true;

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      final token = await user.getIdToken();
      if (token == null) return;

      // Parallel Fetch: Profile & Discoveries
      final profileFuture = ApiService.syncUserWithBackend(token);
      final discoveriesFuture = ApiService.getUserDiscoveries(token);

      final results = await Future.wait([profileFuture, discoveriesFuture]);
      final profileData = results[0] as Map<String, dynamic>?;
      final discoveriesList = results[1] as List<dynamic>;

      // Map Backend Discovery to Local Model
      // Backend returns: { imageUrl, object: { commonName, ... }, ... }
      // Model expects: { imagePath, plantData: { commonName, ... } }
      final mappedDiscoveries = discoveriesList.map((d) {
        return Discovery(
          imagePath: d['imageUrl'] ?? "", // Remote URL
          lat: (d['latitude'] as num?)?.toDouble() ?? 0.0,
          lng: (d['longitude'] as num?)?.toDouble() ?? 0.0,
          plantData: {
            "commonName": d['object']?['commonName'] ?? "Unidentified",
            "scientificName": d['object']?['scientificName'],
            "health": {
              "score": d['healthScore'] ?? 0, 
              "status": "Check Details"
            },
            "confidence": d['confidence'] ?? 1.0,
          },
        );
      }).toList();

      if (mounted) {
        setState(() {
          if (profileData != null) {
            userName = profileData['username'] ?? user.displayName ?? "Explorer";
            userXp = profileData['xp'] ?? 0;
            userLevel = profileData['level'] ?? 1;
            userPhoto = user.photoURL; // Backend doesn't store this yet usually
          }
          discoveries = mappedDiscoveries;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading profile: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.greenAccent, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.greenAccent.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ],
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[800],
            backgroundImage: userPhoto != null ? NetworkImage(userPhoto!) : null,
            child: userPhoto == null 
                ? const Icon(Icons.person, size: 50, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          userName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.greenAccent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
          ),
          child: Text(
            "Level $userLevel Botanist",
            style: const TextStyle(
              color: Colors.greenAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem("Total XP", "$userXp", Icons.bolt, Colors.orange),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildStatItem("Plants", "${discoveries.length}", Icons.local_florist, Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildPlantsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Your Garden",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (discoveries.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: Text(
                "No plants found yet.\nStart scanning!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: discoveries.length,
            itemBuilder: (context, index) {
              final discovery = discoveries[index];
              return _buildPlantCard(discovery);
            },
          ),
      ],
    );
  }

  Widget _buildPlantCard(Discovery discovery) {
    // Safety check for plantData
    final data = discovery.plantData;
    final name = (data['commonName']?.toString().isNotEmpty == true) 
        ? data['commonName'] 
        : "Unidentified Plant";
    
    int health = 0;
    if (data['health'] != null && data['health'] is Map) {
      health = (data['health']['score'] is num) 
          ? (data['health']['score'] as num).toInt() 
          : 0;
    }
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ImagePreviewScreen(imagePath: discovery.imagePath),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: (discovery.imagePath.startsWith("http")) 
                ? NetworkImage(discovery.imagePath) 
                : FileImage(File(discovery.imagePath)) as ImageProvider,
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.2), 
              BlendMode.darken
            ),
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Stack(
          children: [
            // Gradient Overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                  ),
                ),
              ),
            ),
            
            // Text Content
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (health > 0)
                  Row(
                    children: [
                      Icon(Icons.favorite, size: 12, color: health > 50 ? Colors.greenAccent : Colors.orangeAccent),
                      const SizedBox(width: 4),
                      Text(
                        "$health% Health",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
