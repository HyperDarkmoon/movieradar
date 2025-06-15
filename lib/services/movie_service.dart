import 'dart:math';
import 'dart:convert';
import 'package:movieradar/models/movie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MovieService {
  // In-memory storage of movies
  final List<Movie> _movies = [];
  static const String _storageKey = 'movies_data';
  bool _initialized = false;
  
  // Singleton pattern
  static final MovieService _instance = MovieService._internal();
  
  factory MovieService() {
    return _instance;
  }
  
  MovieService._internal();
  
  // Initialize the service by loading movies from storage
  Future<void> init() async {
    if (_initialized) return;
    
    await _loadMovies();
    _initialized = true;
  }
  
  // Load movies from local storage
  Future<void> _loadMovies() async {
    final prefs = await SharedPreferences.getInstance();
    final String? moviesJson = prefs.getString(_storageKey);
    
    if (moviesJson != null) {
      final List<dynamic> decodedList = json.decode(moviesJson);
      _movies.clear();
      _movies.addAll(decodedList.map((item) => _movieFromJson(item)));
    }
  }
  
  // Save movies to local storage
  Future<void> _saveMovies() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> encodableList = 
      _movies.map((movie) => _movieToJson(movie)).toList();
    await prefs.setString(_storageKey, json.encode(encodableList));
  }
  
  // Convert Movie object to JSON
  Map<String, dynamic> _movieToJson(Movie movie) {
    return {
      'id': movie.id,
      'title': movie.title,
      'posterUrl': movie.posterUrl,
      'releaseYear': movie.releaseYear,
      'director': movie.director,
      'overview': movie.overview,
      'isWatched': movie.isWatched,
      'dateAdded': movie.dateAdded.toIso8601String(),
      'dateWatched': movie.dateWatched?.toIso8601String(),
    };
  }
  
  // Create Movie object from JSON
  Movie _movieFromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'],
      title: json['title'],
      posterUrl: json['posterUrl'],
      releaseYear: json['releaseYear'],
      director: json['director'],
      overview: json['overview'],
      isWatched: json['isWatched'],
      dateAdded: DateTime.parse(json['dateAdded']),
      dateWatched: json['dateWatched'] != null ? DateTime.parse(json['dateWatched']) : null,
    );
  }

  // Get all movies
  List<Movie> getAllMovies() {
    return List.unmodifiable(_movies);
  }

  // Add a new movie
  Future<void> addMovie(Movie movie) async {
    _movies.add(movie);
    await _saveMovies();
  }
  // Remove a movie
  Future<void> removeMovie(String id) async {
    _movies.removeWhere((movie) => movie.id == id);
    await _saveMovies();
  }

  // Toggle watched status
  Future<Movie> toggleWatchedStatus(String id) async {
    final index = _movies.indexWhere((movie) => movie.id == id);
    if (index != -1) {
      final movie = _movies[index];
      final updatedMovie = movie.copyWith(
        isWatched: !movie.isWatched,
        dateWatched: !movie.isWatched ? DateTime.now() : null,
      );
      _movies[index] = updatedMovie;
      await _saveMovies();
      return updatedMovie;
    }
    throw Exception('Movie not found');
  }

  // Update movie details
  Future<Movie> updateMovie(Movie updatedMovie) async {
    final index = _movies.indexWhere((movie) => movie.id == updatedMovie.id);
    if (index != -1) {
      _movies[index] = updatedMovie;
      await _saveMovies();
      return updatedMovie;
    }
    throw Exception('Movie not found');
  }

  // Get watched movies
  List<Movie> getWatchedMovies() {
    return _movies.where((movie) => movie.isWatched).toList();
  }

  // Get unwatched movies
  List<Movie> getUnwatchedMovies() {
    return _movies.where((movie) => !movie.isWatched).toList();
  }

  // Generate a unique ID for a new movie
  String generateUniqueId() {
    return 'movie_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }
}
