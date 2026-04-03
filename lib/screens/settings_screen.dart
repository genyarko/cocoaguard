import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/history_provider.dart';
import '../providers/qa_provider.dart';
import '../utils/app_colors.dart';
import 'help_screen.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.onyx,
        foregroundColor: AppColors.chartreuse,
      ),
      body: ListView(
        children: [
          // Data Management Section
          _buildSection(
            'Data Management',
            [
              _buildSettingTile(
                icon: Icons.history,
                title: 'Clear Scan History',
                subtitle: 'Remove all saved scans',
                onTap: () => _showClearHistoryDialog(context),
              ),
              _buildSettingTile(
                icon: Icons.delete_outline,
                title: 'Clear Chat History',
                subtitle: 'Remove all Q&A conversations',
                onTap: () => _showClearChatDialog(context),
              ),
            ],
          ),
          const Divider(),
          // Support Section
          _buildSection(
            'Support',
            [
              _buildSettingTile(
                icon: Icons.help_outline,
                title: 'Help & Guide',
                subtitle: 'How to scan, tips, and FAQs',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpScreen()),
                ),
              ),
              _buildSettingTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                subtitle: 'How your data is handled',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyScreen()),
                ),
              ),
            ],
          ),
          const Divider(),
          // About Section
          _buildSection(
            'About',
            [
              _buildSettingTile(
                icon: Icons.info_outline,
                title: 'App Version',
                subtitle: 'CocoaGuard v1.0.0',
                onTap: null,
              ),
              _buildSettingTile(
                icon: Icons.code,
                title: 'Built with Gemma 4',
                subtitle: 'AI-powered disease detection',
                onTap: null,
              ),
              _buildSettingTile(
                icon: Icons.open_in_new,
                title: 'View GitHub Repository',
                subtitle: 'https://github.com/genyarko/cocoaguard',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('GitHub link copied')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.toffeeBrown,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return Semantics(
      button: onTap != null,
      label: '$title — $subtitle',
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        color: AppColors.lightGray,
        child: ListTile(
          leading: Icon(icon, color: AppColors.chartreuse),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
          onTap: onTap,
        ),
      ),
    );
  }

  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Scan History?'),
        content: const Text(
          'This will permanently delete all saved scans. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<HistoryProvider>().clearHistory();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Scan history cleared')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showClearChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Chat History?'),
        content: const Text(
          'This will permanently delete all Q&A conversations. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<QaProvider>().clearHistory();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat history cleared')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
