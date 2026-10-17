import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_app/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter.format', () {
    test('普通金额保留两位小数并带千分位', () {
      expect(CurrencyFormatter.format(1234.5), '¥1,234.50');
    });

    test('整数金额补零', () {
      expect(CurrencyFormatter.format(100), '¥100.00');
    });

    test('零金额', () {
      expect(CurrencyFormatter.format(0), '¥0.00');
    });
  });

  group('CurrencyFormatter.formatCompact', () {
    test('万元以下不压缩', () {
      expect(CurrencyFormatter.formatCompact(9999.99), '¥9,999.99');
    });

    test('万元以上使用紧凑格式', () {
      final result = CurrencyFormatter.formatCompact(12345.67);
      expect(result.contains('万'), isTrue);
    });
  });

  group('CurrencyFormatter.formatWithoutSymbol', () {
    test('无货币符号，保留千分位与两位小数', () {
      expect(CurrencyFormatter.formatWithoutSymbol(1234.5), '1,234.50');
    });
  });
}
