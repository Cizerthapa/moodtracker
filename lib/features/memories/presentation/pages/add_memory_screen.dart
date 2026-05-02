import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moodtrack/core/theme/app_colors.dart';
import 'package:path_provider/path_provider.dart';
import 'package:moodtrack/features/memories/data/repositories/memories_repository.dart';
import 'package:moodtrack/core/di/service_locator.dart';
import 'package:moodtrack/core/error/result.dart';

import 'package:moodtrack/features/memories/domain/model/memories_model.dart';

class AddMemoryScreen extends StatefulWidget {
  const AddMemoryScreen({super.key});

  @override
  State<AddMemoryScreen> createState() => _AddMemoryScreenState();
}

class _AddMemoryScreenState extends State<AddMemoryScreen> {
  final MemoriesRepository _repository = sl<MemoriesRepository>();
  
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _herFavController = TextEditingController();
  final _hisFavController = TextEditingController();
  
  File? _selectedImage;
  bool _isUploading = false;
  bool _isUnique = false;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _saveMemory() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("A title is required")),
      );
      return;
    }

    setState(() => _isUploading = true);

    String? localImagePath;
    if (_selectedImage != null) {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'memory_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await _selectedImage!.copy('${directory.path}/$fileName');
      localImagePath = savedImage.path;
    }

    final combinedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final newMemory = MemoryModel(
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      lat: 27.7172, // TODO: Location picker
      lng: 85.3240, // TODO: Location picker
      imageUrl: localImagePath,
      isUnique: _isUnique,
      herFavStory: _herFavController.text.isEmpty ? null : _herFavController.text.trim(),
      hisFavStory: _hisFavController.text.isEmpty ? null : _hisFavController.text.trim(),
      memoryDate: combinedDateTime,
    );

    HapticFeedback.lightImpact();
    final result = await _repository.addMemory(newMemory);

    if (mounted) {
      if (result is Success) {
        Navigator.pop(context);
      } else {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text((result as Failure).message)),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _herFavController.dispose();
    _hisFavController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.warmBrown),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "New Memory",
          style: GoogleFonts.outfit(color: AppColors.warmBrown, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(28.w, 10.h, 28.w, 40.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Picker UI
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 220.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.ivoryCard,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppColors.champagne),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20.r),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_rounded, color: AppColors.roseDust, size: 48.r),
                          SizedBox(height: 12.h),
                          Text(
                            "Add a Photo",
                            style: GoogleFonts.outfit(color: AppColors.softBrown, fontSize: 16.sp),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: "Title",
                labelStyle: TextStyle(color: AppColors.softBrown),
                filled: true,
                fillColor: AppColors.ivoryCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.champagne),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            
            TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: "Short Note / Description",
                labelStyle: TextStyle(color: AppColors.softBrown),
                filled: true,
                fillColor: AppColors.ivoryCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.champagne),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            
            // Date & Time pickers
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final parsed = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (parsed != null) setState(() => _selectedDate = parsed);
                    },
                    child: Container(
                      padding: EdgeInsets.all(14.r),
                      decoration: BoxDecoration(
                        color: AppColors.ivoryCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.champagne),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 18.r, color: AppColors.roseDust),
                          SizedBox(width: 8.w),
                          Text("${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2,'0')}-${_selectedDate.day.toString().padLeft(2,'0')}", 
                            style: TextStyle(color: AppColors.warmBrown)),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final parsed = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                      );
                      if (parsed != null) setState(() => _selectedTime = parsed);
                    },
                    child: Container(
                      padding: EdgeInsets.all(14.r),
                      decoration: BoxDecoration(
                        color: AppColors.ivoryCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.champagne),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 18.r, color: AppColors.roseDust),
                          SizedBox(width: 8.w),
                          Text(_selectedTime.format(context), 
                            style: TextStyle(color: AppColors.warmBrown)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // Is Unique Switch
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.ivoryCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.champagne),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star_rounded, color: AppColors.roseDeep),
                      SizedBox(width: 12.w),
                      Text("Unique Memory?", style: TextStyle(color: AppColors.warmBrown, fontWeight: FontWeight.bold, fontSize: 16.sp)),
                    ],
                  ),
                  Switch.adaptive(
                    value: _isUnique,
                    activeTrackColor: AppColors.roseDeep,
                    onChanged: (val) => setState(() => _isUnique = val),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),
            TextField(
              controller: _herFavController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Her Favorite Memory",
                labelStyle: TextStyle(color: AppColors.softBrown),
                filled: true,
                fillColor: AppColors.ivoryCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.champagne),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: _hisFavController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "His Favorite Memory",
                labelStyle: TextStyle(color: AppColors.softBrown),
                filled: true,
                fillColor: AppColors.ivoryCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.champagne),
                ),
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _saveMemory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.roseDeep,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: _isUploading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        "Save Memory",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
