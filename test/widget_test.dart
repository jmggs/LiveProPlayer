import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:live_pro_player/main.dart';
import 'package:live_pro_player/providers/player_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => PlayerProvider(),
        child: const LiveProPlayerApp(),
      ),
    );
    expect(find.byType(LiveProPlayerApp), findsOneWidget);
  });
}
