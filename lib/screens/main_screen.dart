import 'package:flutter/material.dart';
import 'package:movieradar/models/movie.dart';
import 'package:movieradar/services/movie_service.dart';
import 'package:movieradar/screens/add_movie_screen.dart';
import 'package:movieradar/screens/movie_detail_screen.dart';
import 'package:movieradar/screens/settings_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  final MovieService _movieService = MovieService();
  late TabController _tabController;
  bool _isGridView = false; // Default to list view
    // Search functionality
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Setup search controller
    _searchController.addListener(_onSearchChanged);
    
    // Load view preference
    _loadViewPreference();
  }
    // Handle search query changes
  void _onSearchChanged() {
    if (_isSearching) {
      setState(() {
        _searchQuery = _searchController.text;
      });
    }
  }
  
  // Load the user's view preference
  Future<void> _loadViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isGridView = prefs.getBool('is_grid_view') ?? false;
    });
  }
  
  // Save the user's view preference
  Future<void> _saveViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_grid_view', _isGridView);
  }
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {    
    return Scaffold(
      appBar: AppBar(
        title: _isSearching 
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
              decoration: InputDecoration(
                hintText: 'Search movies...',
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)),
                border: InputBorder.none,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _toggleSearch();
                  },
                ),
              ),
            )
          : const Text('MovieRadar'),
        actions: [
          // Search button
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search',
              onPressed: _toggleSearch,
            ),
            
          // Toggle between list and grid view
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            tooltip: _isGridView ? 'List View' : 'Grid View',
            onPressed: () async {
              setState(() {
                _isGridView = !_isGridView;
              });
              // Save preference
              await _saveViewPreference();
            },
          ),
          
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],        bottom: PreferredSize(
          // Use a fixed height that accommodates both scenarios
          preferredSize: Size.fromHeight(_isSearching && _searchQuery.isNotEmpty ? 90 : kToolbarHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Display search info if searching
              if (_isSearching && _searchQuery.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        child: Text(
                          'Search results for: "$_searchQuery"',
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                        tooltip: 'Clear search',
                        iconSize: 20,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                // Tab bar
              SizedBox(
                height: kToolbarHeight,
                child: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Watchlist', icon: Icon(Icons.playlist_add_check)),
                    Tab(text: 'Watched', icon: Icon(Icons.history)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),      
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMovieList(_filterMovies(_movieService.getUnwatchedMovies())),
          _buildMovieList(_filterMovies(_movieService.getWatchedMovies())),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddMovie,
        tooltip: 'Add Movie',
        child: const Icon(Icons.add),
      ),
    );
  }  Widget _buildMovieList(List<Movie> movies) {
    if (movies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.movie_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),            Text(
              _isSearching && _searchQuery.isNotEmpty 
                ? 'No results found' 
                : 'No movies found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              _isSearching && _searchQuery.isNotEmpty 
                ? 'Try a different search term' 
                : 'Add movies using the + button',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
            ),
            if (_isSearching && _searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton(
                  onPressed: () {
                    _searchController.clear();
                    _toggleSearch();
                  },
                  child: const Text('Clear Search'),
                ),
              ),
          ],
        ),
      );
    }

    // Use AnimatedSwitcher for smooth transition between list and grid views
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: _isGridView 
          ? _buildGridView(movies)
          : _buildListView(movies),
    );
  }
    Widget _buildListView(List<Movie> movies) {
    return ListView.builder(
      key: const ValueKey('list-view'),
      itemCount: movies.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final movie = movies[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: 2,
          child: InkWell(
            onTap: () => _navigateToMovieDetails(movie),
            splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            highlightColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                      ),                  onPressed: () async {
                        await _movieService.toggleWatchedStatus(movie.id);
                        setState(() {
                          // Refresh UI
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
  Widget _buildGridView(List<Movie> movies) {
    return GridView.builder(
      key: const ValueKey('grid-view'),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: movies.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final movie = movies[index];
        return Card(
          elevation: 2,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _navigateToMovieDetails(movie),
            splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            highlightColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Poster area
                Expanded(
                  flex: 3,
                  child: Hero(
                    tag: 'movie_${movie.id}',
                    child: movie.posterUrl != null && movie.posterUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: movie.posterUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
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
                
                // Movie info area
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movie.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (movie.releaseYear != null)
                          Text(
                            movie.releaseYear.toString(),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ),
                  // Watch status indicator with toggle button
                InkWell(
                  onTap: () async {
                    await _movieService.toggleWatchedStatus(movie.id);
                    setState(() {
                      // Refresh UI
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    color: movie.isWatched ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          movie.isWatched ? Icons.visibility : Icons.visibility_outlined,
                          size: 16,
                          color: movie.isWatched ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          movie.isWatched ? 'Watched' : 'Not watched',
                          style: TextStyle(
                            fontSize: 12,
                            color: movie.isWatched ? Colors.green : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
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
      await _movieService.addMovie(result);
      setState(() {
        // Refresh UI
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
      // The movie might have been updated or deleted
      if (result is Movie) {
        await _movieService.updateMovie(result);
      } else if (result is String && result == 'delete') {
        await _movieService.removeMovie(movie.id);
      }
      
      setState(() {
        // Refresh UI
      });
    }
  }
    // Filter movies based on search query
  List<Movie> _filterMovies(List<Movie> movies) {
    if (!_isSearching || _searchQuery.isEmpty) {
      return movies;
    }
    
    final query = _searchQuery.toLowerCase();
    return movies.where((movie) {
      return movie.title.toLowerCase().contains(query) || 
             (movie.director?.toLowerCase().contains(query) ?? false) ||
             (movie.releaseYear?.toString().contains(query) ?? false);
    }).toList();
  }
    // Toggle search bar visibility
  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (_isSearching) {
        // Just enabled search, but don't set query until user types
        _searchQuery = '';
      } else {
        // Disabled search, clear everything
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  // Clear the search query
  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      if (_isSearching) {
        _isSearching = false;
      }
    });
  }
}