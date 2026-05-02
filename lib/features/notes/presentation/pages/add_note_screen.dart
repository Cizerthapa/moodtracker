import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moodtrack/l10n/app_localizations.dart';
import 'dart:io';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Mood metadata: emoji, label, card tint, accent color (matching NotesScreen)
final _moods = [
  {
    'emoji': '😊',
    'label': AppStrings.moodHappy,
    'tint': const Color(0xFFFFF8EC),
    'accent': const Color(0xFFD4A832),
  },
  {
    'emoji': '😌',
    'label': AppStrings.moodPeaceful,
    'tint': const Color(0xFFEEF7F0),
    'accent': const Color(0xFF6DAA7A),
  },
  {
    'emoji': '😐',
    'label': AppStrings.moodNeutral,
    'tint': const Color(0xFFF5F2ED),
    'accent': const Color(0xFF9C8878),
  },
  {
    'emoji': '😔',
    'label': AppStrings.moodSad,
    'tint': const Color(0xFFEFF3FA),
    'accent': const Color(0xFF7A8FBB),
  },
  {
    'emoji': '😡',
    'label': AppStrings.moodUpset,
    'tint': const Color(0xFFFFF0EC),
    'accent': const Color(0xFFC4635A),
  },
  {
    'emoji': '😭',
    'label': AppStrings.moodCrying,
    'tint': const Color(0xFFEFF3FA),
    'accent': const Color(0xFF6B8CB8),
  },
];

class AddNoteScreen extends StatefulWidget {
  final Function(String title, String text, String emoji, dynamic image) onSave;
  final String? initialTitle;
  final String? initialText;
  final String? initialEmoji;
  final String? initialImage;

  const AddNoteScreen({
    super.key, 
    required this.onSave,
    this.initialTitle,
    this.initialText,
    this.initialEmoji,
    this.initialImage,
  });

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  final _titleFocusNode = FocusNode();
  final _contentFocusNode = FocusNode();

  late String _selectedEmoji;
  File? _selectedImage;
  String? _existingImageUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _contentController = TextEditingController(text: widget.initialText);
    _selectedEmoji = widget.initialEmoji ?? _moods[0]['emoji'] as String;
    _existingImageUrl = widget.initialImage;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      HapticFeedback.lightImpact();
      setState(() {
        _selectedImage = File(pickedFile.path);
        _existingImageUrl = null;
      });
    }
  }

  void _insertText(String insertion) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      insertion,
    );
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + insertion.length,
      ),
    );
    _contentFocusNode.requestFocus();
    HapticFeedback.lightImpact();
  }

  Future<void> _save() async {
    if (_contentController.text.trim().isEmpty) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something before saving.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    await widget.onSave(
      _titleController.text.trim(),
      _contentController.text.trim(),
      _selectedEmoji,
      _selectedImage ?? _existingImageUrl,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final moodMeta = _moods.firstWhere((m) => m['emoji'] == _selectedEmoji);
    final accentColor = moodMeta['accent'] as Color;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: AppColors.warmBrown),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isSaving)
            Padding(
              padding: EdgeInsets.only(right: 20.w),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.roseDeep,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text(
                'Save',
                style: GoogleFonts.outfit(
                  color: AppColors.roseDeep,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
            ),
          SizedBox(width: 8.w),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Field
                  TextField(
                    controller: _titleController,
                    focusNode: _titleFocusNode,
                    style: GoogleFonts.outfit(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.warmBrown,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Title',
                      hintStyle: GoogleFonts.outfit(
                        color: AppColors.softBrown.withValues(alpha: 0.3),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  SizedBox(height: 16.h),

                  // Content Field
                  TextField(
                    controller: _contentController,
                    focusNode: _contentFocusNode,
                    maxLines: null,
                    style: GoogleFonts.outfit(
                      fontSize: 18.sp,
                      color: AppColors.warmBrown,
                      height: 1.6,
                    ),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.startWritingHint,
                      hintStyle: GoogleFonts.outfit(
                        color: AppColors.softBrown.withValues(alpha: 0.35),
                        fontStyle: FontStyle.italic,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),

                  // Image Preview
                  if (_selectedImage != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16.r),
                          child: Image.file(
                            _selectedImage!,
                            height: 200.h,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8.h,
                          right: 8.w,
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() => _selectedImage = null);
                            },
                            child: Container(
                              padding: EdgeInsets.all(4.r),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 16.r,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else if (_existingImageUrl != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16.r),
                          child: Image.network(
                            _existingImageUrl!,
                            height: 200.h,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8.h,
                          right: 8.w,
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() => _existingImageUrl = null);
                            },
                            child: Container(
                              padding: EdgeInsets.all(4.r),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 16.r,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                  SizedBox(
                    height: 100.h,
                  ), // Extra space to scroll above keyboard
                ],
              ),
            ),
          ),

          // Bottom Toolbar
          Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 8.h,
              top: 8.h,
              left: 16.w,
              right: 16.w,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mood Selector
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Row(
                    children: _moods.map((m) {
                      final emoji = m['emoji'] as String;
                      final isSelected = emoji == _selectedEmoji;
                      final mAccent = m['accent'] as Color;

                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _selectedEmoji = emoji);
                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 6.w),
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? mAccent.withValues(alpha: 0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: isSelected
                                  ? mAccent.withValues(alpha: 0.4)
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Text(emoji, style: TextStyle(fontSize: 22.sp)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Divider(
                  height: 16.h,
                  color: AppColors.champagne.withValues(alpha: 0.5),
                ),
                Row(
                  children: [
                    // Bullet button
                    IconButton(
                      icon: Icon(
                        Icons.format_list_bulleted_rounded,
                        color: AppColors.softBrown,
                      ),
                      onPressed: () => _insertText('• '),
                    ),
                    // Checklist button
                    IconButton(
                      icon: Icon(
                        Icons.checklist_rounded,
                        color: AppColors.softBrown,
                      ),
                      onPressed: () => _insertText('- [ ] '),
                    ),
                    // Image button
                    IconButton(
                      icon: Icon(
                        Icons.add_a_photo_rounded,
                        color: AppColors.softBrown,
                      ),
                      onPressed: _pickImage,
                    ),
                    const Spacer(),
                    // Mood Indicator Circle
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      moodMeta['label'] as String,
                      style: GoogleFonts.outfit(
                        fontSize: 12.sp,
                        color: AppColors.softBrown,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 8.w),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
