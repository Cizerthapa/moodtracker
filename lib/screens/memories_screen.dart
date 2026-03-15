import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  final MapController _mapController = MapController();
  List<Map<String, dynamic>> _memories = [];
  LatLng _currentCenter = const LatLng(51.509364, -0.128928); // London default

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  Future<void> _initMap() async {
    await _loadMemories();
    await _getCurrentLocation();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadMemories() async {
    final prefs = await SharedPreferences.getInstance();
    final memoriesJson = prefs.getStringList('memories') ?? [];
    setState(() {
      _memories = memoriesJson.map((e) => json.decode(e) as Map<String, dynamic>).toList();
    });
  }

  Future<void> _saveMemory(String title, String desc, LatLng location) async {
    final newMemory = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'description': desc,
      'date': DateTime.now().toIso8601String(),
      'lat': location.latitude,
      'lng': location.longitude,
    };
    
    setState(() {
      _memories.add(newMemory);
    });

    final prefs = await SharedPreferences.getInstance();
    final memoriesJson = _memories.map((e) => json.encode(e)).toList();
    await prefs.setStringList('memories', memoriesJson);
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentCenter = LatLng(position.latitude, position.longitude);
    });
    _mapController.move(_currentCenter, 13.0);
  }

  void _showAddMemoryDialog(LatLng point) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pin a Memory',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF9E77ED)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF9E77ED)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9E77ED),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    if (titleController.text.trim().isNotEmpty) {
                      _saveMemory(
                        titleController.text.trim(),
                        descController.text.trim(),
                        point,
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save Memory', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMemoryDetails(Map<String, dynamic> memory) {
    showDialog(
      context: context,
      builder: (context) {
        final date = DateTime.parse(memory['date']);
        final formattedDate = DateFormat('MMM d, yyyy - h:mm a').format(date);
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(memory['title'], style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(formattedDate, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 12),
              Text(memory['description'], style: const TextStyle(color: Colors.white70)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Color(0xFF9E77ED))),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Memories'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF9E77ED)))
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentCenter,
                initialZoom: 13.0,
                onLongPress: (tapPosition, point) {
                  _showAddMemoryDialog(point);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                ),
                MarkerLayer(
                  markers: _memories.map((m) {
                    return Marker(
                      point: LatLng(m['lat'], m['lng']),
                      width: 60,
                      height: 60,
                      child: GestureDetector(
                        onTap: () => _showMemoryDetails(m),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFF9E77ED),
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 4)],
                              ),
                              child: const Icon(Icons.favorite, color: Colors.white, size: 20),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF9E77ED),
        onPressed: () {
          // Default to center if they press the FAB
          _showAddMemoryDialog(_currentCenter);
        },
        icon: const Icon(Icons.add_location_alt, color: Colors.white),
        label: const Text('Add Memory', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
