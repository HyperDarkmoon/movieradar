import 'package:flutter/material.dart';
import 'package:movieradar/models/movie.dart';
import 'package:movieradar/services/movie_service.dart';
import 'package:movieradar/screens/add_movie_screen.dart';
import 'package:movieradar/screens/movie_detail_screen.dart';
import 'package:movieradar/screens/settings_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  final MovieService _movieService = MovieService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Add some sample movies for testing
    _addSampleMovies();
  }

  void _addSampleMovies() {
    final sampleMovies = [
      
    ];

    for (var movie in sampleMovies) {
      _movieService.addMovie(movie);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MovieRadar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Watchlist', icon: Icon(Icons.playlist_add_check)),
            Tab(text: 'Watched', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMovieList(_movieService.getUnwatchedMovies()),
          _buildMovieList(_movieService.getWatchedMovies()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddMovie,
        tooltip: 'Add Movie',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMovieList(List<Movie> movies) {
    if (movies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.movie_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No movies found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Add movies using the + button',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: movies.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final movie = movies[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: 2,
          child: InkWell(
            onTap: () => _navigateToMovieDetails(movie),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Movie poster
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                  child: Hero(
                    tag: 'movie_${movie.id}',
                    child: movie.posterUrl != null && movie.posterUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: movie.posterUrl!,
                          width: 100,
                          height: 150,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 100,
                            height: 150,
                            color: Colors.grey[300],
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 100,
                            height: 150,
                            color: Colors.grey[300],
                            child: Center(
                              child: Text(
                                movie.title.substring(0, 1),
                                style: const TextStyle(fontSize: 40),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          width: 100,
                          height: 150,
                          color: Colors.grey[300],
                          child: Center(
                            child: Text(
                              movie.title.substring(0, 1),
                              style: const TextStyle(fontSize: 40),
                            ),
                          ),
                        ),
                  ),
                ),
                
                // Movie details
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movie.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          movie.releaseYear != null 
                            ? '${movie.releaseYear} • ${movie.director ?? 'Unknown director'}' 
                            : movie.director ?? '',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        if (movie.overview != null && movie.overview!.isNotEmpty)
                          Text(
                            movie.overview!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ),
                
                // Watch status button
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        movie.isWatched ? Icons.visibility : Icons.visibility_outlined,
                        color: movie.isWatched ? Colors.green : Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _movieService.toggleWatchedStatus(movie.id);
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToAddMovie() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddMovieScreen()),
    );

    if (result != null && result is Movie) {
      setState(() {
        _movieService.addMovie(result);
      });
    }
  }

  void _navigateToMovieDetails(Movie movie) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailScreen(movie: movie),
      ),
    );

    if (result != null) {
      setState(() {
        // The movie might have been updated or deleted
        if (result is Movie) {
          _movieService.updateMovie(result);
        } else if (result is String && result == 'delete') {
          _movieService.removeMovie(movie.id);
        }
      });
    }
  }
}