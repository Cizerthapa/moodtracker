import 'package:flutter/material.dart';
import 'memories_screen.dart';
import 'water_intake_screen.dart';
import 'notes_screen.dart';
import 'settings_screen.dart';
import 'package:moodtrack/theme/app_colors.dart';

class EntryScreen extends StatelessWidget {
  const EntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MoodTrack',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: AppColors.warmBrown,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Treasuring your feelings, one step at a time.',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontStyle: FontStyle.italic,
                            fontSize: 15,
                            color: AppColors.softBrown,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.ivoryCard,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.champagne),
                      ),
                      child: const Icon(
                        Icons.settings_rounded,
                        color: AppColors.warmBrown,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // ── Feature Cards ───────────────────────────────────────
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildFeatureCard(
                      context,
                      title: 'Our Story',
                      subtitle: 'Pinned memories of every adventure.',
                      icon: Icons.favorite_rounded,
                      color: AppColors.roseDeep,
                      destination: const MemoriesScreen(),
                    ),
                    const SizedBox(height: 20),
                    _buildFeatureCard(
                      context,
                      title: 'Hydration',
                      subtitle: 'Staying fresh & keeping healthy.',
                      icon: Icons.water_drop_rounded,
                      color: const Color(0xFF6DAA7A), // earth green
                      destination: const WaterIntakeScreen(),
                    ),
                    const SizedBox(height: 20),
                    _buildFeatureCard(
                      context,
                      title: 'Daily Journal',
                      subtitle: 'Reflection for a peaceful mind.',
                      icon: Icons.auto_awesome_rounded,
                      color: const Color(0xFFD4A832), // warm gold
                      destination: const NotesScreen(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget destination,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, anim, __) => destination,
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.ivoryCard,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.warmBrown.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: AppColors.champagne, width: 1),
        ),
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.warmBrown,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                      color: AppColors.softBrown.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.roseDeep.withOpacity(0.4),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
