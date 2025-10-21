import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nfc_attendance_gamify/data/models/gamification.dart';
import 'package:nfc_attendance_gamify/features/gamification/providers/gamification_provider.dart';
import 'package:nfc_attendance_gamify/features/auth/providers/auth_provider.dart';

class LeaderboardWidget extends ConsumerWidget {
  const LeaderboardWidget({super.key, this.maxItems = 5});

  final int maxItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboard = ref.watch(leaderboardProvider);
    final currentUser = ref.watch(currentUserProvider);
    final gamificationNotifier = ref.read(gamificationProvider.notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.leaderboard,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Leaderboard',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.filter_list),
                  onSelected: (filter) {
                    switch (filter) {
                      case 'all':
                        gamificationNotifier.loadLeaderboard();
                        break;
                      case 'batch':
                        if (currentUser != null) {
                          gamificationNotifier.loadFilteredLeaderboards(
                            currentUser.program,
                            currentUser.batch,
                          );
                        }
                        break;
                      case 'program':
                        if (currentUser != null) {
                          gamificationNotifier.loadFilteredLeaderboards(
                            currentUser.program,
                            currentUser.batch,
                          );
                        }
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'all', child: Text('All Students')),
                    const PopupMenuItem(value: 'program', child: Text('My Program')),
                    const PopupMenuItem(value: 'batch', child: Text('My Batch')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (leaderboard.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.leaderboard_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No leaderboard data',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  // Top entries
                  ...leaderboard.take(maxItems).map((entry) => _LeaderboardTile(
                        entry: entry,
                        isCurrentUser: currentUser?.id == entry.userId,
                      )),

                  // Show more button
                  if (leaderboard.length > maxItems)
                    TextButton(
                      onPressed: () {
                        // TODO: Navigate to full leaderboard
                      },
                      child: const Text('View Full Leaderboard'),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isCurrentUser;

  const _LeaderboardTile({
    required this.entry,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
            : null,
        borderRadius: BorderRadius.circular(8),
        border: isCurrentUser
            ? Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Rank
            _buildRankBadge(entry.rank),
            const SizedBox(width: 12),

            // Avatar
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage: entry.profileImageUrl != null
                  ? NetworkImage(entry.profileImageUrl!)
                  : null,
              child: entry.profileImageUrl == null
                  ? Text(
                      entry.fullName.isNotEmpty
                          ? entry.fullName[0].toUpperCase()
                          : 'S',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.fullName,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrentUser)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'YOU',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.program} • Batch ${entry.batch}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Points and streak
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${entry.totalPoints} pts',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (entry.attendanceStreak > 0) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        size: 12,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${entry.attendanceStreak}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color color;
    IconData icon;

    switch (rank) {
      case 1:
        color = Colors.amber;
        icon = Icons.looks_one;
        break;
      case 2:
        color = Colors.grey.shade400;
        icon = Icons.looks_two;
        break;
      case 3:
        color = Colors.brown.shade400;
        icon = Icons.looks_3;
        break;
      default:
        color = Theme.of(context).colorScheme.primary;
        icon = Icons.tag;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Icon(
        icon,
        size: 16,
        color: color,
      ),
    );
  }
}