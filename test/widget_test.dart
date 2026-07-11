import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbi_gathering/app/app.dart';

void main() {
  testWidgets('navigates from home to game', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: OrbiGatheringApp()));

    expect(find.text('Start a game'), findsOneWidget);

    await tester.tap(find.text('Start a game'));
    await tester.pumpAndSettle();

    expect(find.text('Game'), findsOneWidget);
  });
}
