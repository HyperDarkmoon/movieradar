import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:movieradar/models/movie.dart';

class TMDBService {
  // You should register for your own API key at https://www.themoviedb.org/
  static const String apiKey = '9c14092d90d0b9514c7e948932d635c9';
  static const String baseUrl = 'https://api.themoviedb.org/3';
  static const String imageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  // Search for movies with a query
  Future<List<MovieSearchResult>> searchMovies(String query) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/search/movie?api_key=$apiKey&query=${Uri.encodeComponent(query)}'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];
        
        return results
          .where((movie) => movie['title'] != null)
          .map((movie) => MovieSearchResult.fromJson(movie))
          .toList();
      } else {
        throw Exception('Failed to search movies: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      throw Exception('Network error: Please check your internet connection. (${e.message})');
    } on HttpException catch (e) {
      throw Exception('HTTP error: ${e.message}');
    } on FormatException {
      throw Exception('Invalid response format from server');
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } catch (e) {
      throw Exception('Error searching: $e');
    }
  }

  // Get detailed information about a movie by its ID
  Future<MovieDetail> getMovieDetails(int movieId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/movie/$movieId?api_key=$apiKey&append_to_response=credits'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return MovieDetail.fromJson(data);
      } else {
        throw Exception('Failed to load movie details: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      throw Exception('Network error: Please check your internet connection. (${e.message})');
    } on HttpException catch (e) {
      throw Exception('HTTP error: ${e.message}');
    } on FormatException {
      throw Exception('Invalid response format from server');
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } catch (e) {
      throw Exception('Error fetching details: $e');
    }
  }

  // Get full image URL
  String getImageUrl(String? path) {
    if (path == null || path.isEmpty) {
      return '';
    }
    return '$imageBaseUrl$path';
  }
}

class MovieSearchResult {
  final int id;
  final String title;
  final String? posterPath;
  final int? releaseYear;
  final String? overview;

  MovieSearchResult({
    required this.id,
    required this.title,
    this.posterPath,
    this.releaseYear,
    this.overview,
  });

  factory MovieSearchResult.fromJson(Map<String, dynamic> json) {
    // Extract year from release date if available
    int? year;
    if (json['release_date'] != null && json['release_date'].toString().isNotEmpty) {
      try {
        year = DateTime.parse(json['release_date']).year;
      } catch (e) {
        // Handle invalid date formats
        year = null;
      }
    }

    return MovieSearchResult(
      id: json['id'],
      title: json['title'],
      posterPath: json['poster_path'],
      releaseYear: year,
      overview: json['overview'],
    );
  }
}

class MovieDetail {
  final int id;
  final String title;
  final String? posterPath;
  final int? releaseYear;
  final String? overview;
  final String? director;
  
  MovieDetail({
    required this.id,
    required this.title,
    this.posterPath,
    this.releaseYear,
    this.overview,
    this.director,
  });

  factory MovieDetail.fromJson(Map<String, dynamic> json) {
    // Extract year from release date
    int? year;
    if (json['release_date'] != null && json['release_date'].toString().isNotEmpty) {
      try {
        year = DateTime.parse(json['release_date']).year;
      } catch (e) {
        year = null;
      }
    }

    // Extract director from credits
    String? director;
    if (json['credits'] != null && json['credits']['crew'] != null) {
      final directors = (json['credits']['crew'] as List)
          .where((crew) => crew['job'] == 'Director')
          .toList();
      if (directors.isNotEmpty) {
        director = directors.first['name'];
      }
    }

    return MovieDetail(
      id: json['id'],
      title: json['title'],
      posterPath: json['poster_path'],
      releaseYear: year,
      overview: json['overview'],
      director: director,
    );
  }

  // Convert to our Movie model
  Movie toMovie({required String uniqueId}) {
    return Movie(
      id: uniqueId,
      title: title,
      posterUrl: posterPath != null ? 'https://image.tmdb.org/t/p/w500$posterPath' : null,
      releaseYear: releaseYear,
      director: director,
      dateAdded: DateTime.now(),
    );
  }
}
