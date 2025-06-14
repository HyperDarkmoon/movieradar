import 'dart:math';
import 'package:movieradar/models/movie.dart';

class MovieService {
  // In-memory storage of movies
  final List<Movie> _movies = [];

  // Get all movies
  List<Movie> getAllMovies() {
    return List.unmodifiable(_movies);
  }

  // Add a new movie
  void addMovie(Movie movie) {
    _movies.add(movie);
  }

  // Remove a movie
  void removeMovie(String id) {
    _movies.removeWhere((movie) => movie.id == id);
  }

  // Toggle watched status
  Movie toggleWatchedStatus(String id) {
    final index = _movies.indexWhere((movie) => movie.id == id);
    if (index != -1) {
      final movie = _movies[index];
      final updatedMovie = movie.copyWith(
        isWatched: !movie.isWatched,
        dateWatched: !movie.isWatched ? DateTime.now() : null,
      );
      _movies[index] = updatedMovie;
      return updatedMovie;
    }
    throw Exception('Movie not found');
  }

  // Update movie details
  Movie updateMovie(Movie updatedMovie) {
    final index = _movies.indexWhere((movie) => movie.id == updatedMovie.id);
    if (index != -1) {
      _movies[index] = updatedMovie;
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
