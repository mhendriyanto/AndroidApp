import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapclean_flutter/main.dart';
import 'package:snapclean_flutter/models/snap_item.dart';
import 'package:snapclean_flutter/state/app_controller.dart';

void main() {
  test('timer badge shows seconds below 10 minutes', () {
    final now = DateTime(2026, 1, 1, 12);
    final item = SnapItem(
      id: 'soon',
      title: 'Soon',
      note: 'Countdown',
      type: MockType.receipt,
      createdAt: now.subtract(const Duration(minutes: 1)),
      expiresAt: now.add(const Duration(minutes: 9, seconds: 5)),
      status: SnapStatus.active,
    );

    expect(item.badge(now), '9m 5s');
  });

  test('expired screenshots are deleted and create a notice', () {
    final controller = AppController.seeded();

    controller.snoozeSnap('order', const Duration(seconds: -1));
    controller.deleteExpiredSnaps();

    expect(controller.activeSnaps.any((item) => item.id == 'order'), isFalse);
    expect(controller.latestNotice?.message, contains('expired'));
    controller.dispose();
  });

  testWidgets('SnapClean app renders', (tester) async {
    await tester.pumpWidget(const SnapCleanApp());
    expect(find.text('SnapClean'), findsWidgets);
  });

  testWidgets('Home profile avatar opens the profile screen', (tester) async {
    await tester.pumpWidget(const SnapCleanApp());

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Open profile'));
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('Home shows search, stats, and recent documents', (tester) async {
    await tester.pumpWidget(const SnapCleanApp());

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Search screenshots'), findsOneWidget);
    expect(find.text('3'), findsWidgets);
    expect(find.text('cleaned'), findsNothing);
    expect(find.text('space saved'), findsNothing);
    expect(find.text('kept'), findsNothing);
    expect(find.text('Recents'), findsOneWidget);
    expect(find.text('Order confirmation'), findsOneWidget);
    expect(find.text('Message thread'), findsOneWidget);
  });

  testWidgets('Timers 30m filter hides screenshots over 30 minutes',
      (tester) async {
    await tester.pumpWidget(const SnapCleanApp());

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Timers'));
    await tester.pumpAndSettle();
    expect(find.text('Order confirmation'), findsOneWidget);
    expect(find.text('Message thread'), findsOneWidget);

    await tester.tap(find.text('30m'));
    await tester.pumpAndSettle();

    expect(find.text('Order confirmation'), findsOneWidget);
    expect(find.text('Message thread'), findsNothing);
  });

  testWidgets('Timers screen combines active and expiring functions',
      (tester) async {
    await tester.pumpWidget(const SnapCleanApp());

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Timers'));
    await tester.pumpAndSettle();

    expect(find.text('Timers'), findsOneWidget);
    expect(find.text('Expiring'), findsNothing);
    expect(find.text('Order confirmation'), findsOneWidget);
    expect(find.text('After cleanup'), findsNothing);
    expect(find.text('All clean'), findsNothing);
  });

  testWidgets('Import plus opens emulator image import screen', (tester) async {
    await tester.pumpWidget(const SnapCleanApp());

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add screenshot'));
    await tester.pumpAndSettle();

    expect(find.text('Add images'), findsOneWidget);
    expect(find.text('Choose from emulator'), findsOneWidget);
  });

  testWidgets('Import includes 10 minute timer and separate forever option',
      (tester) async {
    await tester.pumpWidget(const SnapCleanApp());

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('10 minutes'), findsOneWidget);
    expect(find.text('Save forever'), findsOneWidget);
    expect(find.text('Forever'), findsOneWidget);
  });

  testWidgets('Saved tab shows forever shots', (tester) async {
    await tester.pumpWidget(const SnapCleanApp());

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();

    expect(find.text('Forever shots'), findsOneWidget);
    expect(find.text('Travel QR code'), findsOneWidget);
    expect(find.text('1 saved'), findsOneWidget);
  });

  testWidgets('Import shows guided workflow steps', (tester) async {
    await tester.pumpWidget(const SnapCleanApp());

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Images'), findsOneWidget);
    expect(find.text('Timer'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
  });

  testWidgets('Timer cards open screenshot detail', (tester) async {
    await tester.pumpWidget(const SnapCleanApp());

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Timers'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Order confirmation'));
    await tester.pumpAndSettle();

    expect(find.text('Keep forever'), findsOneWidget);
    expect(find.text('Snooze 1 hour'), findsOneWidget);
  });

  testWidgets('Import can add a custom timer', (tester) async {
    await tester.pumpWidget(const SnapCleanApp());

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Custom'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText).at(0), 'Lunch timer');
    await tester.enterText(find.byType(EditableText).at(1), '45');
    await tester.tap(find.text('Add timer'));
    await tester.pumpAndSettle();

    expect(find.text('Lunch timer'), findsWidgets);
    expect(find.text('45 minutes'), findsOneWidget);
  });

  testWidgets('Import can edit a custom timer', (tester) async {
    await tester.pumpWidget(const SnapCleanApp());

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Custom'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText).at(0), 'Lunch timer');
    await tester.enterText(find.byType(EditableText).at(1), '45');
    await tester.tap(find.text('Add timer'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lunch timer').last);
    await tester.pumpAndSettle();

    expect(find.text('Edit timer'), findsOneWidget);
    await tester.enterText(find.byType(EditableText).at(0), 'Tea timer');
    await tester.enterText(find.byType(EditableText).at(1), '15');
    await tester.tap(find.text('Save timer'));
    await tester.pumpAndSettle();

    expect(find.text('Tea timer'), findsWidgets);
    expect(find.text('15 minutes'), findsOneWidget);
  });

  testWidgets('custom import timers appear in Timers tabs', (tester) async {
    await tester.pumpWidget(const SnapCleanApp());

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Custom'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText).at(0), 'Lunch timer');
    await tester.enterText(find.byType(EditableText).at(1), '45');
    await tester.tap(find.text('Add timer'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Timers'));
    await tester.pumpAndSettle();
    expect(find.text('Lunch timer'), findsOneWidget);
  });
}
