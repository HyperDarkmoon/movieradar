import 'dart:io';
import 'dart:convert'; // Add the utf8 encoder
import 'dart:typed_data'; // Add Uint8List support
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart' as file_selector;
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:movieradar/services/movie_service.dart';
import 'package:movieradar/models/import_result.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import / Export'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Export section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Export Movies',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),                    const SizedBox(height: 8),
                    Text(
                      Platform.isAndroid 
                        ? 'Export your movie collection to a location of your choice or to the default Download/MovieRadar folder.'
                        : 'Export your movie collection to the Documents/MovieRadar folder.',
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isExporting ? null : _exportToFile,
                            icon: const Icon(Icons.folder_open),
                            label: const Text('Save to Location'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isExporting ? null : _exportAndShare,
                            icon: const Icon(Icons.share),
                            label: const Text('Share Export'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Import section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Import Movies',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),                    const SizedBox(height: 8),
                    Text(
                      'Import your movie collection from a backup file. Use "Browse Export Files" to access files in the ${Platform.isAndroid ? 'Download/MovieRadar' : 'Documents/MovieRadar'} folder.',
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isImporting ? null : () => _importFromFile(replace: true),
                                icon: const Icon(Icons.delete_sweep),
                                label: const Text('Replace All'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isImporting ? null : () => _importFromFile(replace: false),
                                icon: const Icon(Icons.merge_type),
                                label: const Text('Merge'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _isImporting ? null : () async {
                            final filePath = await _showExportFileSelectionDialog(context);
                            if (filePath != null) {
                              final File file = File(filePath);
                              final String jsonData = await file.readAsString();
                              
                              final ImportResult result = await _movieService.importMovies(jsonData);
                              
                              setState(() {
                                _isImporting = false;
                                _statusMessage = result.message;
                                _isSuccess = result.success;
                              });
                            }
                          },
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Browse Export Files'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Status message
            if (_statusMessage.isNotEmpty)              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isSuccess ? Colors.green : Colors.red,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _isSuccess ? Icons.check_circle : Icons.error,
                          color: _isSuccess ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _statusMessage,
                            style: TextStyle(
                              color: _isSuccess ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // If the message indicates successful export, show action buttons
                    if (_isSuccess && _statusMessage.contains('Saved to:'))
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, left: 32.0),
                        child: Row(
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.folder, size: 20),
                              label: const Text('View Folder'),
                              onPressed: () {
                                _showExportFileSelectionDialog(context);
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                minimumSize: const Size(0, 36),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
              // Tips
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.amber),
                        SizedBox(width: 8),
                        Text(
                          'Tips',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(Platform.isAndroid 
                      ? '• Export files can be saved to any location or to Download/MovieRadar folder'
                      : '• Export files are saved to Documents/MovieRadar folder'),
                    const Text('• Use "Replace All" to completely replace your current movies'),
                    const Text('• Use "Merge" to add movies without affecting existing ones'),
                    const Text('• Use "Browse Export Files" to quickly access saved exports'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }  // Export to file and save it
  // Check and request storage permissions on Android
  Future<bool> _checkAndRequestPermissions() async {
    if (!Platform.isAndroid) return true; // Only Android needs explicit permissions
    
    // For Android 13+ (SDK 33+), we need different permissions
    if (await Permission.manageExternalStorage.status.isGranted) {
      return true;
    }
    
    // Check storage permissions
    final storagePermission = await Permission.storage.status;
    if (storagePermission.isGranted) {
      return true;
    }
    
    // Request storage permission
    final status = await Permission.storage.request();
    if (status.isGranted) {
      return true;
    }
    
    // For Android 13+, try to request manage external storage permission
    final externalStorageStatus = await Permission.manageExternalStorage.request();
    return externalStorageStatus.isGranted;
  }

  Future<void> _exportToFile() async {
    setState(() {
      _isExporting = true;
      _statusMessage = '';
    });
    
    try {
      // Check permissions first
      final bool hasPermission = await _checkAndRequestPermissions();
      if (!hasPermission) {
        final bool goToSettings = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Text('Storage permission is required to export files. Would you like to open settings to grant this permission?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        ) ?? false;
        
        if (goToSettings) {
          await openAppSettings();
        }
        
        setState(() {
          _isExporting = false;
          _statusMessage = 'Export cancelled: Permission denied';
          _isSuccess = false;
        });
        return;
      }
      
      // Generate the export JSON
      final String jsonData = _movieService.exportMovies();
      
      // Create a timestamp for the filename
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String suggestedFilename = 'movieradar_export_$timestamp.json';
      
      String? selectedPath;
      bool userCancelled = false;
      bool useDirectSave = false;
      
      // Use FilePicker to save the file - better Android support
      try {
        // On Android, we need to use FilePicker instead of file_selector
        if (Platform.isAndroid) {
          // Use FilePicker to pick a directory where the user wants to save
          final String? outputDir = await FilePicker.platform.getDirectoryPath(
            dialogTitle: 'Select a folder to save the export',
          );
          
          if (outputDir != null) {
            // User selected a directory, create the full path
            selectedPath = '$outputDir/$suggestedFilename';
            useDirectSave = false; // Use standard File API for Android
          } else {
            // User canceled directory selection, offer default location
            final bool useDefault = await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Save to default location?'),
                content: const Text('Would you like to save to the Download/MovieRadar folder instead?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Save to default'),
                  ),
                ],
              ),
            ) ?? false;
            
            if (useDefault) {
              selectedPath = await _saveToDefaultLocation(suggestedFilename);
            } else {
              userCancelled = true;
            }
          }
        } else {
          // For iOS and desktop platforms, try to use file_selector's getSaveLocation
          // Since we know getSaveLocation is not implemented on Android, we don't use it there
          try {
            // Define the JSON file type
            final file_selector.XTypeGroup jsonTypeGroup = file_selector.XTypeGroup(
              label: 'JSON',
              extensions: ['json'],
              mimeTypes: ['application/json'],
            );
            
            // Get the save location - this opens the file picker
            final file_selector.FileSaveLocation? saveLocation = await file_selector.getSaveLocation(
              suggestedName: suggestedFilename,
              acceptedTypeGroups: [jsonTypeGroup],
            );
            
            if (saveLocation != null) {
              // User selected a location, save there
              selectedPath = saveLocation.path;
              useDirectSave = true;
            } else {
              // User canceled selection, offer default location
              final bool useDefault = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Save to default location?'),
                  content: const Text('Would you like to save to the Documents/MovieRadar folder instead?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Save to default'),
                    ),
                  ],
                ),
              ) ?? false;
              
              if (useDefault) {
                selectedPath = await _saveToDefaultLocation(suggestedFilename);
              } else {
                userCancelled = true;
              }
            }
          } catch (e) {
            // If file_selector fails, fall back to default location
            print('FileSelectorError: $e');
            selectedPath = await _saveToDefaultLocation(suggestedFilename);
          }
        }
      } catch (e) {
        // If direct file picker fails, ask the user if they want to use default location
        print('FilePickerError: $e');
        final bool useDefault = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Save to default location?'),
            content: Text('File picker failed. Would you like to save to the ${Platform.isAndroid ? 'Download/MovieRadar' : 'Documents/MovieRadar'} folder instead?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save to default'),
              ),
            ],
          ),
        ) ?? false;
        
        if (useDefault) {
          selectedPath = await _saveToDefaultLocation(suggestedFilename);
        } else {
          userCancelled = true;
        }
      }
      
      if (userCancelled) {
        setState(() {
          _isExporting = false;
          _statusMessage = 'Export canceled';
          _isSuccess = true;
        });
        return;
      }
      
      // Make sure we have a valid path
      if (selectedPath == null) {
        throw Exception('Failed to determine export location');
      }

      if (useDirectSave && !Platform.isAndroid) {
        // Use the XFile API for direct saving through the file picker
        // But only on non-Android platforms
        final file_selector.XFile jsonFile = file_selector.XFile.fromData(
          Uint8List.fromList(utf8.encode(jsonData)),
          mimeType: 'application/json',
          name: suggestedFilename,
        );
        
        await jsonFile.saveTo(selectedPath);
      } else {
        // Use standard File API - this works on all platforms, including Android
        final File file = File(selectedPath);
        await file.writeAsString(jsonData, flush: true);
      }
      
      setState(() {
        _isExporting = false;
        _statusMessage = 'Export successful! Saved to: $selectedPath';
        _isSuccess = true;
      });
    } catch (e) {
      setState(() {
        _isExporting = false;
        _statusMessage = 'Export failed: $e';
        _isSuccess = false;
      });
    }
  }  // Export and share via the system share dialog
  Future<void> _exportAndShare() async {
    setState(() {
      _isExporting = true;
      _statusMessage = '';
    });
    
    try {
      // Generate the export JSON
      final String jsonData = _movieService.exportMovies();
      
      // Get the temporary directory for sharing
      final Directory tempDir = await getTemporaryDirectory();
      
      // Create a unique filename
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filename = 'movieradar_export_$timestamp.json';
      final String filepath = '${tempDir.path}/$filename';

      // Write the file
      final File file = File(filepath);
      await file.writeAsString(jsonData, flush: true);
        try {
        // Share the file
        await Share.shareXFiles(
          [XFile(filepath)],  // This is share_plus.XFile which is imported by default
          text: 'MovieRadar Export',
          subject: 'MovieRadar Movie Collection',
        );
      } catch (shareError) {
        // Handle share errors specifically
        setState(() {
          _isExporting = false;
          _statusMessage = 'Export created but sharing failed: $shareError';
          _isSuccess = true; // Still consider it a success since the file was created
        });
        return;
      }
      
      setState(() {
        _isExporting = false;
        _statusMessage = 'Export ready to share!';
        _isSuccess = true;
      });
    } catch (e) {
      setState(() {
        _isExporting = false;
        _statusMessage = 'Export failed: $e';
        _isSuccess = false;
      });
    }
  }  // Import movies from a file
  Future<void> _importFromFile({required bool replace}) async {
    setState(() {
      _isImporting = true;
      _statusMessage = '';
    });

    try {
      // Check permissions first
      final bool hasPermission = await _checkAndRequestPermissions();
      if (!hasPermission) {
        final bool goToSettings = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Text('Storage permission is required to import files. Would you like to open settings to grant this permission?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        ) ?? false;
        
        if (goToSettings) {
          await openAppSettings();
        }
        
        setState(() {
          _isImporting = false;
          _statusMessage = 'Import cancelled: Permission denied';
          _isSuccess = false;
        });
        return;
      }
      
      // Try to determine where exports would be saved
      String? filePath;

      // First try to use the file picker if available
      try {
        // Use FilePicker for better Android compatibility
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['json'],
          dialogTitle: 'Select a MovieRadar export file',
        );
        
        if (result != null) {
          filePath = result.files.single.path;
        } else {
          setState(() {
            _isImporting = false;
            _statusMessage = 'Import cancelled';
            _isSuccess = true;
          });
          return;
        }
      } catch (e) {
        // File picker failed, we'll offer to show exports directory next
        // Do not set an error state yet
      }
        // If file picker failed, try to list available exports
      if (filePath == null) {
        // Show dialog with list of available exported files
        filePath = await _showExportFileSelectionDialog(context);
      }
      
      // Check if a file was selected by either method
      if (filePath == null) {
        setState(() {
          _isImporting = false;
          _statusMessage = 'Import cancelled';
          _isSuccess = true;
        });
        return;
      }
      
      // Read the file
      final File file = File(filePath);
      final String jsonData = await file.readAsString();      // Import the data
      ImportResult result = await _movieService.importMovies(jsonData);
      
      setState(() {
        _isImporting = false;
        _statusMessage = result.message;
        _isSuccess = result.success;
      });
    } catch (e) {
      setState(() {
        _isImporting = false;
        _statusMessage = 'Import failed: $e';
        _isSuccess = false;
      });
    }
  }  // Helper method to save to default location (Download/MovieRadar folder)
  Future<String> _saveToDefaultLocation(String filename) async {
    // Create a dedicated directory for app exports in Downloads (Android) or Documents (iOS)
    Directory? storageDir;
    String dirName = 'MovieRadar';
    
    if (Platform.isAndroid) {
      // For Android, try to use the Downloads directory
      storageDir = Directory('/storage/emulated/0/Download');
      if (!await storageDir.exists()) {
        // Fall back to application documents directory
        storageDir = await getApplicationDocumentsDirectory();
      }
    } else {
      // For iOS and other platforms, use the documents directory
      storageDir = await getApplicationDocumentsDirectory();
    }
    
    // Create app subfolder if it doesn't exist
    final Directory appDir = Directory('${storageDir.path}/$dirName');
    if (!await appDir.exists()) {
      await appDir.create();
    }
    
    return '${appDir.path}/$filename';
  }  // Show a dialog with available export files in the MovieRadar directory
  Future<String?> _showExportFileSelectionDialog(BuildContext context) async {
    // Check permissions first
    final bool hasPermission = await _checkAndRequestPermissions();
    if (!hasPermission) {
      final bool goToSettings = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permission Required'),
          content: const Text('Storage permission is required to browse files. Would you like to open settings to grant this permission?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      ) ?? false;
      
      if (goToSettings) {
        await openAppSettings();
      }
      return null;
    }
    
    // Find the MovieRadar directory based on platform
    Directory? storageDir;
    String dirName = 'MovieRadar';
    
    if (Platform.isAndroid) {
      // Try Downloads directory first
      storageDir = Directory('/storage/emulated/0/Download');
      if (!await storageDir.exists()) {
        // Fall back to documents directory
        storageDir = await getApplicationDocumentsDirectory();
      }
    } else {
      // For iOS and other platforms
      storageDir = await getApplicationDocumentsDirectory();
    }
    
    // Get the app directory
    final Directory appDir = Directory('${storageDir.path}/$dirName');
    if (!await appDir.exists()) {
      // Create it if it doesn't exist
      await appDir.create();
    }
    
    // List all files with .json extension
    final List<FileSystemEntity> files = appDir.listSync();
    final List<File> jsonFiles = files
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.json'))
        .toList();
    
    // Sort by last modified date
    jsonFiles.sort((a, b) {
      return b.lastModifiedSync().compareTo(a.lastModifiedSync());
    });
    
    if (jsonFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No export files found in MovieRadar directory')),
      );
      return null;
    }
    
    // Show dialog to select a file
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select an export file'),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Directory: ${appDir.path}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
                SizedBox(
                  width: double.maxFinite,
                  height: 300,
                  child: ListView.builder(
                    itemCount: jsonFiles.length,
                    itemBuilder: (context, index) {
                      final File file = jsonFiles[index];
                      final String fileName = file.path.split('/').last;
                      final DateTime modifiedDate = file.lastModifiedSync();
                      
                      return ListTile(
                        title: Text(fileName),
                        subtitle: Text(
                          'Modified: ${modifiedDate.year}-${modifiedDate.month.toString().padLeft(2, '0')}'
                          '-${modifiedDate.day.toString().padLeft(2, '0')} '
                          '${modifiedDate.hour.toString().padLeft(2, '0')}:'
                          '${modifiedDate.minute.toString().padLeft(2, '0')}',
                        ),
                        onTap: () {
                          Navigator.of(context).pop(file.path);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }


}
