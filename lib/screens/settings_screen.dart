import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/history_provider.dart';
import '../providers/language_provider.dart';
import '../providers/qa_provider.dart';
import '../services/knowledge_service.dart';
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
    return Consumer<LanguageProvider>(
      builder: (context, langProvider, _) {
        final ks = langProvider.knowledgeService;
        return Scaffold(
          appBar: AppBar(
            title: Text(ks.sectionTitle('settings')),
            backgroundColor: AppColors.onyx,
            foregroundColor: AppColors.chartreuse,
          ),
          body: ListView(
            children: [
              // Language Section
              _buildSection(
                ks.sectionTitle('language'),
                [
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 0,
                    color: AppColors.lightGray,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.language,
                                  color: AppColors.chartreuse),
                              const SizedBox(width: 12),
                              Text(
                                ks.sectionTitle('offlineLibLang'),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: [
                              for (final lang in AppLanguage.values)
                                FilterChip(
                                  label: Text(lang.displayName),
                                  selected:
                                      langProvider.language == lang,
                                  onSelected: (selected) {
                                    if (selected) {
                                      langProvider.setLanguage(lang);
                                    }
                                  },
                                  selectedColor:
                                      AppColors.chartreuse,
                                  labelStyle: TextStyle(
                                    color: langProvider.language == lang
                                        ? AppColors.onyx
                                        : Colors.grey[700],
                                    fontWeight:
                                        langProvider.language == lang
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(),
              // Data Management Section
              _buildSection(
                ks.sectionTitle('dataManagement'),
                [
                  _buildSettingTile(
                    icon: Icons.history,
                    title: ks.sectionTitle('clearScanHistory'),
                    subtitle: ks.sectionTitle('clearScanHistorySub'),
                    onTap: () => _showClearHistoryDialog(context),
                  ),
                  _buildSettingTile(
                    icon: Icons.delete_outline,
                    title: ks.sectionTitle('clearChatHistory'),
                    subtitle: ks.sectionTitle('clearChatHistorySub'),
                    onTap: () => _showClearChatDialog(context),
                  ),
                ],
              ),
              const Divider(),
              // Support Section
              _buildSection(
                ks.sectionTitle('support'),
                [
                  _buildSettingTile(
                    icon: Icons.help_outline,
                    title: ks.sectionTitle('helpGuide'),
                    subtitle: ks.sectionTitle('helpGuideSub'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HelpScreen()),
                    ),
                  ),
                  _buildSettingTile(
                    icon: Icons.privacy_tip_outlined,
                    title: ks.sectionTitle('privacyPolicy'),
                    subtitle: ks.sectionTitle('privacyPolicySub'),
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
                ks.sectionTitle('about'),
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
      },
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
    final ks = context.read<LanguageProvider>().knowledgeService;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ks.sectionTitle('clearScanConfirm')),
        content: Text(ks.sectionTitle('clearScanConfirmBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ks.sectionTitle('cancel')),
          ),
          TextButton(
            onPressed: () {
              context.read<HistoryProvider>().clearHistory();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(ks.sectionTitle('scanHistoryCleared'))),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(ks.sectionTitle('clear')),
          ),
        ],
      ),
    );
  }

  void _showClearChatDialog(BuildContext context) {
    final ks = context.read<LanguageProvider>().knowledgeService;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ks.sectionTitle('clearChatConfirm')),
        content: Text(ks.sectionTitle('clearChatConfirmBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ks.sectionTitle('cancel')),
          ),
          TextButton(
            onPressed: () {
              context.read<QaProvider>().clearHistory();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(ks.sectionTitle('chatHistoryCleared'))),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(ks.sectionTitle('clear')),
          ),
        ],
      ),
    );
  }
}
