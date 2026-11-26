import 'package:flutter_test/flutter_test.dart';
import 'package:prac2/main.dart';

void main() {
  testWidgets('Sudoku screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(const SudokuApp());
    expect(find.text('Sudoku - Normal'), findsOneWidget);
  });
}