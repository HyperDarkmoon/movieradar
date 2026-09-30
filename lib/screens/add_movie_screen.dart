import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:movieradar/models/movie.dart';
import 'package:movieradar/services/movie_service.dart';
import 'package:movieradar/services/tmdb_service.dart';
import 'package:movieradar/theme/cinematic_theme.dart';
import 'package:movieradar/widgets/cinematic_widgets.dart';

class AddMovieScreen extends StatefulWidget {
  const AddMovieScreen({super.key});

  @override
  State<AddMovieScreen> createState() => _AddMovieScreenState();
}

class _AddMovieScreenState extends State<AddMovieScreen> {
  final _formKey = GlobalKey<FormState>();
  final MovieService _movieService = MovieService();
  final TMDBService _tmdbService = TMDBService();

  final TextEditingController _searchController = TextEditingController();
  List<MovieSearchResult> _searchResults = [];
  bool _isSearching = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _directorController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _overviewController = TextEditingController();

  String? _posterUrl;
  bool _isWatched = false;

  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    _directorController.dispose();
    _yearController.dispose();
    _overviewController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isEmpty) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
        return;
      }
      setState(() => _isSearching = true);

      _tmdbService.searchMovies(query).then((results) {
        if (!mounted) return;
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }).catchError((error) {
        if (!mounted) return;
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching: $error')),
        );
      });
    });
  }

  Future<void> _selectMovie(MovieSearchResult result) async {
    setState(() {
      _isSearching = true;
      _searchResults = [];
      _searchController.text = result.title;
    });

    try {
      final details = await _tmdbService.getMovieDetails(result.id);
      if (!mounted) return;
      setState(() {
        _titleController.text = details.title;
        if (details.director != null) {
          _directorController.text = details.director!;
        }
        if (details.releaseYear != null) {
          _yearController.text = details.releaseYear.toString();
        }
        if (details.overview != null) {
          _overviewController.text = details.overview!;
        }
        _posterUrl = details.posterPath != null
            ? _tmdbService.getImageUrl(details.posterPath)
            : null;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching movie details: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = CinematicColors.of(context);

    return CinematicScaffold(
      appBar: AppBar(
        title: const Text(
          'ADD MOVIE',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
            fontSize: 17,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // TMDB search
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search TMDB',
                  hintText: 'Search for a movie...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: _onSearchChanged,
              ),
              const SizedBox(height: 12),

              if (_isSearching)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),

              if (_searchResults.isNotEmpty)
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: colors.glass,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final result = _searchResults[index];
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: result.posterPath != null
                              ? CachedNetworkImage(
                                  imageUrl: _tmdbService
                                      .getImageUrl(result.posterPath),
                                  width: 46,
                                  height: 66,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      const SizedBox(
                                    width: 46,
                                    height: 66,
                                    child: ShimmerBox(
                                      borderRadius: 8,
                                      width: 46,
                                      height: 66,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const _ResultFallback(),
                                )
                              : const _ResultFallback(),
                        ),
                        title: Text(
                          result.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          result.releaseYear != null
                              ? 'Released ${result.releaseYear}'
                              : 'Unknown year',
                          style: TextStyle(
                            fontSize: 12,
                            color: Cinematic.textSecondaryOf(context),
                          ),
                        ),
                        trailing: const Icon(
                          Icons.add_circle_outline,
                          color: Cinematic.neonViolet,
                        ),
                        onTap: () => _selectMovie(result),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 20),

              // Poster preview
              if (_posterUrl != null)
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: colors.glowSoft,
                          blurRadius: 24,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: CachedNetworkImage(
                        imageUrl: _posterUrl!,
                        height: 220,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Manual entry form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Movie Title',
                        prefixIcon: Icon(Icons.movie_outlined),
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Please enter a title'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _directorController,
                      decoration: const InputDecoration(
                        labelText: 'Director',
                        prefixIcon: Icon(Icons.theater_comedy_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _yearController,
                      decoration: const InputDecoration(
                        labelText: 'Release Year',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _overviewController,
                      decoration: const InputDecoration(
                        labelText: 'Overview',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      title: const Text(
                        'ALREADY WATCHED',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      subtitle: const Text('Add it directly to your history'),
                      value: _isWatched,
                      onChanged: (value) => setState(() => _isWatched = value),
                    ),
                    const SizedBox(height: 20),
                    CinematicButton(
                      label: 'SAVE MOVIE',
                      icon: Icons.check,
                      onPressed: _saveMovie,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveMovie() {
    if (_formKey.currentState!.validate()) {
      final newMovie = Movie(
        id: _movieService.generateUniqueId(),
        title: _titleController.text,
        director:
            _directorController.text.isEmpty ? null : _directorController.text,
        releaseYear: _yearController.text.isEmpty
            ? null
            : int.tryParse(_yearController.text),
        overview:
            _overviewController.text.isEmpty ? null : _overviewController.text,
        posterUrl: _posterUrl,
        isWatched: _isWatched,
        dateAdded: DateTime.now(),
        dateWatched: _isWatched ? DateTime.now() : null,
      );

      Navigator.pop(context, newMovie);
    }
  }
}

class _ResultFallback extends StatelessWidget {
  const _ResultFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 66,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: Cinematic.glowGradient,
      ),
      child: const Icon(Icons.local_movies, size: 22, color: Colors.white),
    );
  }
}