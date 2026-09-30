import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:movieradar/providers/theme_provider.dart';
import 'package:movieradar/screens/import_export_screen.dart';
import 'package:movieradar/theme/cinematic_theme.dart';
import 'package:movieradar/widgets/cinematic_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = CinematicColors.of(context);

    return CinematicScaffold(
      appBar: AppBar(
        title: const Text(
          'SETTINGS',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
            fontSize: 17,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsCard(
            title: 'APPEARANCE',
            child: Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return Column(
                  children: [
                    _ThemeTile(
                      title: 'System theme',
                      subtitle: 'Follow system settings',
                      value: ThemeMode.system,
                      groupValue: themeProvider.themeMode,
                      icon: Icons.brightness_auto,
                      onChanged: (v) => themeProvider.setThemeMode(v),
                    ),
                    const Divider(indent: 56),
                    _ThemeTile(
                      title: 'Light theme',
                      subtitle: 'Sunlit cinema',
                      value: ThemeMode.light,
                      groupValue: themeProvider.themeMode,
                      icon: Icons.light_mode,
                      onChanged: (v) => themeProvider.setThemeMode(v),
                    ),
                    const Divider(indent: 56),
                    _ThemeTile(
                      title: 'Dark theme',
                      subtitle: 'The late show',
                      value: ThemeMode.dark,
                      groupValue: themeProvider.themeMode,
                      icon: Icons.dark_mode,
                      onChanged: (v) => themeProvider.setThemeMode(v),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          _SettingsCard(
            title: 'DATA MANAGEMENT',
            child: ListTile(
              title: const Text('Import / Export Movies'),
              subtitle: Text(
                'Backup or transfer your collection',
                style: TextStyle(color: Cinematic.textSecondaryOf(context)),
              ),
              leading: _TileIcon(icon: Icons.import_export, colors: colors),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 15,
                color: Cinematic.neonViolet,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ImportExportScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          _SettingsCard(
            title: 'ABOUT',
            child: ListTile(
              title: const Text('About MovieRadar'),
              subtitle: Text(
                'Version 1.0.0',
                style: TextStyle(color: Cinematic.textSecondaryOf(context)),
              ),
              leading: _TileIcon(
                icon: Icons.local_movies,
                colors: colors,
              ),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'MovieRadar',
                  applicationVersion: '1.0.0',
                  applicationIcon: ShaderMask(
                    shaderCallback: (bounds) =>
                        Cinematic.glowGradient.createShader(bounds),
                    child: const Icon(
                      Icons.movie,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  applicationLegalese: 'Your cinema. Curated.',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cardColor = Cinematic.surfaceOf(context);
    final cardBorder = Cinematic.cardBorderOf(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.6,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          child,
        ],
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.icon,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final ThemeMode value;
  final ThemeMode groupValue;
  final IconData icon;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = CinematicColors.of(context);
    final selected = value == groupValue;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dotGradient = selected
        ? Cinematic.glowGradient
        : (isDark
            ? const LinearGradient(
                colors: [Color(0xFF2A2148), Color(0xFF241B40)],
              )
            : const LinearGradient(
                colors: [Color(0xFFE3D8F6), Color(0xFFD8C9F0)],
              ));
    final dotBorder = selected
        ? Colors.white.withValues(alpha: 0.4)
        : isDark
            ? Colors.white.withValues(alpha: 0.12)
            : colors.glow.withValues(alpha: 0.3);

    return ListTile(
      leading: _TileIcon(icon: icon, colors: colors, active: selected),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      subtitle: Text(subtitle,
          style: TextStyle(color: Cinematic.textSecondaryOf(context))),
      trailing: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: dotGradient,
          border: Border.all(color: dotBorder),
        ),
        child: selected
            ? const Icon(Icons.check, size: 14, color: Colors.white)
            : null,
      ),
      onTap: () => onChanged(value),
    );
  }
}

class _TileIcon extends StatelessWidget {
  const _TileIcon({
    required this.icon,
    required this.colors,
    this.active = false,
  });

  final IconData icon;
  final CinematicColors colors;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? colors.glow.withValues(alpha: 0.16)
            : colors.glass,
        border: Border.all(
          color: active
              ? colors.glow.withValues(alpha: 0.5)
              : Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.1)
                  : colors.glow.withValues(alpha: 0.22),
        ),
      ),
      child: Icon(
        icon,
        size: 19,
        color: active
            ? colors.glow
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}