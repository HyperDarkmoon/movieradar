class Movie {
  final String id;
  final String title;
  final String? posterUrl;
  final int? releaseYear;
  final String? director;
  final String? overview;
  bool isWatched;
  final DateTime dateAdded;
  DateTime? dateWatched;

  Movie({
    required this.id,
    required this.title,
    this.posterUrl,
    this.releaseYear,
    this.director,
    this.overview,
    this.isWatched = false,
    required this.dateAdded,
    this.dateWatched,
  });

  // Create a copy of the movie with updated fields
  Movie copyWith({
    String? title,
    String? posterUrl,
    int? releaseYear,
    String? director,
    String? overview,
    bool? isWatched,
    DateTime? dateWatched,
  }) {
    return Movie(
      id: this.id,
      title: title ?? this.title,
      posterUrl: posterUrl ?? this.posterUrl,
      releaseYear: releaseYear ?? this.releaseYear,
      director: director ?? this.director,
      overview: overview ?? this.overview,
      isWatched: isWatched ?? this.isWatched,
      dateAdded: this.dateAdded,
      dateWatched: dateWatched ?? this.dateWatched,
    );
  }
}
