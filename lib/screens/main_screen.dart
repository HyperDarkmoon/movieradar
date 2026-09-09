import 'dart:async';
import 'dart:math';

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

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  final MovieService _movieService = MovieService();
  final Random _random = Random();
  late TabController _tabController;
  bool _isGridView = false; // Default to list view
  bool _isPickingRandomMovie = false;
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
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search movies...',
                  hintStyle: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimary.withOpacity(0.7),
                  ),
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
        ],
        bottom: PreferredSize(
          // Use a fixed height that accommodates both scenarios
          preferredSize: Size.fromHeight(
            _isSearching && _searchQuery.isNotEmpty ? 90 : kToolbarHeight,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Display search info if searching
              if (_isSearching && _searchQuery.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 4.0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        child: Text(
                          'Search results for: "$_searchQuery"',
                          style: const TextStyle(fontStyle: FontStyle.italic),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                        tooltip: 'Clear search',
                        iconSize: 20,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
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
                    Tab(
                      text: 'Watchlist',
                      icon: Icon(Icons.playlist_add_check),
                    ),
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
          _buildWatchlistTab(),
          _buildMovieList(_filterMovies(_movieService.getWatchedMovies())),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddMovie,
        tooltip: 'Add Movie',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildWatchlistTab() {
    final watchlistMovies = _movieService.getUnwatchedMovies();
    final filteredWatchlist = _filterMovies(watchlistMovies);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: watchlistMovies.isEmpty || _isPickingRandomMovie
                  ? null
                  : () => _pickRandomMovie(watchlistMovies),
              icon: AnimatedRotation(
                turns: _isPickingRandomMovie ? 1 : 0,
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeInOut,
                child: const Icon(Icons.casino),
              ),
              label: Text(
                _isPickingRandomMovie
                    ? 'Picking a movie...'
                    : 'Pick Random Movie',
              ),
            ),
          ),
        ),
        Expanded(child: _buildMovieList(filteredWatchlist)),
      ],
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
              _isSearching && _searchQuery.isNotEmpty
                  ? 'No results found'
                  : 'No movies found',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              _isSearching && _searchQuery.isNotEmpty
                  ? 'Try a different search term'
                  : 'Add movies using the + button',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
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
        return FadeTransition(opacity: animation, child: child);
      },
      child: _isGridView ? _buildGridView(movies) : _buildListView(movies),
    );
  }

  Widget _buildListView(List<Movie> movies) {
    // Use ColorScheme to ensure text visibility in both light and dark modes
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

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
            highlightColor: Theme.of(
              context,
            ).colorScheme.primary.withOpacity(0.1),
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
                    child:
                        movie.posterUrl != null && movie.posterUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: movie.posterUrl!,
                            width: 100,
                            height: 150,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 100,
                              height: 150,
                              color: Colors.grey[300],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 100,
                              height: 150,
                              color: Colors.grey[300],
                              child: Center(
                                child: Text(
                                  movie.title.substring(0, 1),
                                  style: TextStyle(
                                    fontSize: 40,
                                    color: colorScheme
                                        .onSurface, // Use theme-aware color
                                  ),
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
                                style: TextStyle(
                                  fontSize: 40,
                                  color: colorScheme
                                      .onSurface, // Use theme-aware color
                                ),
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
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color:
                                colorScheme.onSurface, // Use theme-aware color
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          movie.releaseYear != null
                              ? '${movie.releaseYear} • ${movie.director ?? 'Unknown director'}'
                              : movie.director ?? '',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme
                                .onSurfaceVariant, // Use theme-aware color
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (movie.overview != null &&
                            movie.overview!.isNotEmpty)
                          Text(
                            movie.overview!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme
                                  .onSurfaceVariant, // Use theme-aware color
                            ),
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
                        movie.isWatched
                            ? Icons.visibility
                            : Icons.visibility_outlined,
                        color: movie.isWatched
                            ? Colors.green
                            : colorScheme
                                  .onSurfaceVariant, // Use theme-aware color
                      ),
                      onPressed: () async {
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
            highlightColor: Theme.of(
              context,
            ).colorScheme.primary.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Poster area
                Expanded(
                  flex: 3,
                  child: Hero(
                    tag: 'movie_${movie.id}',
                    child:
                        movie.posterUrl != null && movie.posterUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: movie.posterUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
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

                // Movie info area with unconstrained height to prevent overflow
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          movie.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (movie.releaseYear != null)
                          Text(
                            movie.releaseYear.toString(),
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
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
                    color: movie.isWatched
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          movie.isWatched
                              ? Icons.visibility
                              : Icons.visibility_outlined,
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
      MaterialPageRoute(builder: (context) => MovieDetailScreen(movie: movie)),
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

  Future<void> _pickRandomMovie(List<Movie> watchlistMovies) async {
    if (watchlistMovies.isEmpty || _isPickingRandomMovie) {
      return;
    }

    final selectedMovie = watchlistMovies[_random.nextInt(watchlistMovies.length)];

    setState(() {
      _isPickingRandomMovie = true;
    });

    final shouldOpenDetails = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _RandomMoviePickerDialog(
          watchlistMovies: watchlistMovies,
          selectedMovie: selectedMovie,
        );
      },
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isPickingRandomMovie = false;
    });

    if (shouldOpenDetails == true) {
      _navigateToMovieDetails(selectedMovie);
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

class _RandomMoviePickerDialog extends StatefulWidget {
  final List<Movie> watchlistMovies;
  final Movie selectedMovie;

  const _RandomMoviePickerDialog({
    required this.watchlistMovies,
    required this.selectedMovie,
  });

  @override
  State<_RandomMoviePickerDialog> createState() => _RandomMoviePickerDialogState();
}

class _RandomMoviePickerDialogState extends State<_RandomMoviePickerDialog>
    with SingleTickerProviderStateMixin {
  final Random _random = Random();
  late final AnimationController _revealController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _rotationAnimation;
  Timer? _shuffleTimer;
  late Movie _displayedMovie;
  bool _isRevealed = false;

  @override
  void initState() {
    super.initState();
    _displayedMovie = widget.watchlistMovies[
      _random.nextInt(widget.watchlistMovies.length)
    ];

    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeOutBack,
    );

    _rotationAnimation = Tween<double>(begin: 0.06, end: 0.0).animate(
      CurvedAnimation(parent: _revealController, curve: Curves.easeOutCubic),
    );

    _startShuffleAnimation();
  }

  @override
  void dispose() {
    _shuffleTimer?.cancel();
    _revealController.dispose();
    super.dispose();
  }

  void _startShuffleAnimation() {
    int tick = 0;
    _shuffleTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      tick++;
      if (tick >= 16) {
        timer.cancel();
        if (!mounted) {
          return;
        }

        setState(() {
          _displayedMovie = widget.selectedMovie;
          _isRevealed = true;
        });

        _revealController.forward();
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _displayedMovie = widget.watchlistMovies[
          _random.nextInt(widget.watchlistMovies.length)
        ];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isRevealed ? 'Tonight\'s pick' : 'Shuffling your watchlist...',
      ),
      content: SizedBox(
        width: 320,
        child: AnimatedBuilder(
          animation: _revealController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _isRevealed ? _rotationAnimation.value : 0,
              child: Transform.scale(
                scale: _isRevealed ? _scaleAnimation.value : 1,
                child: child,
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.35),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 190,
                    child: _displayedMovie.posterUrl != null &&
                            _displayedMovie.posterUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: _displayedMovie.posterUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => _buildPosterFallback(),
                          )
                        : _buildPosterFallback(),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _displayedMovie.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _displayedMovie.releaseYear != null
                              ? '${_displayedMovie.releaseYear} • ${_displayedMovie.director ?? 'Unknown director'}'
                              : (_displayedMovie.director ?? 'Unknown director'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: _isRevealed ? () => Navigator.of(context).pop(true) : null,
          child: const Text('Open Details'),
        ),
      ],
    );
  }

  Widget _buildPosterFallback() {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Text(
          _displayedMovie.title.substring(0, 1),
          style: const TextStyle(fontSize: 54),
        ),
      ),
    );
  }
}
