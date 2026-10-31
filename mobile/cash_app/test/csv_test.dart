import 'package:cash_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

TxItem tx({String description = 'Plain description', int type = 2}) => TxItem(
      id: '1',
      description: description,
      amount: 12.5,
      type: type,
      categoryName: 'Comida',
      accountName: 'Banco',
      memberName: 'Alex Demo',
      date: DateTime(2026, 10, 30),
    );

String row(TxItem item) => generateTransactionsCsv([item]).split('\n')[1];

void main() {
  group('C1: fields with special characters are quoted', () {
    test('comma', () {
      expect(row(tx(description: 'Lunch, office')),
          contains(',"Lunch, office",'));
    });

    test('double quote', () {
      expect(row(tx(description: 'The "big" shop')),
          contains(',"The ""big"" shop",'));
    });

    test('line break', () {
      expect(generateTransactionsCsv([tx(description: 'First\nSecond')]),
          contains(',"First\nSecond",'));
      expect(generateTransactionsCsv([tx(description: 'First\rSecond')]),
          contains(',"First\rSecond",'));
    });
  });

  test('C2: fields without special characters are unchanged', () {
    expect(row(tx()),
        '2026-10-30,GASTO,Comida,Plain description,Banco,Alex Demo,12.50');
  });

  test('C3: transfers are labelled TRANSFERENCIA', () {
    expect(row(tx(type: 3)), contains(',TRANSFERENCIA,'));
  });
}
