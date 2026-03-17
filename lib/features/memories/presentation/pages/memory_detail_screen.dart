import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:moodtrack/core/theme/app_colors.dart';

class MemoryDetailScreen extends StatefulWidget {
  final DocumentSnapshot doc;
  const MemoryDetailScreen({super.key, required this.doc});

  @override
  State<MemoryDetailScreen> createState() => _MemoryDetailScreenState();
}

class _MemoryDetailScreenState extends State<MemoryDetailScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late LatLng _location;
  bool _isEditing = false;
  late AnimationController _heartController;
  late Animation<double> _heartAnim;

  @override
  void initState() {
    super.initState();
    final data = widget.doc.data() as Map<String, dynamic>;
    _titleController = TextEditingController(text: data['title']);
    _descController = TextEditingController(text: data['description']);
    _location = LatLng(data['lat'], data['lng']);

    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _heartAnim = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _heartController.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _updateMemory() async {
    await FirebaseFirestore.instance
        .collection('memories')
        .doc(widget.doc.id)
        .update({
          'title': _titleController.text.trim(),
          'description': _descController.text.trim(),
        });
    setState(() => _isEditing = false);
  }

  Future<void> _deleteMemory() async {
    final bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.ivoryCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text(
              'Forget this memory?',
              style: TextStyle(
                fontFamily: 'Georgia',
                color: AppColors.warmBrown,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'This moment will be gone forever. Are you sure?',
              style: TextStyle(color: AppColors.softBrown, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Keep it',
                  style: TextStyle(color: AppColors.softBrown, fontFamily: 'Georgia'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Let go',
                  style: TextStyle(
                    color: AppColors.roseDeep,
                    fontFamily: 'Georgia',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      await FirebaseFirestore.instance
          .collection('memories')
          .doc(widget.doc.id)
          .delete();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data() as Map<String, dynamic>;
    final bool isUnique = data['isUnique'] == true;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          // ── Collapsible Map Header ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.cream,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: _CircleButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _CircleButton(
                  icon: _isEditing ? Icons.check_rounded : Icons.edit_rounded,
                  onTap: () => _isEditing
                      ? _updateMemory()
                      : setState(() => _isEditing = true),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _CircleButton(
                  icon: Icons.delete_outline_rounded,
                  onTap: _deleteMemory,
                  color: AppColors.roseDeep,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Map
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: _location,
                      initialZoom: 15.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                        subdomains: const ['a', 'b', 'c', 'd'],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _location,
                            width: 64,
                            height: 64,
                            child: ScaleTransition(
                              scale: _heartAnim,
                              child: Icon(
                                isUnique
                                    ? Icons.star_rounded
                                    : Icons.favorite_rounded,
                                color: AppColors.roseDeep,
                                size: 40,
                                shadows: const [
                                  Shadow(
                                    color: Colors.white,
                                    blurRadius: 12,
                                    offset: Offset(0, 0),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Fade-to-cream at the bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 80,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppColors.cream.withOpacity(0), AppColors.cream],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date badge / description chip
                  if (!_isEditing) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.champagne,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isUnique
                                    ? Icons.star_rounded
                                    : Icons.favorite_rounded,
                                size: 14,
                                color: AppColors.roseDeep,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                data['description'] ?? '',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.softBrown,
                                  fontStyle: FontStyle.italic,
                                  fontFamily: 'Georgia',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Text(
                      data['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Georgia',
                        color: AppColors.warmBrown,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Divider with heart
                    _HeartDivider(),
                    const SizedBox(height: 20),

                    // Unique memory callout
                    if (isUnique) ...[
                      _SpecialMemoryCard(),
                      const SizedBox(height: 20),
                    ],

                    // Bottom love note
                    _LoveNoteFooter(),
                    const SizedBox(height: 40),
                  ] else ...[
                    // ── Edit mode ─────────────────────────────────────
                    _EditField(
                      controller: _titleController,
                      label: 'Memory Title',
                      fontSize: 22,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 20),
                    _EditField(
                      controller: _descController,
                      label: 'Date / Description',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _updateMemory,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.roseDeep,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text(
                          'Save Memory',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ────────────────────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.color = AppColors.warmBrown,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.cream.withOpacity(0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.warmBrown.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class _HeartDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(color: AppColors.roseDust.withOpacity(0.5), thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Icon(Icons.favorite, size: 14, color: AppColors.roseDust),
        ),
        Expanded(
          child: Divider(color: AppColors.roseDust.withOpacity(0.5), thickness: 1),
        ),
      ],
    );
  }
}

class _SpecialMemoryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.champagne,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.roseDust.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.star_rounded, color: AppColors.roseDeep, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'A truly special moment — marked as unforgettable.',
              style: TextStyle(
                color: AppColors.softBrown,
                fontSize: 13,
                fontFamily: 'Georgia',
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoveNoteFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.ivoryCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.champagne),
        boxShadow: [
          BoxShadow(
            color: AppColors.roseDust.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.favorite_rounded,
            color: AppColors.roseDust.withOpacity(0.7),
            size: 28,
          ),
          const SizedBox(height: 10),
          Text(
            '"Every moment with you\nis a memory worth keeping."',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Georgia',
              fontStyle: FontStyle.italic,
              fontSize: 15,
              color: AppColors.softBrown,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final double fontSize;

  const _EditField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(
        fontSize: fontSize,
        fontFamily: 'Georgia',
        color: AppColors.warmBrown,
        fontWeight: maxLines == 1 ? FontWeight.bold : FontWeight.normal,
      ),
      cursorColor: AppColors.roseDeep,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.softBrown, fontFamily: 'Georgia'),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.champagne, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.roseDust, width: 1.5),
        ),
        filled: true,
        fillColor: AppColors.ivoryCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
