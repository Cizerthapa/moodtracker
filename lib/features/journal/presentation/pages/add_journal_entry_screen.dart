import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens — pixel-perfect match to the HTML preview
//
//  Page bg       : #FDF8F3  (warm cream)
//  Text primary  : #2C1F0E
//  Text secondary: #7A5C38
//  Text hint     : #B89870
//  Default accent: #C8842A  (amber-gold)
//  Default tint  : #FFF3DC
//  Border light  : rgba(232,217,192, 0.6)
//
//  Fonts
//    UI / labels / stats → DM Sans
//    Page heading        → DM Serif Display
//    Journal textarea    → Playfair Display
//
//  pubspec.yaml — add under google_fonts:
//    - DM Sans
//    - DM Serif Display
//    - Playfair Display
// ─────────────────────────────────────────────────────────────────────────────

class AddJournalEntryScreen extends StatefulWidget {
  final Future<void> Function(String? title, String text, String mood) onSave;
  final List<Map<String, dynamic>> moods;

  const AddJournalEntryScreen({
    super.key,
    required this.onSave,
    required this.moods,
  });

  @override
  State<AddJournalEntryScreen> createState() => _AddJournalEntryScreenState();
}

class _AddJournalEntryScreenState extends State<AddJournalEntryScreen>
    with TickerProviderStateMixin {
  // ── State ────────────────────────────────────────────────────────────────
  final _titleController = TextEditingController();
  final _textController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _focusNode = FocusNode();
  String? _selectedEmoji;
  bool _isSaving = false;

  Color _accentColor = const Color(0xFFC8842A);
  Color _tintColor = const Color(0xFFFFF3DC);
  Color _prevTintColor = const Color(0xFFFFF3DC);

  // ── Animation controllers ────────────────────────────────────────────────
  late AnimationController _bgAnimController;
  late Animation<Color?> _bgColorAnim;

  late AnimationController _emojiPopController;
  late Animation<double> _emojiPopAnim;

  late AnimationController _insightController;
  late Animation<double> _insightAnim;

  bool _wasEmpty = true;

  // ── Helpers ──────────────────────────────────────────────────────────────
  int get _wordCount {
    final t = _textController.text.trim();
    if (t.isEmpty) return 0;
    return t.split(RegExp(r'\s+')).length;
  }

  String get _currentInsight {
    if (widget.moods.isEmpty || _selectedEmoji == null) return '';
    final mood = widget.moods.firstWhere(
      (m) => m['emoji'] == _selectedEmoji,
      orElse: () => widget.moods.first,
    );
    return (mood['insight'] as String?) ?? '';
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    // Background tint crossfade
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Heading-emoji spring pop
    _emojiPopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _emojiPopAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 35),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.35,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 65,
      ),
    ]).animate(_emojiPopController);

    // Insight strip slide-in / slide-out
    _insightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _insightAnim = CurvedAnimation(
      parent: _insightController,
      curve: Curves.easeOut,
    );

    if (widget.moods.isNotEmpty) {
      final first = widget.moods.first;
      _selectedEmoji = first['emoji'] as String;
      _accentColor = first['accent'] as Color;
      _tintColor = first['tint'] as Color;
      _prevTintColor = _tintColor;
    }

    _bgColorAnim = ColorTween(
      begin: _tintColor,
      end: _tintColor,
    ).animate(_bgAnimController);

    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {});
    final isEmpty = _textController.text.trim().isEmpty;
    if (_wasEmpty && !isEmpty) _insightController.forward();
    if (!_wasEmpty && isEmpty) _insightController.reverse();
    _wasEmpty = isEmpty;
  }

  void _selectMood(String emoji) {
    HapticFeedback.lightImpact();
    final meta = widget.moods.firstWhere(
      (m) => m['emoji'] == emoji,
      orElse: () => widget.moods.first,
    );
    final newTint = meta['tint'] as Color;
    final newAccent = meta['accent'] as Color;

    _bgColorAnim = ColorTween(begin: _prevTintColor, end: newTint).animate(
      CurvedAnimation(parent: _bgAnimController, curve: Curves.easeInOut),
    );
    _bgAnimController.forward(from: 0);
    _prevTintColor = newTint;
    _emojiPopController.forward(from: 0);

    setState(() {
      _selectedEmoji = emoji;
      _accentColor = newAccent;
      _tintColor = newTint;
    });
  }

  Future<void> _save() async {
    if (_textController.text.trim().isEmpty || _selectedEmoji == null) {
      HapticFeedback.heavyImpact();
      return;
    }
    setState(() => _isSaving = true);
    await widget.onSave(
      _titleController.text.trim().isEmpty
          ? null
          : _titleController.text.trim(),
      _textController.text.trim(),
      _selectedEmoji!,
    );
    if (mounted) Navigator.pop(context);
  }

  void _insertText(String insertion) {
    final text = _textController.text;
    final selection = _textController.selection;
    
    // Fallback if no selection
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;

    final newText = text.replaceRange(
      start,
      end,
      insertion,
    );
    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: start + insertion.length,
      ),
    );
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    _titleFocusNode.dispose();
    _focusNode.dispose();
    _bgAnimController.dispose();
    _emojiPopController.dispose();
    _insightController.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMMM d').format(now);
    final timeStr = DateFormat('h:mm a').format(now);
    final hasText = _textController.text.trim().isNotEmpty;
    final l10n = AppLocalizations.of(context)!;

    return AnimatedBuilder(
      animation: Listenable.merge([_bgColorAnim, _emojiPopAnim]),
      builder: (context, _) {
        final bg = _bgColorAnim.value ?? _tintColor;

        return Scaffold(
          // Handle keyboard padding manually via SingleChildScrollView padding
          resizeToAvoidBottomInset: false,
          backgroundColor: const Color(0xFFFDF8F3),
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              // ── Animated gradient wash (mood tint → cream) ─────────────
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        bg.withValues(alpha: 0.60),
                        const Color(0xFFFDF8F3).withValues(alpha: 0.94),
                        const Color(0xFFFDF8F3),
                      ],
                      stops: const [0.0, 0.40, 1.0],
                    ),
                  ),
                ),
              ),

              // ── Top-right decorative blob ──────────────────────────────
              Positioned(
                top: -56,
                right: -36,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: 210.r,
                  height: 210.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _accentColor.withValues(alpha: 0.07),
                  ),
                ),
              ),

              // ── Mid-left decorative blob ───────────────────────────────
              Positioned(
                top: 90,
                left: -64,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: 150.r,
                  height: 150.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _accentColor.withValues(alpha: 0.045),
                  ),
                ),
              ),

              // ── Main scrollable content ────────────────────────────────
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.only(
                        top: 10.h,
                        bottom: MediaQuery.of(context).viewInsets.bottom + 40.h,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Top bar: back + date/time ────────────────────────
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            child: Row(
                              children: [
                                // Back button
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    width: 38.r,
                                    height: 38.r,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.88),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _accentColor.withValues(alpha: 0.15),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _accentColor.withValues(alpha: 0.10),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      color: const Color(0xFF2C1F0E),
                                      size: 15.sp,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                // Date / time block
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      dateStr,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF2C1F0E),
                                      ),
                                    ),
                                    SizedBox(height: 1.h),
                                    Text(
                                      timeStr,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 11.sp,
                                        color: const Color(0xFF7A5C38),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 22.h),

                          // ── Heading: "How are you feeling?" + emoji ──────────
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Text(
                                    l10n.howAreYouFeeling,
                                    style: GoogleFonts.dmSerifDisplay(
                                      fontSize: 24.sp,
                                      color: const Color(0xFF2C1F0E),
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                                if (_selectedEmoji != null) ...[
                                  SizedBox(width: 10.w),
                                  ScaleTransition(
                                    scale: _emojiPopAnim,
                                    child: AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 250),
                                      transitionBuilder: (child, anim) =>
                                          FadeTransition(opacity: anim, child: child),
                                      child: Text(
                                        _selectedEmoji!,
                                        key: ValueKey(_selectedEmoji),
                                        style: TextStyle(fontSize: 24.sp),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(height: 10.h),

                          // ── Horizontal mood chips ────────────────────────────
                          SizedBox(
                            height: 78.h,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(horizontal: 24.w),
                              physics: const BouncingScrollPhysics(),
                              itemCount: widget.moods.length,
                              separatorBuilder: (_, _) => SizedBox(width: 8.w),
                              itemBuilder: (context, i) {
                                final m = widget.moods[i];
                                final emoji = m['emoji'] as String;
                                final label = m['label'] as String;
                                final accent = m['accent'] as Color;
                                final tint = m['tint'] as Color;
                                return _MoodChip(
                                  emoji: emoji,
                                  label: label,
                                  accent: accent,
                                  tint: tint,
                                  selected: emoji == _selectedEmoji,
                                  onTap: () => _selectMood(emoji),
                                );
                              },
                            ),
                          ),

                          SizedBox(height: 14.h),

                          // ── Triple accent divider ────────────────────────────
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: Row(
                              children: [
                                _DivBar(width: 28.w, color: _accentColor),
                                SizedBox(width: 5.w),
                                _DivBar(
                                  width: 10.w,
                                  color: _accentColor.withValues(alpha: 0.4),
                                ),
                                SizedBox(width: 5.w),
                                _DivBar(
                                  width: 5.w,
                                  color: _accentColor.withValues(alpha: 0.2),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 14.h),

                          // ── Writing canvas ───────────────────────────────────
                          GestureDetector(
                            onTap: () => _focusNode.requestFocus(),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              constraints: BoxConstraints(minHeight: 320.h),
                              margin: EdgeInsets.symmetric(horizontal: 18.w),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.88),
                                borderRadius: BorderRadius.circular(24.r),
                                border: Border.all(
                                  color: _accentColor.withValues(
                                    alpha: hasText ? 0.30 : 0.15,
                                  ),
                                  width: hasText ? 1.2 : 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _accentColor.withValues(alpha: 0.07),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Thin rule under header
                                  Container(
                                    height: 0.5,
                                    color: _accentColor.withValues(alpha: 0.10),
                                  ),

                                  // Title Field
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 0),
                                    child: TextField(
                                      controller: _titleController,
                                      focusNode: _titleFocusNode,
                                      style: GoogleFonts.dmSerifDisplay(
                                        fontSize: 22.sp,
                                        color: const Color(0xFF2C1F0E),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Entry Title...',
                                        hintStyle: GoogleFonts.dmSerifDisplay(
                                          fontSize: 20.sp,
                                          color: const Color(0xFFB89870).withValues(alpha: 0.4),
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      textInputAction: TextInputAction.next,
                                      onSubmitted: (_) => _focusNode.requestFocus(),
                                    ),
                                  ),

                                  // Text field
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 18.h),
                                    child: TextField(
                                      controller: _textController,
                                      focusNode: _focusNode,
                                      autofocus: true,
                                      maxLines: null,
                                      style: GoogleFonts.playfairDisplay(
                                        fontSize: 15.sp,
                                        color: const Color(0xFF2C1F0E),
                                        height: 1.8,
                                      ),
                                      cursorColor: _accentColor,
                                      decoration: InputDecoration(
                                        hintText: 'Let your thoughts flow freely…',
                                        hintStyle: GoogleFonts.playfairDisplay(
                                          fontSize: 14.sp,
                                          fontStyle: FontStyle.italic,
                                          color: const Color(0xFFB89870).withValues(alpha: 0.55),
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // ── Formatting toolbar ──────────────────────────────
                          Padding(
                            padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 0),
                            child: Row(
                              children: [
                                _FormatButton(
                                  icon: Icons.format_list_bulleted_rounded,
                                  onTap: () => _insertText('• '),
                                  color: _accentColor,
                                ),
                                SizedBox(width: 8.w),
                                _FormatButton(
                                  icon: Icons.checklist_rounded,
                                  onTap: () => _insertText('- [ ] '),
                                  color: _accentColor,
                                ),
                              ],
                            ),
                          ),

                          // ── Insight strip ──────────────────────────────────
                          SizeTransition(
                            sizeFactor: _insightAnim,
                            axisAlignment: -1,
                            child: FadeTransition(
                              opacity: _insightAnim,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 0),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                                  decoration: BoxDecoration(
                                    color: _tintColor,
                                    borderRadius: BorderRadius.circular(14.r),
                                    border: Border.all(color: _accentColor.withValues(alpha: 0.22)),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('✦', style: TextStyle(fontSize: 12.sp, color: _accentColor)),
                                      SizedBox(width: 8.w),
                                      Expanded(
                                        child: Text(
                                          _currentInsight,
                                          style: GoogleFonts.dmSans(
                                            fontSize: 12.sp,
                                            color: const Color(0xFF7A5C38),
                                            height: 1.45,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 10.h),

                          // ── Bottom bar: word count + save button ─────────────
                          Container(
                            margin: EdgeInsets.fromLTRB(18.w, 0, 18.w, 24.h),
                            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(24.r),
                              border: Border.all(color: const Color(0xFFE8D9C0).withValues(alpha: 0.55)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 14,
                                  offset: const Offset(0, -3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 220),
                                      transitionBuilder: (child, anim) => SlideTransition(
                                        position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(anim),
                                        child: FadeTransition(opacity: anim, child: child),
                                      ),
                                      child: Text(
                                        '$_wordCount',
                                        key: ValueKey(_wordCount),
                                        style: GoogleFonts.dmSans(
                                          fontSize: 22.sp,
                                          fontWeight: FontWeight.w500,
                                          height: 1.0,
                                          color: hasText ? _accentColor : const Color(0xFF7A5C38),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      'words written',
                                      style: GoogleFonts.dmSans(fontSize: 10.sp, color: const Color(0xFFB89870)),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                if (_isSaving)
                                  SizedBox(
                                    width: 46.r,
                                    height: 46.r,
                                    child: Padding(
                                      padding: EdgeInsets.all(12.r),
                                      child: CircularProgressIndicator(strokeWidth: 2.5, color: _accentColor),
                                    ),
                                  )
                                else
                                  GestureDetector(
                                    onTap: hasText ? _save : null,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 280),
                                      curve: Curves.easeOut,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: hasText ? 22.w : 16.w,
                                        vertical: 13.h,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: hasText
                                            ? LinearGradient(
                                                colors: [_accentColor, _accentColor.withValues(alpha: 0.78)],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              )
                                            : LinearGradient(
                                                colors: [
                                                  const Color(0xFFE8D9C0).withValues(alpha: 0.6),
                                                  const Color(0xFFE8D9C0).withValues(alpha: 0.6),
                                                ],
                                              ),
                                        borderRadius: BorderRadius.circular(50.r),
                                        boxShadow: hasText
                                            ? [
                                                BoxShadow(
                                                  color: _accentColor.withValues(alpha: 0.32),
                                                  blurRadius: 16,
                                                  offset: const Offset(0, 5),
                                                ),
                                              ]
                                            : [],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 15.sp),
                                          SizedBox(width: 8.w),
                                          Text(
                                            'Save Entry',
                                            style: GoogleFonts.dmSans(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _MoodChip extends StatelessWidget {
  final String emoji;
  final String label;
  final Color accent;
  final Color tint;
  final bool selected;
  final VoidCallback onTap;

  const _MoodChip({
    required this.emoji,
    required this.label,
    required this.accent,
    required this.tint,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, selected ? -3 : 0, 0),
        padding: EdgeInsets.symmetric(horizontal: selected ? 16.w : 12.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: selected ? tint : Colors.white.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: selected ? accent : const Color(0xFFE8D9C0).withValues(alpha: 0.6),
            width: selected ? 1.5 : 1.0,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: selected ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutBack,
              child: Text(emoji, style: TextStyle(fontSize: 22.sp)),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 10.sp,
                color: selected ? accent : const Color(0xFF7A5C38),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DivBar extends StatelessWidget {
  final double width;
  final Color color;
  const _DivBar({required this.width, required this.color});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        width: width,
        height: 2.5.h,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
      );
}

class _FormatButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _FormatButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Icon(icon, size: 18.sp, color: color),
      ),
    );
  }
}
