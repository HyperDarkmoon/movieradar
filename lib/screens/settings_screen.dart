import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:movieradar/providers/theme_provider.dart';
import 'package:movieradar/screens/import_export_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Appearance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 1),
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) {
                    return Column(
                      children: [
                        RadioListTile<ThemeMode>(
                          title: const Text('System theme'),
                          subtitle: const Text('Follow system settings'),
                          value: ThemeMode.system,
                          groupValue: themeProvider.themeMode,
                          onChanged: (ThemeMode? value) {
                            if (value != null) {
                              themeProvider.setThemeMode(value);
                            }
                          },
                        ),
                        RadioListTile<ThemeMode>(
                          title: const Text('Light theme'),
                          value: ThemeMode.light,
                          groupValue: themeProvider.themeMode,
                          onChanged: (ThemeMode? value) {
                            if (value != null) {
                              themeProvider.setThemeMode(value);
                            }
                          },
                        ),
                        RadioListTile<ThemeMode>(
                          title: const Text('Dark theme'),
                          value: ThemeMode.dark,
                          groupValue: themeProvider.themeMode,
                          onChanged: (ThemeMode? value) {
                            if (value != null) {
                              themeProvider.setThemeMode(value);
                            }
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Data Management',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Import / Export Movies'),
                  subtitle: const Text('Backup or transfer your movie collection'),
                  leading: const Icon(Icons.import_export),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ImportExportScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('About MovieRadar'),
                  subtitle: const Text('Version 1.0.0'),
                  leading: const Icon(Icons.info_outline),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'MovieRadar',
                      applicationVersion: '1.0.0',
                      applicationIcon: const FlutterLogo(),
                      applicationLegalese: 'A simple movie watchlist app',
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
