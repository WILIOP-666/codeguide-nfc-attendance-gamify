import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nfc_attendance_gamify/features/gamification/providers/gamification_provider.dart';

class PointsBalanceCard extends ConsumerWidget {
  const PointsBalanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamificationNotifier = ref.read(gamificationProvider.notifier);
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) return const SizedBox.shrink();

    final currentLevel = gamificationNotifier.calculateUserLevel(currentUser.totalPoints);
    final pointsToNextLevel = gamificationNotifier.calculatePointsToNextLevel(currentLevel, currentUser.totalPoints);
    final levelProgress = gamificationNotifier.getLevelProgress(currentLevel, currentUser.totalPoints);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Points Balance',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getLevelColor(currentLevel).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Level $currentLevel',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getLevelColor(currentLevel),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Points Display
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currentUser.totalPoints.toString(),
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'points',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Level Progress
            if (currentLevel < 6) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Level Progress',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '$pointsToNextLevel points to next level',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: levelProgress,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(_getLevelColor(currentLevel)),
                borderRadius: BorderRadius.circular(4),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Maximum Level Reached!',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 1: return Colors.grey; // Beginner
      case 2: return Colors.brown; // Bronze
      case 3: return Colors.grey.shade400; // Silver
      case 4: return Colors.yellow.shade700; // Gold
      case 5: return Colors.blue.shade600; // Platinum
      case 6: return Colors.purple; // Diamond
      default: return Colors.grey;
    }
  }
}