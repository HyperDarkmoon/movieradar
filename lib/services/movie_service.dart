import 'dart:math';
import 'dart:convert';
import 'package:movieradar/models/movie.dart';
import 'package:movieradar/models/import_result.dart';
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

  // Export movies to JSON string
  String exportToJson() {
    final List<Map<String, dynamic>> encodableList = 
      _movies.map((movie) => _movieToJson(movie)).toList();
    return json.encode({
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'movies': encodableList,
    });
  }
  
  // Import movies from JSON string
  Future<void> importFromJson(String jsonString) async {
    try {
      final Map<String, dynamic> data = json.decode(jsonString);
      
      // Verify that this is a valid export file
      if (!data.containsKey('movies') || !data.containsKey('version')) {
        throw Exception('Invalid export file format');
      }
      
      // Get movies from the import
      final List<dynamic> importedMovies = data['movies'];
      
      // Convert to Movie objects
      final List<Movie> movies = importedMovies.map<Movie>((item) => _movieFromJson(item)).toList();
      
      // Replace existing movies or merge
      _movies.clear();
      _movies.addAll(movies);
      
      // Save to local storage
      await _saveMovies();
      
      return;
    } catch (e) {
      throw Exception('Failed to import movies: $e');
    }
  }
  
  // Merge imported movies with existing ones
  Future<void> mergeFromJson(String jsonString) async {
    try {
      final Map<String, dynamic> data = json.decode(jsonString);
      
      // Verify that this is a valid export file
      if (!data.containsKey('movies') || !data.containsKey('version')) {
        throw Exception('Invalid export file format');
      }
      
      // Get movies from the import
      final List<dynamic> importedMovies = data['movies'];
      
      // Convert to Movie objects
      final List<Movie> movies = importedMovies.map<Movie>((item) => _movieFromJson(item)).toList();
      
      // Create a set of existing movie IDs for faster lookup
      final Set<String> existingIds = _movies.map((m) => m.id).toSet();
      
      // Add only movies that don't exist yet
      for (final movie in movies) {
        if (!existingIds.contains(movie.id)) {
          _movies.add(movie);
        }
      }
      
      // Save to local storage
      await _saveMovies();
      
      return;
    } catch (e) {
      throw Exception('Failed to merge movies: $e');
    }
  }

  // Export movies to a JSON string
  String exportMovies({bool onlyWatched = false, bool onlyUnwatched = false}) {
    List<Movie> moviesToExport = _movies;
    
    if (onlyWatched) {
      moviesToExport = getWatchedMovies();
    } else if (onlyUnwatched) {
      moviesToExport = getUnwatchedMovies();
    }
    
    final exportData = {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'movies': moviesToExport.map((movie) => _movieToJson(movie)).toList(),
    };
    
    return json.encode(exportData);
  }
  
  // Import movies from a JSON string
  Future<ImportResult> importMovies(String jsonString) async {
    try {
      final Map<String, dynamic> importData = json.decode(jsonString);
      
      // Basic validation
      if (!importData.containsKey('movies') || !(importData['movies'] is List)) {
        return ImportResult(
          success: false,
          message: 'Invalid import file format',
          moviesImported: 0,
        );
      }
      
      final List<dynamic> moviesList = importData['movies'];
      int importCount = 0;
      
      for (var movieJson in moviesList) {
        try {
          final Movie movie = _movieFromJson(movieJson);
          
          // Check if the movie already exists (by title and release year)
          final existingMovieIndex = _movies.indexWhere((m) => 
            m.title == movie.title && m.releaseYear == movie.releaseYear);
          
          if (existingMovieIndex != -1) {
            // Skip or update existing movie
            continue;
          } else {
            // Add new movie with a new unique ID
            final newMovie = Movie(
              id: generateUniqueId(),
              title: movie.title,
              posterUrl: movie.posterUrl,
              releaseYear: movie.releaseYear,
              director: movie.director,
              overview: movie.overview,
              isWatched: movie.isWatched,
              dateAdded: DateTime.now(), // Set current date as import date
              dateWatched: movie.dateWatched,
            );
            
            _movies.add(newMovie);
            importCount++;
          }
        } catch (e) {
          // Skip invalid entries
          continue;
        }
      }
      
      // Save changes to local storage
      await _saveMovies();
      
      return ImportResult(
        success: true,
        message: 'Successfully imported $importCount movies',
        moviesImported: importCount,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        message: 'Error importing movies: ${e.toString()}',
        moviesImported: 0,
      );
    }
  }
}
