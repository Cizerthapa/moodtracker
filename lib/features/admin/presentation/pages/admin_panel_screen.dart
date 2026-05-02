import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moodtrack/core/models/user_profile_model.dart';
import 'package:moodtrack/features/admin/data/repositories/admin_repository.dart';
import 'package:moodtrack/core/di/service_locator.dart';

import 'package:moodtrack/features/memories/domain/model/memories_model.dart';
import 'package:moodtrack/models/journal_entry_model.dart';
import 'package:moodtrack/core/error/result.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  final AdminRepository _repo = sl<AdminRepository>();
  late TabController _tabController;
  Map<String, int> _stats = {};
  bool _loadingStats = true;

  // Palette
  static const _bg = Color(0xFF0D1117);
  static const _surface = Color(0xFF161B22);

  static const _accent = Color(0xFF58A6FF);
  static const _danger = Color(0xFFFF7B72);
  static const _success = Color(0xFF3FB950);
  static const _textPrimary = Color(0xFFE6EDF3);
  static const _textSecondary = Color(0xFF8B949E);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadStats();
  }

  Future<void> _loadStats() async {
    final result = await _repo.getStats();
    if (mounted) {
      setState(() {
        if (result is Success<Map<String, int>>) {
          _stats = result.data;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text((result as Failure).message),
              backgroundColor: _danger,
            ),
          );
        }
        _loadingStats = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _bg,
        colorScheme: const ColorScheme.dark(primary: _accent),
      ),
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _surface,
          elevation: 0,
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _textSecondary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: _danger.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.admin_panel_settings_rounded,
                  color: _danger,
                  size: 20.r,
                ),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Panel',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  Text(
                    AdminRepository.adminEmail,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10.sp,
                      color: _success,
                    ),
                  ),
                ],
              ),
            ],
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: _accent,
            indicatorWeight: 2,
            labelColor: _accent,
            unselectedLabelColor: _textSecondary,
            labelStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 13.sp,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.people_alt_rounded, size: 18),
                text: 'Users',
              ),
              Tab(
                icon: Icon(Icons.photo_library_rounded, size: 18),
                text: 'Memories',
              ),
              Tab(
                icon: Icon(Icons.menu_book_rounded, size: 18),
                text: 'Journals',
              ),
              Tab(
                icon: Icon(Icons.campaign_rounded, size: 18),
                text: 'Broadcast',
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            // ── Stats Bar ─────────────────────────────────────────
            _buildStatsBar(),
            // ── Tabs ──────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _UsersTab(repo: _repo),
                  _MemoriesTab(repo: _repo),
                  _JournalsTab(repo: _repo),
                  _BroadcastTab(repo: _repo),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      color: _surface,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: [
          _StatChip(
            label: 'Users',
            value: _stats['users'],
            loading: _loadingStats,
          ),
          SizedBox(width: 12.w),
          _StatChip(
            label: 'Memories',
            value: _stats['memories'],
            loading: _loadingStats,
          ),
          SizedBox(width: 12.w),
          _StatChip(
            label: 'Journals',
            value: _stats['journals'],
            loading: _loadingStats,
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: _textSecondary,
              size: 18.r,
            ),
            onPressed: () {
              setState(() => _loadingStats = true);
              _loadStats();
            },
          ),
        ],
      ),
    );
  }
}

// ── Stat Chip ──────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final int? value;
  final bool loading;
  const _StatChip({
    required this.label,
    required this.value,
    required this.loading,
  });

  static const _accent = Color(0xFF58A6FF);
  static const _textSecondary = Color(0xFF8B949E);
  static const _card = Color(0xFF21262D);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          loading
              ? SizedBox(
                  width: 12.r,
                  height: 12.r,
                  child: const CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: _accent,
                  ),
                )
              : Text(
                  '${value ?? 0}',
                  style: GoogleFonts.jetBrainsMono(
                    color: _accent,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
          SizedBox(width: 6.w),
          Text(
            label,
            style: GoogleFonts.outfit(color: _textSecondary, fontSize: 11.sp),
          ),
        ],
      ),
    );
  }
}

// ── USERS TAB ────────────────────────────────────────────────────────────────

class _UsersTab extends StatelessWidget {
  final AdminRepository repo;
  const _UsersTab({required this.repo});

  static const _card = Color(0xFF21262D);
  static const _border = Color(0xFF30363D);
  static const _textPrimary = Color(0xFFE6EDF3);
  static const _textSecondary = Color(0xFF8B949E);
  static const _accent = Color(0xFF58A6FF);
  static const _danger = Color(0xFFFF7B72);
  static const _success = Color(0xFF3FB950);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserProfile>>(
      stream: repo.getAllUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _accent));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'No users found.',
              style: GoogleFonts.outfit(color: _textSecondary),
            ),
          );
        }
        final users = snapshot.data!;
        return ListView.builder(
          padding: EdgeInsets.all(16.r),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final UserProfile user = users[index];
            final uid = user.uid;
            final email = user.email;
            final displayName = user.displayName;
            final partnerUid = user.partnerUid;
            final fcmToken = user.fcmToken;
            final platform = user.platform;
            final lastSeen = user.lastSeen;
            final relDate = user.relationshipStartDate;

            String? lastSeenStr;
            if (lastSeen != null) {
              lastSeenStr =
                  '${lastSeen.day}/${lastSeen.month}/${lastSeen.year} ${lastSeen.hour.toString().padLeft(2, '0')}:${lastSeen.minute.toString().padLeft(2, '0')}';
            }

            String? relDateStr;
            if (relDate != null) {
              relDateStr = '${relDate.day}/${relDate.month}/${relDate.year}';
            }

            return Container(
              margin: EdgeInsets.only(bottom: 12.h),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: _border),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(14.r),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20.r,
                          backgroundColor: _accent.withValues(alpha: 0.15),
                          child: Text(
                            (displayName ?? email).isNotEmpty
                                ? (displayName ?? email)[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.outfit(
                              color: _accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (displayName != null)
                                Text(
                                  displayName,
                                  style: GoogleFonts.outfit(
                                    color: _textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              Text(
                                email,
                                style: GoogleFonts.jetBrainsMono(
                                  color: _textSecondary,
                                  fontSize: 11.sp,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  if (platform != null) ...[
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6.w,
                                        vertical: 2.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _accent.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(
                                          6.r,
                                        ),
                                      ),
                                      child: Text(
                                        platform,
                                        style: GoogleFonts.jetBrainsMono(
                                          color: _accent,
                                          fontSize: 9.sp,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 6.w),
                                  ],
                                  if (partnerUid != null)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.favorite_rounded,
                                          color: _danger,
                                          size: 11.r,
                                        ),
                                        SizedBox(width: 3.w),
                                        Text(
                                          'Linked',
                                          style: GoogleFonts.outfit(
                                            color: _danger,
                                            fontSize: 10.sp,
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (lastSeenStr != null) ...[
                                    SizedBox(width: 8.w),
                                    Icon(
                                      Icons.access_time_rounded,
                                      color: _textSecondary,
                                      size: 10.r,
                                    ),
                                    SizedBox(width: 3.w),
                                    Text(
                                      lastSeenStr,
                                      style: GoogleFonts.jetBrainsMono(
                                        color: _textSecondary,
                                        fontSize: 9.sp,
                                      ),
                                    ),
                                  ],
                                  if (relDateStr != null) ...[
                                    SizedBox(width: 8.w),
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      color: _success,
                                      size: 10.r,
                                    ),
                                    SizedBox(width: 3.w),
                                    Text(
                                      relDateStr,
                                      style: GoogleFonts.jetBrainsMono(
                                        color: _success,
                                        fontSize: 9.sp,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: _danger,
                            size: 20.r,
                          ),
                          onPressed: () => _confirmDelete(context, uid, email),
                        ),
                      ],
                    ),
                  ),
                  // FCM Token row
                  if (fcmToken != null)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 12.h),
                      child: Row(
                        children: [
                          Icon(
                            Icons.notifications_active_rounded,
                            color: _success,
                            size: 12.r,
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: SelectableText(
                              fcmToken,
                              style: GoogleFonts.jetBrainsMono(
                                color: _textSecondary,
                                fontSize: 9.sp,
                              ),
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 12.h),
                      child: Row(
                        children: [
                          Icon(
                            Icons.notifications_off_rounded,
                            color: _textSecondary,
                            size: 12.r,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'No FCM token',
                            style: GoogleFonts.outfit(
                              color: _textSecondary,
                              fontSize: 10.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, String uid, String email) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF21262D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: _danger, size: 22.r),
            SizedBox(width: 8.w),
            Text(
              'Delete User',
              style: GoogleFonts.outfit(
                color: _textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: GoogleFonts.outfit(color: _textSecondary, fontSize: 13.sp),
            children: [
              const TextSpan(text: 'This will permanently delete '),
              TextSpan(
                text: email,
                style: const TextStyle(
                  color: _textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const TextSpan(
                text:
                    ' and all their data (memories, journals, etc.).\n\nThis action cannot be undone.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: _textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await repo.deleteUserData(uid);
              if (context.mounted) {
                if (result is Success) {
                  HapticFeedback.heavyImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('User $email and all their data deleted.'),
                      backgroundColor: _danger,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text((result as Failure).message),
                      backgroundColor: _danger,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _danger,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ── MEMORIES TAB ─────────────────────────────────────────────────────────────

class _MemoriesTab extends StatefulWidget {
  final AdminRepository repo;
  const _MemoriesTab({required this.repo});

  @override
  State<_MemoriesTab> createState() => _MemoriesTabState();
}

class _MemoriesTabState extends State<_MemoriesTab> {
  List<UserProfile> _users = [];
  String? _selectedUid;
  String? _selectedEmail;
  List<MemoryModel> _memories = [];
  bool _loadingUsers = true;
  bool _loadingMemories = false;

  static const _card = Color(0xFF21262D);
  static const _border = Color(0xFF30363D);
  static const _textPrimary = Color(0xFFE6EDF3);
  static const _textSecondary = Color(0xFF8B949E);
  static const _accent = Color(0xFF58A6FF);
  static const _danger = Color(0xFFFF7B72);
  static const _surface = Color(0xFF161B22);

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    widget.repo.getAllUsersStream().first.then((users) {
      if (mounted) {
        setState(() {
          _users = users;
          _loadingUsers = false;
        });
      }
    });
  }

  Future<void> _loadMemories(String uid) async {
    setState(() {
      _loadingMemories = true;
      _memories = [];
    });
    final result = await widget.repo.getUserMemories(uid);
    if (mounted) {
      setState(() {
        if (result is Success<List<MemoryModel>>) {
          _memories = result.data;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text((result as Failure).message),
              backgroundColor: _danger,
            ),
          );
        }
        _loadingMemories = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingUsers) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }

    return Column(
      children: [
        // User selector
        Container(
          height: 48.h,
          color: _surface,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            itemCount: _users.length,
            itemBuilder: (context, index) {
              final user = _users[index];
              final uid = user.uid;
              final email = user.email.isNotEmpty ? user.email : uid;
              final isSelected = uid == _selectedUid;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedUid = uid;
                    _selectedEmail = email;
                  });
                  _loadMemories(uid);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: 8.w),
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? _accent.withValues(alpha: 0.15) : _card,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: isSelected ? _accent : _border),
                  ),
                  child: Text(
                    email,
                    style: GoogleFonts.outfit(
                      color: isSelected ? _accent : _textSecondary,
                      fontSize: 12.sp,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Memories list
        Expanded(
          child: _selectedUid == null
              ? Center(
                  child: Text(
                    'Select a user above to view their memories.',
                    style: GoogleFonts.outfit(
                      color: _textSecondary,
                      fontSize: 13.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : _loadingMemories
              ? const Center(child: CircularProgressIndicator(color: _accent))
              : _memories.isEmpty
              ? Center(
                  child: Text(
                    'No memories found for $_selectedEmail.',
                    style: GoogleFonts.outfit(color: _textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16.r),
                  itemCount: _memories.length,
                  itemBuilder: (context, index) {
                    final mem = _memories[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 10.h),
                      padding: EdgeInsets.all(14.r),
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: _border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            mem.isUnique
                                ? Icons.star_rounded
                                : Icons.favorite_rounded,
                            color: mem.isUnique
                                ? const Color(0xFFD29922)
                                : _danger,
                            size: 18.r,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mem.title,
                                  style: GoogleFonts.outfit(
                                    color: _textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14.sp,
                                  ),
                                ),
                                Text(
                                  mem.description,
                                  style: GoogleFonts.outfit(
                                    color: _textSecondary,
                                    fontSize: 11.sp,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (mem.memoryDate != null)
                                  Text(
                                    '${mem.memoryDate!.day}/${mem.memoryDate!.month}/${mem.memoryDate!.year}',
                                    style: GoogleFonts.jetBrainsMono(
                                      color: _textSecondary,
                                      fontSize: 10.sp,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: _danger,
                              size: 18.r,
                            ),
                            onPressed: mem.id != null
                                ? () => _confirmDeleteMemory(context, mem)
                                : null,
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _confirmDeleteMemory(BuildContext context, MemoryModel mem) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF21262D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Delete Memory',
          style: GoogleFonts.outfit(
            color: _textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Delete "${mem.title}"? This cannot be undone.',
          style: GoogleFonts.outfit(color: _textSecondary, fontSize: 13.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: _textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await widget.repo.deleteMemory(
                _selectedUid!,
                mem.id!,
              );
              if (result is Success) {
                _loadMemories(_selectedUid!);
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text((result as Failure).message),
                    backgroundColor: _danger,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _danger,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ── JOURNALS TAB ─────────────────────────────────────────────────────────────

class _JournalsTab extends StatefulWidget {
  final AdminRepository repo;
  const _JournalsTab({required this.repo});

  @override
  State<_JournalsTab> createState() => _JournalsTabState();
}

class _JournalsTabState extends State<_JournalsTab> {
  List<UserProfile> _users = [];
  String? _selectedUid;
  String? _selectedEmail;
  List<JournalEntry> _journals = [];
  bool _loadingUsers = true;
  bool _loadingJournals = false;

  static const _card = Color(0xFF21262D);
  static const _border = Color(0xFF30363D);
  static const _textPrimary = Color(0xFFE6EDF3);
  static const _textSecondary = Color(0xFF8B949E);
  static const _accent = Color(0xFF58A6FF);
  static const _danger = Color(0xFFFF7B72);
  static const _surface = Color(0xFF161B22);

  @override
  void initState() {
    super.initState();
    widget.repo.getAllUsersStream().first.then((users) {
      if (mounted) {
        setState(() {
          _users = users;
          _loadingUsers = false;
        });
      }
    });
  }

  Future<void> _loadJournals(String uid) async {
    setState(() {
      _loadingJournals = true;
      _journals = [];
    });
    final result = await widget.repo.getUserJournals(uid);
    if (mounted) {
      setState(() {
        if (result is Success<List<JournalEntry>>) {
          _journals = result.data;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text((result as Failure).message),
              backgroundColor: _danger,
            ),
          );
        }
        _loadingJournals = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingUsers) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }

    return Column(
      children: [
        // User selector
        Container(
          height: 48.h,
          color: _surface,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            itemCount: _users.length,
            itemBuilder: (context, index) {
              final user = _users[index];
              final uid = user.uid;
              final email = user.email.isNotEmpty ? user.email : uid;
              final isSelected = uid == _selectedUid;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedUid = uid;
                    _selectedEmail = email;
                  });
                  _loadJournals(uid);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: 8.w),
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? _accent.withValues(alpha: 0.15) : _card,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: isSelected ? _accent : _border),
                  ),
                  child: Text(
                    email,
                    style: GoogleFonts.outfit(
                      color: isSelected ? _accent : _textSecondary,
                      fontSize: 12.sp,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Journals list
        Expanded(
          child: _selectedUid == null
              ? Center(
                  child: Text(
                    'Select a user above to view their journals.',
                    style: GoogleFonts.outfit(
                      color: _textSecondary,
                      fontSize: 13.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : _loadingJournals
              ? const Center(child: CircularProgressIndicator(color: _accent))
              : _journals.isEmpty
              ? Center(
                  child: Text(
                    'No journals found for $_selectedEmail.',
                    style: GoogleFonts.outfit(color: _textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16.r),
                  itemCount: _journals.length,
                  itemBuilder: (context, index) {
                    final entry = _journals[index];
                    final ts = entry.timestamp;
                    final dateStr = ts != null
                        ? '${ts.day}/${ts.month}/${ts.year}  ${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}'
                        : null;
                    return Container(
                      margin: EdgeInsets.only(bottom: 10.h),
                      padding: EdgeInsets.all(14.r),
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: _border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36.r,
                            height: 36.r,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFF30363D),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Text(
                              entry.mood,
                              style: TextStyle(fontSize: 18.sp),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (entry.title != null &&
                                    entry.title!.isNotEmpty)
                                  Text(
                                    entry.title!,
                                    style: GoogleFonts.outfit(
                                      color: _textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                Text(
                                  entry.encrypted
                                      ? '🔒 Encrypted entry'
                                      : entry.text,
                                  style: GoogleFonts.outfit(
                                    color: _textSecondary,
                                    fontSize: 11.sp,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (dateStr != null) ...[
                                  SizedBox(height: 4.h),
                                  Text(
                                    dateStr,
                                    style: GoogleFonts.jetBrainsMono(
                                      color: _textSecondary,
                                      fontSize: 9.sp,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: _danger,
                              size: 18.r,
                            ),
                            onPressed: () => _confirmDelete(context, entry),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, JournalEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF21262D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Delete Journal Entry',
          style: GoogleFonts.outfit(
            color: _textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Delete this entry? This cannot be undone.',
          style: GoogleFonts.outfit(color: _textSecondary, fontSize: 13.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: _textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await widget.repo.deleteJournal(
                _selectedUid!,
                entry.id,
              );
              if (result is Success) {
                _loadJournals(_selectedUid!);
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text((result as Failure).message),
                    backgroundColor: _danger,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _danger,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ── BROADCAST TAB ─────────────────────────────────────────────────────────────

class _BroadcastTab extends StatefulWidget {
  final AdminRepository repo;
  const _BroadcastTab({required this.repo});

  @override
  State<_BroadcastTab> createState() => _BroadcastTabState();
}

class _BroadcastTabState extends State<_BroadcastTab> {
  final _messageController = TextEditingController();
  String _selectedType = 'info';
  bool _sending = false;

  static const _card = Color(0xFF21262D);
  static const _border = Color(0xFF30363D);
  static const _textPrimary = Color(0xFFE6EDF3);
  static const _textSecondary = Color(0xFF8B949E);
  static const _accent = Color(0xFF58A6FF);
  static const _danger = Color(0xFFFF7B72);
  static const _success = Color(0xFF3FB950);

  final Map<String, Map<String, dynamic>> _types = {
    'info': {
      'label': 'Info',
      'color': Color(0xFF58A6FF),
      'icon': Icons.info_rounded,
    },
    'warning': {
      'label': 'Warning',
      'color': Color(0xFFD29922),
      'icon': Icons.warning_rounded,
    },
    'success': {
      'label': 'Success',
      'color': Color(0xFF3FB950),
      'icon': Icons.check_circle_rounded,
    },
    'danger': {
      'label': 'Danger',
      'color': Color(0xFFFF7B72),
      'icon': Icons.error_rounded,
    },
  };

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Current Broadcast ──────────────────────────────────
          Text(
            'Current Active Broadcast',
            style: GoogleFonts.outfit(
              color: _textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 12.h),
          StreamBuilder(
            stream: widget.repo.getBroadcastStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: _border),
                  ),
                  child: Text(
                    'No active broadcast.',
                    style: GoogleFonts.outfit(
                      color: _textSecondary,
                      fontSize: 13.sp,
                    ),
                  ),
                );
              }
              final data = snapshot.data!.data() as Map<String, dynamic>;
              final msg = data['message'] as String? ?? '';
              final type = data['type'] as String? ?? 'info';
              final typeData = _types[type] ?? _types['info']!;
              final color = typeData['color'] as Color;
              final icon = typeData['icon'] as IconData;
              return Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 20.r),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        msg,
                        style: GoogleFonts.outfit(
                          color: _textPrimary,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: _danger,
                        size: 18.r,
                      ),
                      onPressed: () async {
                        final result = await widget.repo.clearBroadcast();
                        if (result is Failure && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text((result).message),
                              backgroundColor: _danger,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: 28.h),

          // ── Send New Broadcast ─────────────────────────────────
          Text(
            'Send New Broadcast',
            style: GoogleFonts.outfit(
              color: _textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 12.h),

          // Type selector
          Row(
            children: _types.entries.map((entry) {
              final isSelected = _selectedType == entry.key;
              final color = entry.value['color'] as Color;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedType = entry.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(
                      right: entry.key == _types.keys.last ? 0 : 8.w,
                    ),
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withValues(alpha: 0.15) : _card,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: isSelected ? color : _border),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          entry.value['icon'] as IconData,
                          color: color,
                          size: 18.r,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          entry.value['label'] as String,
                          style: GoogleFonts.outfit(
                            color: isSelected ? color : _textSecondary,
                            fontSize: 10.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 16.h),

          // Message field
          TextField(
            controller: _messageController,
            maxLines: 4,
            style: GoogleFonts.outfit(color: _textPrimary, fontSize: 14.sp),
            decoration: InputDecoration(
              hintText: 'Type your broadcast message...',
              hintStyle: GoogleFonts.outfit(
                color: _textSecondary,
                fontSize: 13.sp,
              ),
              filled: true,
              fillColor: _card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: _border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: _accent),
              ),
            ),
          ),
          SizedBox(height: 16.h),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _sending ? null : _sendBroadcast,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              icon: _sending
                  ? SizedBox(
                      width: 16.r,
                      height: 16.r,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(Icons.send_rounded, size: 18.r),
              label: Text(
                _sending ? 'Sending...' : 'Send Broadcast',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  fontSize: 15.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendBroadcast() async {
    final msg = _messageController.text.trim();
    if (msg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a message.', style: GoogleFonts.outfit()),
          backgroundColor: _danger,
        ),
      );
      return;
    }
    setState(() => _sending = true);
    final result = await widget.repo.sendBroadcast(msg, type: _selectedType);
    if (mounted) {
      setState(() => _sending = false);
      if (result is Success) {
        setState(() => _messageController.clear());
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Broadcast sent!', style: GoogleFonts.outfit()),
            backgroundColor: _success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              (result as Failure).message,
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: _danger,
          ),
        );
      }
    }
  }
}
