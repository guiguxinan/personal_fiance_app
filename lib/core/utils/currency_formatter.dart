import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'zh_CN',
    symbol: '¥',
    decimalDigits: 2,
  );

  static final NumberFormat _compactFormat = NumberFormat.compactCurrency(
    locale: 'zh_CN',
    symbol: '¥',
    decimalDigits: 2,
  );

  static String format(double amount) {
    return _currencyFormat.format(amount);
  }

  static String formatCompact(double amount) {
    if (amount >= 10000) {
      return _compactFormat.format(amount);
    }
    return _currencyFormat.format(amount);
  }

  static String formatWithoutSymbol(double amount) {
    return NumberFormat('#,##0.00', 'zh_CN').format(amount);
  }
}
