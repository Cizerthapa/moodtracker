import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moodtrack/core/theme/app_colors.dart';
import 'package:moodtrack/features/memories/data/repositories/memories_repository.dart';
import 'package:moodtrack/features/memories/domain/model/memories_model.dart';
import 'package:moodtrack/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class MemoryDetailScreen extends StatefulWidget {
  final MemoryModel memory;
  const MemoryDetailScreen({super.key, required this.memory});

  @override
  State<MemoryDetailScreen> createState() => _MemoryDetailScreenState();
}

class _MemoryDetailScreenState extends State<MemoryDetailScreen>
    with TickerProviderStateMixin {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _herFavController;
  late TextEditingController _hisFavController;
  late LatLng _location;
  late MemoryModel _memory;
  bool _isEditing = false;
  late AnimationController _heartController;
  late AnimationController _fadeController;
  late Animation<double> _heartAnim;
  late Animation<double> _fadeAnim;
  final MemoriesRepository _repository = MemoriesRepository();
  List<File> _additionalImages = [];

  @override
  void initState() {
    super.initState();
    _memory = widget.memory;
    _titleController = TextEditingController(text: _memory.title);
    _descController = TextEditingController(text: _memory.description);
    _herFavController = TextEditingController(text: _memory.herFavStory ?? '');
    _hisFavController = TextEditingController(text: _memory.hisFavStory ?? '');
    _location = LatLng(_memory.lat, _memory.lng);

    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _heartAnim = Tween<double>(begin: 1.0, end: 1.22).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _loadLocalImages();
  }

  Future<void> _loadLocalImages() async {
    final int count = _memory.imageCount;
    if (count == 0 || _memory.id == null) {
      return;
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      final List<File> loaded = [];
      for (int i = 0; i < count; i++) {
        final f = File('${dir.path}/memory_${_memory.id}_img_$i.jpg');
        if (await f.exists()) {
          loaded.add(f);
        }
      }
      if (mounted) {
        setState(() {
          _additionalImages = loaded;
        });
      }
    } catch (_) {
      // Ignored
    }
  }

  @override
  void dispose() {
    _heartController.dispose();
    _fadeController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _herFavController.dispose();
    _hisFavController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_additionalImages.length >= 25) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Maximum 25 images allowed')));
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 70);
    if (picked.isNotEmpty) {
      int availableSlots = 25 - _additionalImages.length;
      final toAdd = picked
          .take(availableSlots)
          .map((x) => File(x.path))
          .toList();
      setState(() {
        _additionalImages.addAll(toAdd);
      });
      if (picked.length > availableSlots) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Only $availableSlots more images could be added, max 25 reached.',
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _updateMemory() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final memoryId = _memory.id;
      if (memoryId == null) return;

      int count = 0;
      for (var file in _additionalImages) {
        final newPath = '${dir.path}/memory_${memoryId}_img_$count.jpg';
        if (file.path != newPath) {
          await file.copy(newPath);
        }
        count++;
      }
      int oldCount = _memory.imageCount;
      for (int i = count; i < oldCount; i++) {
        final f = File('${dir.path}/memory_${memoryId}_img_$i.jpg');
        if (await f.exists()) await f.delete();
      }

      final updatedMemory = _memory.copyWith(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        herFavStory: _herFavController.text.trim().isEmpty
            ? null
            : _herFavController.text.trim(),
        hisFavStory: _hisFavController.text.trim().isEmpty
            ? null
            : _hisFavController.text.trim(),
        imageCount: count,
      );

      await _repository.updateMemory(updatedMemory);

      setState(() {
        _memory = updatedMemory;
        _isEditing = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save memory: $e')));
      }
    }
  }

  Future<void> _deleteMemory() async {
    final bool confirm =
        await showModalBottomSheet<bool>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => _DeleteSheet(),
        ) ??
        false;

    if (confirm) {
      if (_memory.id != null) {
        await _repository.deleteMemory(_memory.id!);
      }
      if (mounted) Navigator.pop(context);
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    DateTime dt;
    if (date is DateTime) {
      dt = date;
    } else if (date.runtimeType.toString().contains('Timestamp')) {
      dt = (date as dynamic).toDate();
    } else {
      return date.toString();
    }
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}  ·  $hour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final bool isUnique = _memory.isUnique;
    final String? herFav = _memory.herFavStory;
    final String? hisFav = _memory.hisFavStory;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Hero Map / Image Header ─────────────────────────────────
            SliverAppBar(
              expandedHeight: 340.h,
              pinned: true,
              backgroundColor: AppColors.cream,
              elevation: 0,
              leading: Padding(
                padding: EdgeInsets.all(8.r),
                child: _GlassButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.pop(context),
                ),
              ),
              actions: [
                Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: _GlassButton(
                    icon: _isEditing ? Icons.check_rounded : Icons.edit_rounded,
                    onTap: () => _isEditing
                        ? _updateMemory()
                        : setState(() => _isEditing = true),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(right: 16.w),
                  child: _GlassButton(
                    icon: Icons.delete_outline_rounded,
                    onTap: _deleteMemory,
                    tint: AppColors.roseDeep,
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _HeroSection(
                  memory: _memory,
                  location: _location,
                  heartAnim: _heartAnim,
                  isUnique: isUnique,
                ),
              ),
            ),

            // ── Body ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _isEditing
                  ? _EditPanel(
                      titleController: _titleController,
                      descController: _descController,
                      herFavController: _herFavController,
                      hisFavController: _hisFavController,
                      additionalImages: _additionalImages,
                      onPickImages: _pickImages,
                      onRemoveImage: (index) {
                        setState(() => _additionalImages.removeAt(index));
                      },
                      onSave: _updateMemory,
                      onCancel: () => setState(() => _isEditing = false),
                    )
                  : _ViewPanel(
                      memory: _memory,
                      isUnique: isUnique,
                      herFav: herFav,
                      hisFav: hisFav,
                      additionalImages: _additionalImages,
                      formatDate: _formatDate,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hero Section ──────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final MemoryModel memory;
  final LatLng location;
  final Animation<double> heartAnim;
  final bool isUnique;

  const _HeroSection({
    required this.memory,
    required this.location,
    required this.heartAnim,
    required this.isUnique,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = memory.imageUrl != null;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background: photo or map
        if (hasImage)
          _MemoryImage(url: memory.imageUrl!)
        else
          FlutterMap(
            options: MapOptions(
              initialCenter: location,
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
                    point: location,
                    width: 64.r,
                    height: 64.r,
                    child: ScaleTransition(
                      scale: heartAnim,
                      child: Icon(
                        isUnique ? Icons.star_rounded : Icons.favorite_rounded,
                        color: AppColors.roseDeep,
                        size: 42.sp,
                        shadows: [
                          Shadow(color: Colors.white, blurRadius: 16.r),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

        // Gradient scrim — always
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.5, 1.0],
                colors: [
                  Colors.black.withValues(alpha: 0.15),
                  Colors.transparent,
                  AppColors.cream,
                ],
              ),
            ),
          ),
        ),

        // If image shown, small pulsing map pip in corner
        if (hasImage)
          Positioned(
            bottom: 70.h,
            right: 20.w,
            child: _MapPip(
              location: location,
              heartAnim: heartAnim,
              isUnique: isUnique,
            ),
          ),
      ],
    );
  }
}

class _MemoryImage extends StatelessWidget {
  final String url;
  const _MemoryImage({required this.url});

  @override
  Widget build(BuildContext context) {
    final isNetwork = url.startsWith('http');
    return isNetwork
        ? Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _ImageFallback(),
          )
        : Image.file(
            File(url),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _ImageFallback(),
          );
  }
}

class _ImageFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.champagne,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: AppColors.softBrown,
          size: 48.sp,
        ),
      ),
    );
  }
}

class _MapPip extends StatelessWidget {
  final LatLng location;
  final Animation<double> heartAnim;
  final bool isUnique;

  const _MapPip({
    required this.location,
    required this.heartAnim,
    required this.isUnique,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: SizedBox(
        width: 110.w,
        height: 80.h,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: location,
                initialZoom: 14.0,
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
                      point: location,
                      width: 28.r,
                      height: 28.r,
                      child: ScaleTransition(
                        scale: heartAnim,
                        child: Icon(
                          isUnique
                              ? Icons.star_rounded
                              : Icons.favorite_rounded,
                          color: AppColors.roseDeep,
                          size: 20.sp,
                          shadows: [
                            Shadow(color: Colors.white, blurRadius: 8.r),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // border overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── View Panel ─────────────────────────────────────────────────────────────

class _ViewPanel extends StatelessWidget {
  final MemoryModel memory;
  final bool isUnique;
  final String? herFav;
  final String? hisFav;
  final List<File> additionalImages;
  final String Function(dynamic) formatDate;

  const _ViewPanel({
    required this.memory,
    required this.isUnique,
    required this.herFav,
    required this.hisFav,
    required this.additionalImages,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 60.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 4.h),

          // ── Unique badge ─────────────────────────────────────────────
          if (isUnique) ...[_UniqueBadge(), SizedBox(height: 14.h)],

          // ── Title ────────────────────────────────────────────────────
          Text(
            memory.title,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 38.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.warmBrown,
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 10.h),

          // ── Date pill ────────────────────────────────────────────────
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 13.sp,
                color: AppColors.roseDust,
              ),
              SizedBox(width: 6.w),
              Text(
                formatDate(memory.memoryDate ?? memory.timestamp),
                style: GoogleFonts.outfit(
                  fontSize: 12.sp,
                  color: AppColors.softBrown,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // ── Ornamental divider ───────────────────────────────────────
          _OrnamentalDivider(),
          SizedBox(height: 24.h),

          // ── Description ──────────────────────────────────────────────
          if (memory.description.isNotEmpty) ...[
            Text(
              memory.description,
              style: GoogleFonts.lora(
                fontSize: 15.sp,
                color: AppColors.softBrown,
                height: 1.75,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 28.h),
          ],

          // ── Favorite stories ─────────────────────────────────────────
          if (herFav != null || hisFav != null) ...[
            _StoryCards(herFav: herFav, hisFav: hisFav),
            SizedBox(height: 28.h),
          ],

          if (additionalImages.isNotEmpty) ...[
            Text(
              'Captured Moments',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.warmBrown,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(height: 14.h),
            SizedBox(
              height: 140.h,
              child: ListView.builder(
                physics: BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                itemCount: additionalImages.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: EdgeInsets.only(right: 16.w),
                    width: 110.r,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.r),
                      image: DecorationImage(
                        image: FileImage(additionalImages[index]),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8.r,
                          offset: Offset(0, 4.h),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 28.h),
          ],

          // ── Love note footer ─────────────────────────────────────────
          _LoveNoteCard(),
        ],
      ),
    );
  }
}

// ─── Edit Panel ─────────────────────────────────────────────────────────────

class _EditPanel extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descController;
  final TextEditingController herFavController;
  final TextEditingController hisFavController;
  final List<File> additionalImages;
  final VoidCallback onPickImages;
  final Function(int) onRemoveImage;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _EditPanel({
    required this.titleController,
    required this.descController,
    required this.herFavController,
    required this.hisFavController,
    required this.additionalImages,
    required this.onPickImages,
    required this.onRemoveImage,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 60.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit Memory',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 28.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.warmBrown,
            ),
          ),
          SizedBox(height: 20.h),
          _StyledField(
            controller: titleController,
            label: 'Title',
            maxLines: 1,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
          SizedBox(height: 16.h),
          _StyledField(
            controller: descController,
            label: 'Short Note / Description',
            maxLines: 4,
          ),
          SizedBox(height: 16.h),
          _StyledField(
            controller: herFavController,
            label: 'Her Favorite Story',
            maxLines: 3,
          ),
          SizedBox(height: 16.h),
          _StyledField(
            controller: hisFavController,
            label: 'His Favorite Story',
            maxLines: 3,
          ),
          SizedBox(height: 24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Extra Memories (${additionalImages.length}/25)',
                style: GoogleFonts.outfit(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warmBrown,
                ),
              ),
              TextButton.icon(
                onPressed: onPickImages,
                icon: Icon(
                  Icons.add_a_photo_rounded,
                  size: 16.sp,
                  color: AppColors.roseDeep,
                ),
                label: Text(
                  'Add Photos',
                  style: GoogleFonts.outfit(
                    color: AppColors.roseDeep,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (additionalImages.isNotEmpty)
            SizedBox(
              height: 100.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: additionalImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        margin: EdgeInsets.only(right: 12.w, top: 8.h),
                        width: 90.r,
                        height: 90.r,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          image: DecorationImage(
                            image: FileImage(additionalImages[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 4.w,
                        child: GestureDetector(
                          onTap: () => onRemoveImage(index),
                          child: Container(
                            padding: EdgeInsets.all(4.r),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black26, blurRadius: 4),
                              ],
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 14.sp,
                              color: AppColors.roseDust,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          SizedBox(height: 28.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.softBrown,
                    side: BorderSide(color: AppColors.champagne, width: 1.5),
                    padding: EdgeInsets.symmetric(vertical: 15.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.outfit(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.roseDeep,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 15.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  icon: Icon(Icons.check_rounded, size: 18.sp),
                  label: Text(
                    'Save Changes',
                    style: GoogleFonts.outfit(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Sub-components ──────────────────────────────────────────────────────────

class _UniqueBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.roseDeep.withValues(alpha: 0.15),
            AppColors.champagne,
          ],
        ),
        borderRadius: BorderRadius.circular(50.r),
        border: Border.all(
          color: AppColors.roseDust.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 14.sp, color: AppColors.roseDeep),
          SizedBox(width: 6.w),
          Text(
            'Special Memory',
            style: GoogleFonts.outfit(
              fontSize: 12.sp,
              color: AppColors.roseDeep,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrnamentalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.champagne.withValues(alpha: 0),
                  AppColors.roseDust.withValues(alpha: 0.5),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Row(
            children: [
              Icon(Icons.favorite, size: 8.sp, color: AppColors.roseDust),
              SizedBox(width: 5.w),
              Icon(Icons.favorite, size: 12.sp, color: AppColors.roseDust),
              SizedBox(width: 5.w),
              Icon(Icons.favorite, size: 8.sp, color: AppColors.roseDust),
            ],
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.roseDust.withValues(alpha: 0.5),
                  AppColors.champagne.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StoryCards extends StatelessWidget {
  final String? herFav;
  final String? hisFav;

  const _StoryCards({this.herFav, this.hisFav});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Our Perspectives',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.warmBrown,
            letterSpacing: 0.3,
          ),
        ),
        SizedBox(height: 14.h),
        if (herFav != null)
          _PerspectiveCard(
            label: 'Her Story',
            text: herFav!,
            icon: Icons.favorite_rounded,
            accentColor: const Color(0xFFE8A5B0),
            isLeft: true,
          ),
        if (herFav != null && hisFav != null) SizedBox(height: 12.h),
        if (hisFav != null)
          _PerspectiveCard(
            label: 'His Story',
            text: hisFav!,
            icon: Icons.favorite_rounded,
            accentColor: const Color(0xFFB5C4D8),
            isLeft: false,
          ),
      ],
    );
  }
}

class _PerspectiveCard extends StatelessWidget {
  final String label;
  final String text;
  final IconData icon;
  final Color accentColor;
  final bool isLeft;

  const _PerspectiveCard({
    required this.label,
    required this.text,
    required this.icon,
    required this.accentColor,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: AppColors.ivoryCard,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isLeft ? 4.r : 20.r),
          topRight: Radius.circular(isLeft ? 20.r : 4.r),
          bottomLeft: Radius.circular(20.r),
          bottomRight: Radius.circular(20.r),
        ),
        border: Border.all(color: AppColors.champagne),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.12),
            blurRadius: 16.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28.r,
                height: 28.r,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14.sp, color: accentColor),
              ),
              SizedBox(width: 10.w),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.softBrown,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            text,
            style: GoogleFonts.lora(
              fontSize: 14.sp,
              color: AppColors.warmBrown,
              height: 1.7,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoveNoteCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 28.h, horizontal: 24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.ivoryCard,
            AppColors.champagne.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: AppColors.champagne),
        boxShadow: [
          BoxShadow(
            color: AppColors.roseDust.withValues(alpha: 0.1),
            blurRadius: 24.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_rounded,
                size: 10.sp,
                color: AppColors.roseDust.withValues(alpha: 0.5),
              ),
              SizedBox(width: 6.w),
              Icon(
                Icons.favorite_rounded,
                size: 16.sp,
                color: AppColors.roseDust,
              ),
              SizedBox(width: 6.w),
              Icon(
                Icons.favorite_rounded,
                size: 10.sp,
                color: AppColors.roseDust.withValues(alpha: 0.5),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Text(
            AppLocalizations.of(context)!.loveNoteText,
            textAlign: TextAlign.center,
            style: GoogleFonts.cormorantGaramond(
              fontStyle: FontStyle.italic,
              fontSize: 17.sp,
              color: AppColors.softBrown,
              height: 1.7,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? tint;

  const _GlassButton({required this.icon, required this.onTap, this.tint});

  @override
  Widget build(BuildContext context) {
    final color = tint ?? AppColors.warmBrown;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40.r,
        height: 40.r,
        decoration: BoxDecoration(
          color: AppColors.cream.withValues(alpha: 0.88),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.12), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 12.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Icon(icon, size: 17.sp, color: color),
      ),
    );
  }
}

class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final double? fontSize;
  final FontWeight? fontWeight;

  const _StyledField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.fontSize,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.lora(
        fontSize: fontSize ?? 14.sp,
        color: AppColors.warmBrown,
        fontWeight: fontWeight ?? FontWeight.normal,
      ),
      cursorColor: AppColors.roseDeep,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(
          color: AppColors.softBrown,
          fontSize: 13.sp,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: AppColors.champagne, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: AppColors.roseDust, width: 1.5),
        ),
        filled: true,
        fillColor: AppColors.ivoryCard,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      ),
    );
  }
}

class _DeleteSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 32.h),
      padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 24.h),
      decoration: BoxDecoration(
        color: AppColors.ivoryCard,
        borderRadius: BorderRadius.circular(28.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            margin: EdgeInsets.only(bottom: 24.h),
            decoration: BoxDecoration(
              color: AppColors.champagne,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Container(
            width: 56.r,
            height: 56.r,
            decoration: BoxDecoration(
              color: AppColors.roseDeep.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.delete_outline_rounded,
              color: AppColors.roseDeep,
              size: 26.sp,
            ),
          ),
          SizedBox(height: 18.h),
          Text(
            'Let this memory go?',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.warmBrown,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            'This memory will be gone forever.\nAre you sure?',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14.sp,
              color: AppColors.softBrown,
              height: 1.5,
            ),
          ),
          SizedBox(height: 28.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.softBrown,
                    side: BorderSide(color: AppColors.champagne, width: 1.5),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    'Keep It',
                    style: GoogleFonts.outfit(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.roseDeep,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    'Let Go',
                    style: GoogleFonts.outfit(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
