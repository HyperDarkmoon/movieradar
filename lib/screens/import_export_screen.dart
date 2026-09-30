import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:movieradar/models/import_result.dart';
import 'package:movieradar/services/movie_service.dart';
import 'package:movieradar/theme/cinematic_theme.dart';
import 'package:movieradar/widgets/cinematic_widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ImportExportScreen extends StatefulWidget {
  const ImportExportScreen({super.key});

  @override
  State<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen> {
  final MovieService _movieService = MovieService();
  bool _isExporting = false;
  bool _isImporting = false;
  String _statusMessage = '';
  bool _isSuccess = true;

  @override
  Widget build(BuildContext context) {
    return CinematicScaffold(
      appBar: AppBar(
        title: const Text(
          'IMPORT / EXPORT',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
            fontSize: 17,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Export section
              _ExportCard(
                title: 'EXPORT MOVIES',
                subtitle:
                    'Save your collection as a JSON backup anywhere on your device. No storage permissions needed.',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.save_alt_outlined,
                          label: 'Save to Files',
                          busy: _isExporting,
                          onPressed: _isExporting ? null : _exportToFile,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.share_outlined,
                          label: 'Share',
                          busy: _isExporting,
                          onPressed: _isExporting ? null : _exportAndShare,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Import section
              _ExportCard(
                title: 'IMPORT MOVIES',
                subtitle:
                    'Restore a backup. Pick any JSON export from your device or shared files.',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.delete_sweep_outlined,
                          label: 'Replace All',
                          busy: _isImporting,
                          destructive: true,
                          onPressed:
                              _isImporting ? null : () => _importFromFile(replace: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.merge_type,
                          label: 'Merge',
                          busy: _isImporting,
                          onPressed:
                              _isImporting ? null : () => _importFromFile(replace: false),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Status message
              if (_statusMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: (_isSuccess ? Colors.green : Colors.redAccent)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isSuccess ? Colors.green : Colors.redAccent,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isSuccess ? Icons.check_circle : Icons.error,
                        color: _isSuccess ? Colors.green : Colors.redAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _statusMessage,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Tips
              _ExportCard(
                title: 'TIPS',
                subtitle: '',
                children: [
                  const _Tip(
                    icon: Icons.folder_open,
                    text:
                        'Use "Save to Files" to store backups in the location of your choice.',
                  ),
                  const SizedBox(height: 10),
                  const _Tip(
                    icon: Icons.share,
                    text:
                        'Use "Share" to send a backup through WhatsApp, email, Drive, etc.',
                  ),
                  const SizedBox(height: 10),
                  const _Tip(
                    icon: Icons.restore,
                    text:
                        '"Replace All" overwrites your library. "Merge" adds only movies you don\'t already have.',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Export
  // ---------------------------------------------------------------------

  Future<void> _exportToFile() async {
    setState(() {
      _isExporting = true;
      _statusMessage = '';
    });

    try {
      final jsonData = _movieService.exportMovies();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final filename = 'movieradar_export_$timestamp.json';

      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save MovieRadar backup',
        fileName: filename,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: Uint8List.fromList(utf8.encode(jsonData)),
      );

      if (path == null) {
        setState(() {
          _isExporting = false;
          _statusMessage = 'Export cancelled';
          _isSuccess = true;
        });
        return;
      }

      setState(() {
        _isExporting = false;
        _statusMessage = 'Backup saved to $path';
        _isSuccess = true;
      });
    } catch (e) {
      setState(() {
        _isExporting = false;
        _statusMessage = 'Export failed: $e';
        _isSuccess = false;
      });
    }
  }

  Future<void> _exportAndShare() async {
    setState(() {
      _isExporting = true;
      _statusMessage = '';
    });

    try {
      final jsonData = _movieService.exportMovies();
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final filepath =
          '${tempDir.path}/movieradar_export_$timestamp.json';

      final file = File(filepath);
      await file.writeAsString(jsonData, flush: true);

      try {
        await Share.shareXFiles(
          [XFile(filepath)],
          subject: 'MovieRadar Movie Collection',
          text: 'MovieRadar backup',
        );
      } catch (shareError) {
        setState(() {
          _isExporting = false;
          _statusMessage = 'Backup created, but sharing failed: $shareError';
          _isSuccess = true;
        });
        return;
      }

      setState(() {
        _isExporting = false;
        _statusMessage = 'Backup ready to share!';
        _isSuccess = true;
      });
    } catch (e) {
      setState(() {
        _isExporting = false;
        _statusMessage = 'Export failed: $e';
        _isSuccess = false;
      });
    }
  }

  // ---------------------------------------------------------------------
  // Import
  // ---------------------------------------------------------------------

  Future<void> _importFromFile({required bool replace}) async {
    setState(() {
      _isImporting = true;
      _statusMessage = '';
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Select a MovieRadar backup',
      );

      if (result == null || result.files.single.path == null) {
        setState(() {
          _isImporting = false;
          _statusMessage = 'Import cancelled';
          _isSuccess = true;
        });
        return;
      }

      final file = File(result.files.single.path!);
      final jsonData = await file.readAsString();

      final ImportResult importResult;
      if (replace) {
        await _movieService.importFromJson(jsonData);
        importResult = ImportResult(
          success: true,
          message: 'Your library was replaced from the backup',
          moviesImported: 0,
        );
      } else {
        importResult = await _movieService.importMovies(jsonData);
      }

      setState(() {
        _isImporting = false;
        _statusMessage = importResult.message;
        _isSuccess = importResult.success;
      });
    } catch (e) {
      setState(() {
        _isImporting = false;
        _statusMessage = 'Import failed: $e';
        _isSuccess = false;
      });
    }
  }
}

// ---------------------------------------------------------------------
// UI helpers
// ---------------------------------------------------------------------

class _ExportCard extends StatelessWidget {
  const _ExportCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Cinematic.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: Cinematic.neonViolet,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                color: Cinematic.textSecondaryDark,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final bool destructive;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = CinematicColors.of(context);
    final enabled = widget.onPressed != null && !widget.busy;

    return GestureDetector(
      onTapDown: (_) {
        if (enabled) setState(() => _pressed = true);
      },
      onTapUp: (_) {
        if (enabled) setState(() => _pressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () {
        if (enabled) setState(() => _pressed = false);
      },
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
          decoration: BoxDecoration(
            gradient: widget.busy
                ? const LinearGradient(
                    colors: [Color(0xFF3B3057), Color(0xFF3B3057)],
                  )
                : widget.destructive
                    ? const LinearGradient(
                        colors: [Color(0xFF7A2E4D), Color(0xFF4A1E33)],
                      )
                    : Cinematic.glowGradient,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: enabled
                  ? Colors.white.withValues(alpha: 0.18)
                  : Colors.transparent,
            ),
            boxShadow: enabled
                ? [BoxShadow(color: colors.glowSoft, blurRadius: 16)]
                : null,
          ),
          child: widget.busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.icon,
                      size: 18,
                      color: enabled
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        widget.label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: enabled
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Cinematic.neonViolet),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Cinematic.textSecondaryDark,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}