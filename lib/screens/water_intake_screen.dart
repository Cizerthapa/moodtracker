import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class WaterIntakeScreen extends StatefulWidget {
  const WaterIntakeScreen({super.key});

  @override
  State<WaterIntakeScreen> createState() => _WaterIntakeScreenState();
}

class _WaterIntakeScreenState extends State<WaterIntakeScreen> {
  int _currentIntake = 0;
  final int _dailyGoal = 2500; // ml
  final String _todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadIntake();
  }

  Future<void> _loadIntake() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentIntake = prefs.getInt('water_$_todayKey') ?? 0;
    });
  }

  Future<void> _addWater(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentIntake += amount;
      if (_currentIntake < 0) _currentIntake = 0;
    });
    await prefs.setInt('water_$_todayKey', _currentIntake);
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentIntake / _dailyGoal).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: const Text('Hydration')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Today\'s Intake',
                style: TextStyle(fontSize: 20, color: Colors.white70),
              ),
              const SizedBox(height: 40),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 250,
                    height: 250,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 20,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF12B76A),
                      ),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.water_drop_rounded,
                        size: 48,
                        color: const Color(0xFF12B76A).withOpacity(0.8),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_currentIntake',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '/ $_dailyGoal ml',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 60),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildWaterButton(
                    context,
                    -250,
                    'Remove 250ml',
                    Icons.remove,
                  ),
                  _buildWaterButton(context, 250, 'Add 250ml', Icons.add),
                ],
              ),
              const SizedBox(height: 20),
              _buildWaterButton(context, 500, 'Add 500ml', Icons.local_drink),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaterButton(
    BuildContext context,
    int amount,
    String label,
    IconData icon,
  ) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(
          0xFF12B76A,
        ).withOpacity(amount > 0 ? 1 : 0.2),
        foregroundColor: amount > 0 ? Colors.white : const Color(0xFF12B76A),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: amount > 0 ? 8 : 0,
        shadowColor: const Color(0xFF12B76A).withOpacity(0.5),
      ),
      onPressed: () => _addWater(amount),
      icon: Icon(icon),
      label: Text(
        amount > 0 ? '+$amount ml' : '$amount ml',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
