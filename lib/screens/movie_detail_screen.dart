import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:movieradar/models/movie.dart';
import 'package:movieradar/theme/cinematic_theme.dart';
import 'package:movieradar/widgets/cinematic_widgets.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movie});

  final Movie movie;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  late Movie _movie;
  late bool _isWatched;

  @override
  void initState() {
    super.initState();
    _movie = widget.movie;
    _isWatched = _movie.isWatched;
  }

  @override
  Widget build(BuildContext context) {
    final colors = CinematicColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Cinematic.bgTop,
      body: Stack(
        children: [
          const Positioned.fill(child: CinematicBackground()),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                stretch: true,
                expandedHeight: 320,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                leading: _DetailIconMorph(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.of(context).pop(),
                ),
                actions: [
                  _DetailIconMorph(
                    icon: Icons.delete_outline,
                    onTap: () => _confirmDelete(context),
                  ),
                  const SizedBox(width: 12),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.blurBackground,
                    StretchMode.zoomBackground,
                  ],
                  background: _Backdrop(movie: _movie),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Transform.translate(
                        offset: const Offset(0, -72),
                        child: Center(
                          child: Hero(
                            tag: 'movie_${_movie.id}',
                            child: MoviePoster(
                              movie: _movie,
                              width: 170,
                              height: 255,
                              borderRadius: 20,
                              glow: true,
                            ),
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -60),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) =>
                                  Cinematic.glowGradient.createShader(bounds),
                              child: Text(
                                _movie.title,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (_movie.releaseYear != null)
                                  NeonChip(
                                    label: _movie.releaseYear.toString(),
                                    icon: Icons.calendar_today,
                                  ),
                                NeonChip(
                                  label: _movie.director ?? 'Unknown director',
                                  icon: Icons.theater_comedy,
                                ),
                                NeonChip(
                                  label: 'Added ${_formatDate(_movie.dateAdded)}',
                                  icon: Icons.add_circle_outline,
                                ),
                                if (_isWatched && _movie.dateWatched != null)
                                  NeonChip(
                                    label:
                                        'Watched ${_formatDate(_movie.dateWatched!)}',
                                    icon: Icons.check_circle,
                                    active: true,
                                  ),
                              ],
                            ),
                            if (_movie.overview != null &&
                                _movie.overview!.isNotEmpty) ...[
                              const SizedBox(height: 26),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: colors.glass,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'SYNOPSIS',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 3,
                                        color: Cinematic.neonViolet,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      _movie.overview!,
                                      style: textTheme.bodyLarge?.copyWith(
                                        height: 1.5,
                                        color: Cinematic.textPrimaryDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 26),
                            // Watched toggle
                            Container(
                              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                              decoration: BoxDecoration(
                                color: colors.glass,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: _isWatched
                                      ? colors.glow.withValues(alpha: 0.4)
                                      : Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              child: SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  _isWatched ? 'WATCHED' : 'MARK AS WATCHED',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                    color: Colors.white,
                                  ),
                                ),
                                subtitle: Text(
                                  _isWatched
                                      ? 'This film is in your history'
                                      : 'Move it to your watched list',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                value: _isWatched,
                                onChanged: (bool value) {
                                  setState(() {
                                    _isWatched = value;
                                    _movie = _movie.copyWith(
                                      isWatched: value,
                                      dateWatched: value
                                          ? DateTime.now()
                                          : null,
                                    );
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 22),
                            SizedBox(
                              width: double.infinity,
                              child: CinematicButton(
                                label: 'SAVE CHANGES',
                                icon: Icons.check,
                                onPressed: () =>
                                    Navigator.pop(context, _movie),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete movie?'),
        content: Text('Remove "${_movie.title}" from your library?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      if (mounted) Navigator.pop(context, 'delete');
    }
  }
}

class _DetailIconMorph extends StatelessWidget {
  const _DetailIconMorph({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.35),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, size: 21),
        ),
      ),
    );
  }
}

/// Blurred cinematic backdrop with a scrim.
class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    final colors = CinematicColors.of(context);
    final hasPoster = movie.posterUrl != null && movie.posterUrl!.isNotEmpty;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasPoster)
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
            child: Image.network(
              movie.posterUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => _BackdropFallback(),
            ),
          )
        else
          const _BackdropFallback(),
        // Scrim
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.35, 0.75, 1],
              colors: [
                Cinematic.bgTop.withValues(alpha: 0.25),
                Cinematic.bgTop.withValues(alpha: 0.8),
                Cinematic.bgTop,
              ],
            ),
          ),
        ),
        // Edge glow
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  colors.glow.withValues(alpha: 0.9),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BackdropFallback extends StatelessWidget {
  const _BackdropFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(gradient: Cinematic.duskGradient),
    );
  }
}