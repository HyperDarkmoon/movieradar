import 'dart:async'; // Used for the debounce Timer
import 'package:flutter/material.dart';
import 'package:movieradar/models/movie.dart';
import 'package:movieradar/services/movie_service.dart';
import 'package:movieradar/services/tmdb_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AddMovieScreen extends StatefulWidget {
  const AddMovieScreen({super.key});

  @override
  State<AddMovieScreen> createState() => _AddMovieScreenState();
}

class _AddMovieScreenState extends State<AddMovieScreen> {
  final _formKey = GlobalKey<FormState>();
  final MovieService _movieService = MovieService();
  final TMDBService _tmdbService = TMDBService();
  
  // Search controller
  final TextEditingController _searchController = TextEditingController();
  
  // Search results
  List<MovieSearchResult> _searchResults = [];
  bool _isSearching = false;
  
  // Selected movie details
  MovieDetail? _selectedMovieDetails;
  
  // Form fields
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _directorController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _overviewController = TextEditingController();
  
  String? _posterUrl;
  bool _isWatched = false;
  
  // Debouncer for search
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
  
  // Search for movies with debounce
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
      
      setState(() {
        _isSearching = true;
      });
      
      _tmdbService.searchMovies(query).then((results) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }).catchError((error) {
        setState(() {
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching: $error')),
        );
      });
    });
  }
  
  // Update form with selected movie
  Future<void> _selectMovie(MovieSearchResult result) async {
    setState(() {
      _isSearching = true;
      _searchResults = [];
      _searchController.text = result.title;
    });
    
    try {
      final details = await _tmdbService.getMovieDetails(result.id);
      setState(() {
        _selectedMovieDetails = details;
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
        _posterUrl = details.posterPath != null ? _tmdbService.getImageUrl(details.posterPath) : null;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching movie details: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Movie'),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search bar for movies
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search for a movie',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: _onSearchChanged,
              ),
              
              // Search results
              if (_isSearching)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
                
              if (_searchResults.isNotEmpty)
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final result = _searchResults[index];
                      return ListTile(
                        leading: result.posterPath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: CachedNetworkImage(
                                imageUrl: _tmdbService.getImageUrl(result.posterPath),
                                width: 50,
                                placeholder: (context, url) => const SizedBox(
                                  width: 50,
                                  child: Center(child: CircularProgressIndicator()),
                                ),
                                errorWidget: (context, url, error) => const Icon(Icons.error),
                              ),
                            )
                          : const SizedBox(
                              width: 50,
                              child: Icon(Icons.movie),
                            ),
                        title: Text(result.title),
                        subtitle: Text(result.releaseYear != null ? 'Released: ${result.releaseYear}' : 'Unknown year'),
                        onTap: () => _selectMovie(result),
                      );
                    },
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Movie details form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_posterUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: _posterUrl!,
                              height: 200,
                              placeholder: (context, url) => const SizedBox(
                                height: 200,
                                child: Center(child: CircularProgressIndicator()),
                              ),
                              errorWidget: (context, url, error) => const Icon(Icons.error, size: 100),
                            ),
                          ),
                        ),
                      ),
                    
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Movie Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _directorController,
                      decoration: const InputDecoration(
                        labelText: 'Director',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _yearController,
                      decoration: const InputDecoration(
                        labelText: 'Release Year',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _overviewController,
                      decoration: const InputDecoration(
                        labelText: 'Overview',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    SwitchListTile(
                      title: const Text('Already watched?'),
                      value: _isWatched,
                      onChanged: (bool value) {
                        setState(() {
                          _isWatched = value;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    ElevatedButton(
                      onPressed: _saveMovie,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Save Movie'),
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
        director: _directorController.text.isEmpty ? null : _directorController.text,
        releaseYear: _yearController.text.isEmpty ? null : int.tryParse(_yearController.text),
        overview: _overviewController.text.isEmpty ? null : _overviewController.text,
        posterUrl: _posterUrl,
        isWatched: _isWatched,
        dateAdded: DateTime.now(),
        dateWatched: _isWatched ? DateTime.now() : null,
      );
      
      Navigator.pop(context, newMovie);
    }
  }
}
