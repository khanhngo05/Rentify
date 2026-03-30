import 'package:flutter_test/flutter_test.dart';
import 'package:rentify/main.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const RentifyApp());
    expect(find.text('Rentify\nCho thuê trang phục trực tuyến'), findsOneWidget);
  });
}
