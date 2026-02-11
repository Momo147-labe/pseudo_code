import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/challenge_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme.dart';

class UserProfileModal extends StatelessWidget {
  const UserProfileModal({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final challengeProvider = context.watch<ChallengeProvider>();
    final profile = challengeProvider.myProfile;

    if (profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Dialog(
      backgroundColor: ThemeColors.sidebarBg(theme),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 120,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blueAccent, Colors.indigo],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -40,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: profile.avatarUrl != null
                          ? NetworkImage(profile.avatarUrl!)
                          : null,
                      backgroundColor: Colors.grey[300],
                      child: profile.avatarUrl == null
                          ? Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.grey[600],
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 50),
            Text(
              "${profile.firstName} ${profile.lastName}",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: ThemeColors.textBright(theme),
              ),
            ),
            Text(
              "@${profile.username}",
              style: const TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStat("XP", profile.xp.toString()),
                const SizedBox(width: 24),
                _buildStat("NIVEAU", profile.level.toString()),
              ],
            ),
            const Divider(height: 32, indent: 32, endIndent: 32),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildProfileItem(
                    Icons.school,
                    "Université",
                    profile.university,
                    theme,
                  ),
                  _buildProfileItem(
                    Icons.category,
                    "Département",
                    profile.department ?? "N/A",
                    theme,
                  ),
                  _buildProfileItem(
                    Icons.workspace_premium,
                    "Licence",
                    profile.license ?? "N/A",
                    theme,
                  ),
                  if (profile.phone != null)
                    _buildProfileItem(
                      Icons.phone,
                      "Téléphone",
                      profile.phone!,
                      theme,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("FERMER"),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => challengeProvider.signOut(),
                  icon: const Icon(Icons.logout),
                  label: const Text("DÉCONNEXION"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.amber,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileItem(
    IconData icon,
    String label,
    String value,
    AppTheme theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white54),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
