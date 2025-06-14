import 'package:flutter/material.dart';
import 'package:movieradar/models/movie.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MovieDetailScreen extends StatefulWidget {
  final Movie movie;

  const MovieDetailScreen({super.key, required this.movie});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  late Movie _movie;
  late bool _isWatched;
  
  @override
  void initState() {
    super.initState();
    _movie = widget.movie;
    _isWatched = _movie.isWatched;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movie Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Hero(
                tag: 'movie_${_movie.id}',
                child: _movie.posterUrl != null && _movie.posterUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: _movie.posterUrl!,
                        height: 300,
                        placeholder: (context, url) => const SizedBox(
                          height: 300,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => CircleAvatar(
                          radius: 60,
                          child: Text(
                            _movie.title.substring(0, 1),
                            style: const TextStyle(fontSize: 40),
                          ),
                        ),
                      ),
                    )
                  : CircleAvatar(
                      radius: 60,
                      child: Text(
                        _movie.title.substring(0, 1),
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _movie.title,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Director', _movie.director ?? 'Unknown'),
            _buildInfoRow('Release Year', _movie.releaseYear?.toString() ?? 'Unknown'),
            _buildInfoRow('Added on', _formatDate(_movie.dateAdded)),
            if (_movie.isWatched && _movie.dateWatched != null)
              _buildInfoRow('Watched on', _formatDate(_movie.dateWatched!)),
              
            if (_movie.overview != null && _movie.overview!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Overview',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _movie.overview!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
              
            const SizedBox(height: 32),
            SwitchListTile(
              title: const Text('Watched'),
              value: _isWatched,
              onChanged: (bool value) {
                setState(() {
                  _isWatched = value;
                  _movie = _movie.copyWith(
                    isWatched: value,
                    dateWatched: value ? DateTime.now() : null,
                  );
                });
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, _movie);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Movie'),
        content: Text('Are you sure you want to delete "${_movie.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      if (mounted) {
        Navigator.pop(context, 'delete');
      }
    }
  }
}
