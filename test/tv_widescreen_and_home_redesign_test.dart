import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cineva/core/platform/device_form_factor.dart';
import 'package:cineva/features/home/presentation/widgets/airing_calendar_banner.dart';
import 'package:cineva/features/home/presentation/widgets/movie_carousel.dart';
import 'package:cineva/features/home/domain/entities/movie.dart';

void main() {
  group('isWideScreenLayout & 720p TV Detection Tests', () {
    testWidgets('Returns true on 720p TV dimensions in landscape (853x480)', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.5; // 853.33 x 480 logical
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final isWide = isWideScreenLayout(context);
              final formFactor = resolveFormFactor(context, isTv: false);
              return Text('isWide: $isWide, formFactor: ${formFactor.name}');
            },
          ),
        ),
      );

      expect(find.text('isWide: true, formFactor: tv'), findsOneWidget);
    });

    testWidgets('Returns true on 720p TV with 2.0x scale (640x360)', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 2.0; // 640 x 360 logical
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final isWide = isWideScreenLayout(context);
              final formFactor = resolveFormFactor(context, isTv: false);
              return Text('isWide: $isWide, formFactor: ${formFactor.name}');
            },
          ),
        ),
      );

      expect(find.text('isWide: true, formFactor: tv'), findsOneWidget);
    });

    testWidgets('Returns true whenever isTv is explicitly true', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final isWide = isWideScreenLayout(context, isTv: true);
              final formFactor = resolveFormFactor(context, isTv: true);
              return Text('isWide: $isWide, formFactor: ${formFactor.name}');
            },
          ),
        ),
      );

      expect(find.text('isWide: true, formFactor: tv'), findsOneWidget);
    });

    testWidgets('Returns false on standard smartphone in portrait (390x844)', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final isWide = isWideScreenLayout(context, isTv: false);
              final formFactor = resolveFormFactor(context, isTv: false);
              return Text('isWide: $isWide, formFactor: ${formFactor.name}');
            },
          ),
        ),
      );

      expect(find.text('isWide: false, formFactor: mobile'), findsOneWidget);
    });
  });

  group('AiringCalendarBanner Presentation Tests', () {
    testWidgets('Renders classic horizontal banner when isCompanion is false', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AiringCalendarBanner(isCompanion: false),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(AiringCalendarBanner), findsOneWidget);
      expect(find.text('2 TAB'), findsOneWidget);
      expect(find.text('Buka'), findsOneWidget);
    });

    testWidgets('Renders vertical companion card with CTA button when isCompanion is true', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 320,
                height: 490,
                child: AiringCalendarBanner(isCompanion: true),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('LIVE RADAR'), findsOneWidget);
      expect(find.text('2 TAB'), findsOneWidget);
      expect(find.text('Buka Jadwal Lengkap'), findsOneWidget);
    });
  });

  group('Hero Carousel + Airing Calendar Side-by-Side Widescreen Layout Tests', () {
    testWidgets('Renders side-by-side in Row on 720p widescreen display', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.5; // 853 x 480
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const dummyMovie = Movie(
        id: 1,
        title: 'Cineva Premiere Movie',
        overview: 'Epic cinematic journey',
        voteAverage: 8.9,
        releaseDate: '2026-11-06',
        backdropPath: '/dummy.jpg',
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 68,
                      child: MovieCarousel(movies: [dummyMovie]),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      flex: 32,
                      child: AiringCalendarBanner(isCompanion: true),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(MovieCarousel), findsOneWidget);
      expect(find.byType(AiringCalendarBanner), findsOneWidget);
      expect(find.text('Cineva Premiere Movie'), findsOneWidget);
      expect(find.text('LIVE RADAR'), findsOneWidget);
      expect(find.text('Buka Jadwal Lengkap'), findsOneWidget);
    });
  });
}
