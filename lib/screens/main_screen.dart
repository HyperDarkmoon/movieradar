import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:movieradar/models/movie.dart';
import 'package:movieradar/screens/add_movie_screen.dart';
import 'package:movieradar/screens/movie_detail_screen.dart';
import 'package:movieradar/screens/settings_screen.dart';
import 'package:movieradar/services/movie_service.dart';
import 'package:movieradar/theme/cinematic_theme.dart';
import 'package:movieradar/utils/cinematic_routes.dart';
import 'package:movieradar/widgets/cinematic_widgets.dart';
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
  bool _isGridView = false;
  bool _isPickingRandomMovie = false;

  // Search
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
    _loadViewPreference();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_isSearching) {
      setState(() => _searchQuery = _searchController.text);
    }
  }

  Future<void> _loadViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isGridView = prefs.getBool('is_grid_view') ?? false);
  }

  Future<void> _saveViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_grid_view', _isGridView);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: CinematicBackground()),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: _isSearching ? _buildSearchField() : _buildWordmark(),
            actions: [
              if (!_isSearching)
                _AppIcon(
                  icon: Icons.search,
                  tooltip: 'Search',
                  onTap: _toggleSearch,
                ),
              _AppIcon(
                icon: _isGridView ? Icons.view_list : Icons.grid_view,
                tooltip: _isGridView ? 'List View' : 'Grid View',
                onTap: () async {
                  setState(() => _isGridView = !_isGridView);
                  await _saveViewPreference();
                },
              ),
              _AppIcon(
                icon: Icons.settings,
                tooltip: 'Settings',
                onTap: () => _openSettings(),
              ),
              const SizedBox(width: 8),
            ],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(
                _isSearching && _searchQuery.isNotEmpty ? 98 : 62,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isSearching && _searchQuery.isNotEmpty)
                    _buildSearchFooter(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: _buildTabBar(),
                  ),
                ],
              ),
            ),
          ),
          body: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: (!_isSearching || _searchQuery.isEmpty)
                      ? _buildCinematicHero(
                          key: const ValueKey('hero'),
                          unwatched: _movieService.getUnwatchedMovies(),
                          watched: _movieService.getWatchedMovies(),
                        )
                      : const SizedBox.shrink(key: ValueKey('no-hero')),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildWatchlistTab(),
                      _buildMovieList(_filterMovies(
                        _movieService.getWatchedMovies(),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: NeonFab(
            icon: Icons.add,
            tooltip: 'Add Movie',
            onPressed: _navigateToAddMovie,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // App bar
  // ---------------------------------------------------------------------

  Widget _buildWordmark() {
    return ShaderMask(
      shaderCallback: (bounds) => Cinematic.glowGradient.createShader(bounds),
      child: const Text(
        'MOVIERADAR',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: 4,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      style: const TextStyle(color: Cinematic.textPrimaryDark),
      cursorColor: Cinematic.neonViolet,
      decoration: InputDecoration(
        hintText: 'Search your radar...',
        hintStyle: TextStyle(
          color: Cinematic.textSecondaryDark.withValues(alpha: 0.7),
        ),
        border: InputBorder.none,
        icon: const Icon(
          Icons.search,
          color: Cinematic.neonViolet,
          size: 22,
        ),
        suffixIcon: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _searchController.clear();
            _toggleSearch();
          },
        ),
      ),
    );
  }

  Widget _buildSearchFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Results for "$_searchQuery"',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Cinematic.textSecondaryDark,
                fontStyle: FontStyle.italic,
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.clear, color: Cinematic.neonViolet, size: 18),
            tooltip: 'Clear search',
            onPressed: _clearSearch,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Cinematic.surfaceBright.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: Cinematic.glowGradient,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Cinematic.textSecondaryDark,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
          letterSpacing: 1.2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          letterSpacing: 1.2,
        ),
        tabs: const [
          Tab(text: 'WATCHLIST'),
          Tab(text: 'WATCHED'),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Hero
  // ---------------------------------------------------------------------

  Widget _buildCinematicHero({
    required Key key,
    required List<Movie> unwatched,
    required List<Movie> watched,
  }) {
    final all = [...unwatched, ...watched];
    final posters = all.take(3).toList();
    const double heroHeight = 186;

    return Padding(
      key: key,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: heroHeight,
          decoration: BoxDecoration(
            gradient: Cinematic.duskGradient,
            border: Border.all(
              color: Cinematic.neonViolet.withValues(alpha: 0.18),
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Nebula glows
              Positioned(
                left: -40,
                bottom: -60,
                child: _GlowOrb(
                  radius: 130,
                  color: Cinematic.deepViolet.withValues(alpha: 0.45),
                ),
              ),
              Positioned(
                right: 80,
                top: -70,
                child: _GlowOrb(
                  radius: 150,
                  color: Cinematic.fuchsia.withValues(alpha: 0.22),
                ),
              ),
              // Poster collage
              if (posters.isNotEmpty)
                Positioned(
                  right: 6,
                  bottom: -18,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < posters.length; i++)
                        Transform.translate(
                          offset: Offset(14 * (i - 1).toDouble(), -(i % 2) * 12.0),
                          child: Transform.rotate(
                            angle: (i - 1) * 0.14,
                            child: Opacity(
                              opacity: 0.94,
                              child: _FloatingPoster(movie: posters[i]),
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              else
                Positioned(
                  right: 16,
                  top: 30,
                  child: Icon(
                    Icons.movie_filter,
                    size: 92,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              // Headline copy
              Positioned(
                left: 20,
                top: 22,
                right: 150,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          Cinematic.glowGradient.createShader(bounds),
                      child: Text(
                        all.isEmpty
                            ? 'START YOUR CINEMA'
                            : 'PICK YOUR NEXT FILM',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 22,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        NeonChip(
                          label: '${unwatched.length} to watch',
                          icon: Icons.play_circle_outline,
                          active: true,
                        ),
                        NeonChip(
                          label: '${watched.length} watched',
                          icon: Icons.check_circle_outline,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Bottom strip
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Cinematic.neonViolet.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Tabs
  // ---------------------------------------------------------------------

  Widget _buildWatchlistTab() {
    final watchlistMovies = _movieService.getUnwatchedMovies();
    final filteredWatchlist = _filterMovies(watchlistMovies);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: SizedBox(
            width: double.infinity,
            child: _RandomPickerButton(
              enabled: watchlistMovies.isNotEmpty && !_isPickingRandomMovie,
              picking: _isPickingRandomMovie,
              onPressed: () => _pickRandomMovie(watchlistMovies),
            ),
          ),
        ),
        Expanded(child: _buildMovieList(filteredWatchlist)),
      ],
    );
  }

  Widget _buildMovieList(List<Movie> movies) {
    if (movies.isEmpty) {
      return _buildEmptyState(movies);
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 340),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (Widget child, Animation<double> animation) =>
          FadeTransition(opacity: animation, child: child),
      child: _isGridView
          ? _buildGridView(movies)
          : _buildListView(movies),
    );
  }

  Widget _buildEmptyState(List<Movie> movies) {
    final searching = _isSearching && _searchQuery.isNotEmpty;
    final colors = CinematicColors.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: Cinematic.glowGradient,
                boxShadow: [
                  BoxShadow(
                    color: colors.glowSoft,
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.movie_outlined,
                size: 44,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              searching ? 'Nothing found' : 'The screen is dark',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    letterSpacing: 1,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              searching
                  ? 'Try a different search term.'
                  : 'Add movies with the + button and let MovieRadar do the rest.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Cinematic.textSecondaryDark,
                  ),
              textAlign: TextAlign.center,
            ),
            if (searching)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: CinematicButton(
                  label: 'Clear search',
                  icon: Icons.close,
                  onPressed: _clearSearch,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(List<Movie> movies) {
    return ListView.builder(
      key: const ValueKey('list-view'),
      itemCount: movies.length,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 96),
      itemBuilder: (context, index) => _CinematicListCard(
        movie: movies[index],
        onTap: () => _navigateToMovieDetails(movies[index]),
        onToggleWatched: () => _toggleWatched(movies[index]),
      ),
    );
  }

  Widget _buildGridView(List<Movie> movies) {
    return GridView.builder(
      key: const ValueKey('grid-view'),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.58,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: movies.length,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 96),
      itemBuilder: (context, index) => _CinematicGridCard(
        movie: movies[index],
        onTap: () => _navigateToMovieDetails(movies[index]),
        onToggleWatched: () => _toggleWatched(movies[index]),
      ),
    );
  }

  Future<void> _toggleWatched(Movie movie) async {
    await _movieService.toggleWatchedStatus(movie.id);
    if (mounted) setState(() {});
  }

  // ---------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------

  void _openSettings() {
    context.pushCinematic(const SettingsScreen());
  }

  Future<void> _navigateToAddMovie() async {
    final result = await context.pushCinematic<Movie>(
      const AddMovieScreen(),
    );
    if (result != null) {
      await _movieService.addMovie(result);
      if (mounted) setState(() {});
    }
  }

  Future<void> _navigateToMovieDetails(Movie movie) async {
    final result = await context.pushCinematic<Object?>(
      MovieDetailScreen(movie: movie),
    );
    if (result != null && mounted) {
      if (result is Movie) {
        await _movieService.updateMovie(result);
      } else if (result is String && result == 'delete') {
        await _movieService.removeMovie(movie.id);
      }
      setState(() {});
    }
  }

  Future<void> _pickRandomMovie(List<Movie> watchlistMovies) async {
    if (watchlistMovies.isEmpty || _isPickingRandomMovie) return;

    final selectedMovie =
        watchlistMovies[_random.nextInt(watchlistMovies.length)];
    setState(() => _isPickingRandomMovie = true);

    final shouldOpenDetails = await context.pushCinematicDialog<bool>(
      _RandomMoviePickerDialog(
        watchlistMovies: watchlistMovies,
        selectedMovie: selectedMovie,
      ),
    );

    if (!mounted) return;
    setState(() => _isPickingRandomMovie = false);

    if (shouldOpenDetails == true) {
      _navigateToMovieDetails(selectedMovie);
    }
  }

  // ---------------------------------------------------------------------
  // Search
  // ---------------------------------------------------------------------

  List<Movie> _filterMovies(List<Movie> movies) {
    if (!_isSearching || _searchQuery.isEmpty) return movies;
    final query = _searchQuery.toLowerCase();
    return movies.where((movie) {
      return movie.title.toLowerCase().contains(query) ||
          (movie.director?.toLowerCase().contains(query) ?? false) ||
          (movie.releaseYear?.toString().contains(query) ?? false);
    }).toList();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      _searchQuery = '';
      if (!_isSearching) _searchController.clear();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _isSearching = false);
  }
}

// ---------------------------------------------------------------------
// Small building blocks
// ---------------------------------------------------------------------

class _AppIcon extends StatelessWidget {
  const _AppIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = CinematicColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.glass,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            child: Icon(icon, size: 21, color: colors.glow),
          ),
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.radius, required this.color});

  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0.0)],
        ),
      ),
    );
  }
}

class _FloatingPoster extends StatelessWidget {
  const _FloatingPoster({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 92,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 14),
        ],
      ),
      child: MoviePoster(
        movie: movie,
        borderRadius: 9,
        glow: true,
      ),
    );
  }
}

class _RandomPickerButton extends StatefulWidget {
  const _RandomPickerButton({
    required this.enabled,
    required this.picking,
    required this.onPressed,
  });

  final bool enabled;
  final bool picking;
  final VoidCallback onPressed;

  @override
  State<_RandomPickerButton> createState() => _RandomPickerButtonState();
}

class _RandomPickerButtonState extends State<_RandomPickerButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void didUpdateWidget(covariant _RandomPickerButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.picking && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!widget.picking && _spin.isAnimating) {
      _spin.stop();
      _spin.value = 0;
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = CinematicColors.of(context);
    final canTap = widget.enabled;

    return GestureDetector(
      onTapDown: (_) {
        if (canTap) setState(() => _pressed = true);
      },
      onTapUp: (_) {
        if (canTap) setState(() => _pressed = false);
        if (canTap) widget.onPressed();
      },
      onTapCancel: () {
        if (canTap) setState(() => _pressed = false);
      },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            gradient: canTap
                ? Cinematic.glowGradient
                : const LinearGradient(
                    colors: [Color(0xFF3B3057), Color(0xFF3B3057)],
                  ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: canTap
                  ? Colors.white.withValues(alpha: 0.25)
                  : Colors.transparent,
            ),
            boxShadow: canTap
                ? [BoxShadow(color: colors.glowSoft, blurRadius: 22)]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedRotation(
                turns: _spin.value,
                duration: const Duration(milliseconds: 700),
                child: Icon(
                  Icons.casino,
                  size: 20,
                  color: canTap
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.35),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                widget.picking ? 'PICKING A MOVIE...' : 'SURPRISE ME',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: canTap
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Movie cards
// ---------------------------------------------------------------------

class _CinematicListCard extends StatelessWidget {
  const _CinematicListCard({
    required this.movie,
    required this.onTap,
    required this.onToggleWatched,
  });

  final Movie movie;
  final VoidCallback onTap;
  final VoidCallback onToggleWatched;

  @override
  Widget build(BuildContext context) {
    final colors = CinematicColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    final meta = [
      if (movie.releaseYear != null) movie.releaseYear.toString(),
      movie.director ?? 'Unknown director',
    ].join('  •  ');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: movie.isWatched
              ? colors.glow.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        splashColor: colors.glow.withValues(alpha: 0.14),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'movie_${movie.id}',
                child: MoviePoster(
                  movie: movie,
                  width: 92,
                  height: 138,
                  borderRadius: 12,
                  glow: !movie.isWatched,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 138,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        movie.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.glow.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (movie.overview != null &&
                          movie.overview!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          movie.overview!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(height: 1.35),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _WatchedBadge(
                watched: movie.isWatched,
                onTap: onToggleWatched,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CinematicGridCard extends StatelessWidget {
  const _CinematicGridCard({
    required this.movie,
    required this.onTap,
    required this.onToggleWatched,
  });

  final Movie movie;
  final VoidCallback onTap;
  final VoidCallback onToggleWatched;

  @override
  Widget build(BuildContext context) {
    final colors = CinematicColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: movie.isWatched
              ? colors.glow.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        splashColor: colors.glow.withValues(alpha: 0.14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Hero(
                tag: 'movie_${movie.id}',
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MoviePoster(movie: movie, borderRadius: 0),
                    // Title scrim
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(10, 26, 10, 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Cinematic.bgTop.withValues(alpha: 0.96),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              movie.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                shadows: const [
                                  Shadow(color: Colors.black54, blurRadius: 6),
                                ],
                              ),
                            ),
                            if (movie.releaseYear != null)
                              Text(
                                movie.releaseYear.toString(),
                                style: textTheme.bodySmall?.copyWith(
                                  color: colors.glow,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.6,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _WatchedStrip(watched: movie.isWatched, onTap: onToggleWatched),
          ],
        ),
      ),
    );
  }
}

class _WatchedBadge extends StatelessWidget {
  const _WatchedBadge({required this.watched, required this.onTap});

  final bool watched;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = CinematicColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: watched
              ? Cinematic.glowGradient
              : const LinearGradient(
                  colors: [Color(0xFF2A2148), Color(0xFF241B40)],
                ),
          border: Border.all(
            color: watched
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.08),
          ),
          boxShadow: watched
              ? [BoxShadow(color: colors.glowSoft, blurRadius: 14)]
              : null,
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Icon(
              watched ? Icons.visibility : Icons.visibility_outlined,
              key: ValueKey(watched),
              size: 20,
              color: watched ? Colors.white : colors.glow,
            ),
          ),
        ),
      ),
    );
  }
}

class _WatchedStrip extends StatelessWidget {
  const _WatchedStrip({required this.watched, required this.onTap});

  final bool watched;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = CinematicColors.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: watched
            ? Cinematic.deepViolet.withValues(alpha: 0.22)
            : colors.glass,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Icon(
              watched ? Icons.visibility : Icons.visibility_outlined,
              key: ValueKey(watched),
              size: 14,
              color: watched ? colors.glow : Cinematic.textSecondaryDark,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onTap,
            child: Text(
              watched ? 'WATCHED' : 'NOT WATCHED',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: watched ? colors.glow : Cinematic.textSecondaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Random movie picker dialog
// ---------------------------------------------------------------------

class _RandomMoviePickerDialog extends StatefulWidget {
  const _RandomMoviePickerDialog({
    required this.watchlistMovies,
    required this.selectedMovie,
  });

  final List<Movie> watchlistMovies;
  final Movie selectedMovie;

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
    _displayedMovie =
        widget.watchlistMovies[_random.nextInt(widget.watchlistMovies.length)];

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
        if (!mounted) return;
        setState(() {
          _displayedMovie = widget.selectedMovie;
          _isRevealed = true;
        });
        _revealController.forward();
        return;
      }
      if (!mounted) return;
      setState(() {
        _displayedMovie =
            widget.watchlistMovies[_random.nextInt(widget.watchlistMovies.length)];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = CinematicColors.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 340,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Cinematic.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: _isRevealed
                      ? colors.glow.withValues(alpha: 0.7)
                      : colors.glow.withValues(alpha: 0.25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.glowSoft,
                    blurRadius: _isRevealed ? 44 : 20,
                    spreadRadius: _isRevealed ? 4 : 0,
                  ),
                  const BoxShadow(color: Colors.black54, blurRadius: 30),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Text(
                      _isRevealed ? "TONIGHT'S PICK" : 'SHUFFLING...',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                        color: Cinematic.neonViolet,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  AnimatedBuilder(
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
                    child: MoviePoster(
                      movie: _displayedMovie,
                      height: 240,
                      borderRadius: 18,
                      glow: _isRevealed,
                    ),
                  ),
                  const SizedBox(height: 14),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _displayedMovie.title,
                      key: ValueKey(_displayedMovie.id),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            color: Colors.white,
                          ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _displayedMovie.releaseYear != null
                        ? '${_displayedMovie.releaseYear}  •  ${_displayedMovie.director ?? 'Unknown director'}'
                        : (_displayedMovie.director ?? 'Unknown director'),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Cinematic.textSecondaryDark,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () =>
                              Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          child: const Text('CLOSE'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _isRevealed
                            ? CinematicButton(
                                label: 'OPEN DETAILS',
                                icon: Icons.arrow_forward,
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}