import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:retail_manager/main.dart';
import 'package:retail_manager/providers/retail_store.dart';

void main() {
  testWidgets('ShopXApp builds shell', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => RetailStore(),
        child: const ShopXApp(),
      ),
    );

    expect(find.text('MayleSoft retail'), findsWidgets);
  });
}
