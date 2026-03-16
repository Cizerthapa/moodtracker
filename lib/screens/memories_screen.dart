import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'memory_detail_screen.dart';
import 'package:moodtrack/theme/app_colors.dart';

class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _initData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    await _seedMemoriesIfEmpty();
    if (mounted) {
      setState(() => _isLoading = false);
      _fadeController.forward();
    }
  }

  Future<void> _seedMemoriesIfEmpty() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('memories')
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) return;

    final seeds = [
      "20th Dec : Windy hill",
      "27th Dec : Cafe Window pane - came to give flowers diuso",
      "31st Dec : Baker's treat",
      "3rd January : The dragon's farm - td",
      "10th January : Lele - td",
      "11th January : Butwal ko fulki - td",
      "15th January : kyampa",
      "18th January : chocolate dina ako thyo",
      "19th January : HaoPin Hotpot - chicken station",
      "20th January : organic - Baker's treat",
      "22rd January : dalle - barbecue chulo",
      "23rd January : buddhanilkantha",
      "30th January : Mike's",
      "31st January : Workshop eatery",
      "7th February : House of sushi",
      "8th February : Cafe Jireh - td",
      "14th February : Marathon - his home",
      "20th February : shrey courtyard - norvic - Car accident",
      "21th February : Mahadevsthan - Baker's treat",
      "25th February : KGF restro",
      "2nd March : holi plus Baker's treat",
      "13th March : Butwal ko fulki plus chaya center (crime 101)",
      "15th March : Baker's treat 2nd month ann",
    ];

    final batch = FirebaseFirestore.instance.batch();
    const double baseLat = 27.7172;
    const double baseLng = 85.3240;

    for (int i = 0; i < seeds.length; i++) {
      final docRef = FirebaseFirestore.instance.collection('memories').doc();
      final text = seeds[i];
      final parts = text.split(" : ");
      final dateStr = parts[0].trim();
      final title = parts.length > 1 ? parts[1].trim() : text;
      final isUnique = (i == 17);

      batch.set(docRef, {
        'title': title,
        'description': dateStr,
        'date': DateTime.now()
            .subtract(Duration(days: seeds.length - i))
            .toIso8601String(),
        'lat': baseLat + (i * 0.005),
        'lng': baseLng + (i * 0.005),
        'isUnique': isUnique,
      });
    }
    await batch.commit();
  }

  Future<void> _addMemoryAtCurrentLocation() async {
    final docRef = await FirebaseFirestore.instance.collection('memories').add({
      'title': 'New Memory',
      'description': 'Description here',
      'date': DateTime.now().toIso8601String(),
      'lat': 27.7172,
      'lng': 85.3240,
      'isUnique': false,
    });

    if (mounted) {
      final snapshot = await docRef.get();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MemoryDetailScreen(doc: snapshot),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 24, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Our Story',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: AppColors.warmBrown,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.favorite_rounded,
                              size: 12,
                              color: AppColors.roseDust,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'every moment, treasured',
                              style: TextStyle(
                                fontFamily: 'Georgia',
                                fontStyle: FontStyle.italic,
                                fontSize: 13,
                                color: AppColors.softBrown,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Add button
                  GestureDetector(
                    onTap: _addMemoryAtCurrentLocation,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.roseDeep,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.roseDeep.withOpacity(0.3),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Thin divider with hearts ─────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: AppColors.roseDust.withOpacity(0.4),
                      thickness: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.favorite,
                      size: 10,
                      color: AppColors.roseDust.withOpacity(0.7),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: AppColors.roseDust.withOpacity(0.4),
                      thickness: 1,
                    ),
                  ),
                ],
              ),
            ),

            // ── List ────────────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppColors.roseDust,
                        strokeWidth: 2,
                      ),
                    )
                  : FadeTransition(
                      opacity: _fadeAnim,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('memories')
                            .orderBy('date', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Center(
                              child: CircularProgressIndicator(
                                color: AppColors.roseDust,
                                strokeWidth: 2,
                              ),
                            );
                          }

                          final docs = snapshot.data!.docs;

                          if (docs.isEmpty) {
                            return _EmptyState(
                              onAdd: _addMemoryAtCurrentLocation,
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final doc = docs[index];
                              final data = doc.data() as Map<String, dynamic>;
                              return _MemoryCard(
                                data: data,
                                index: index,
                                onTap: () => Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (_, anim, __) =>
                                        MemoryDetailScreen(doc: doc),
                                    transitionsBuilder: (_, anim, __, child) =>
                                        FadeTransition(
                                          opacity: anim,
                                          child: child,
                                        ),
                                    transitionDuration: const Duration(
                                      milliseconds: 300,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Memory Card ────────────────────────────────────────────────────────────

class _MemoryCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final int index;
  final VoidCallback onTap;

  const _MemoryCard({
    required this.data,
    required this.index,
    required this.onTap,
  });

  @override
  State<_MemoryCard> createState() => _MemoryCardState();
}

class _MemoryCardState extends State<_MemoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _pressController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isUnique = widget.data['isUnique'] == true;
    final String title = widget.data['title'] ?? '';
    final String description = widget.data['description'] ?? '';

    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isUnique ? const Color(0xFFFFF0EC) : AppColors.ivoryCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isUnique ? AppColors.roseDeep.withOpacity(0.35) : AppColors.champagne,
              width: isUnique ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isUnique
                    ? AppColors.roseDeep.withOpacity(0.07)
                    : AppColors.warmBrown.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                // Icon dot
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isUnique ? AppColors.roseDeep.withOpacity(0.12) : AppColors.champagne,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isUnique ? Icons.star_rounded : Icons.favorite_rounded,
                    color: isUnique ? AppColors.roseDeep : AppColors.roseDust,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 14),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        description,
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontStyle: FontStyle.italic,
                          fontSize: 11,
                          color: isUnique ? AppColors.roseDeep : AppColors.softBrown,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.warmBrown,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  Icons.chevron_right_rounded,
                  color: isUnique ? AppColors.roseDeep : AppColors.roseDust,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 52,
              color: AppColors.roseDust.withOpacity(0.5),
            ),
            const SizedBox(height: 18),
            const Text(
              'No memories yet',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.warmBrown,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Every adventure starts with a first step.\nAdd your first memory together.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Georgia',
                fontStyle: FontStyle.italic,
                fontSize: 14,
                color: AppColors.softBrown,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.roseDeep,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.roseDeep.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  'Add a Memory',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
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
