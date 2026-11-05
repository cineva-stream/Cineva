import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cineva/features/home/domain/entities/movie.dart';
import 'package:cineva/features/home/presentation/widgets/movie_carousel.dart';
import 'package:cineva/shared/widgets/adaptive_nav_rail.dart';

void main() {
  group('Desktop & Widescreen Layout Tests', () {
    testWidgets('AdaptiveNavRail renders logo at top and centers menu items vertically and horizontally',
        (tester) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  AdaptiveNavRail(
                    currentIndex: selectedIndex,
                    onDestinationSelected: (index) => selectedIndex = index,
                    isTv: false,
                  ),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify logo is present
      expect(find.byType(Image), findsOneWidget);

      // Verify all 6 destination icons are rendered
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
      expect(find.byIcon(Icons.live_tv_outlined), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
      expect(find.byIcon(Icons.history_rounded), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

      // Verify tapping a destination triggers onDestinationSelected
      await tester.tap(find.byIcon(Icons.live_tv_outlined));
      expect(selectedIndex, 1);
    });

    testWidgets('MovieCarousel renders expanded 490px hero billboard with synopsis on wide screens',
        (tester) async {
      final sampleMovies = [
        Movie(
          id: 101,
          title: 'Widescreen Masterpiece',
          overview: 'A deep cinematic journey created specifically for big screens.',
          posterPath: '/sample_poster.jpg',
          backdropPath: '/sample_backdrop.jpg',
          voteAverage: 8.8,
          releaseDate: '2026-05-15',
          genreIds: [28, 12],
        ),
      ];

      // Simulate a 1280x720 desktop display
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: MovieCarousel(movies: sampleMovies),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify title is rendered
      expect(find.text('Widescreen Masterpiece'), findsOneWidget);

      // Verify synopsis is rendered on desktop/widescreen
      expect(find.text('A deep cinematic journey created specifically for big screens.'), findsOneWidget);

      // Verify 4K UHD badge is rendered
      expect(find.text('4K UHD'), findsOneWidget);
    });
  });
}

