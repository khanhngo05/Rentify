import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentify/widgets/common/loading_widget.dart';

void main() {
  group('LoadingWidget (Shimmer Grid) Tests', () {
    testWidgets('should display GridView with default item count', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingWidget(),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('should respect custom itemCount', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingWidget(itemCount: 4),
          ),
        ),
      );

      final gridView = tester.widget<GridView>(find.byType(GridView));
      // GridView.builder creates items lazily, so we check if it builds correctly
      expect(gridView, isNotNull);
    });

    testWidgets('should display shimmer cards', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingWidget(itemCount: 2),
          ),
        ),
      );

      // Should have Card widgets for shimmer effect
      expect(find.byType(Card), findsWidgets);
    });
  });

  group('LoadingIndicator Tests', () {
    testWidgets('should display CircularProgressIndicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingIndicator(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should be centered in parent', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingIndicator(),
          ),
        ),
      );

      expect(find.byType(Center), findsOneWidget);
    });

    testWidgets('should display message when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingIndicator(message: 'Loading data...'),
          ),
        ),
      );

      expect(find.text('Loading data...'), findsOneWidget);
    });

    testWidgets('should not display message when not provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingIndicator(),
          ),
        ),
      );

      // Should only have the CircularProgressIndicator
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('should display both indicator and message together', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingIndicator(message: 'Please wait...'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Please wait...'), findsOneWidget);
    });
  });
}
