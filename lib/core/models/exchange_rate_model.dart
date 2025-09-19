class ExchangeRate {
  final String fromCurrency;
  final String toCurrency;
  final double rate;
  final DateTime lastUpdated;
  final double changePercent;

  const ExchangeRate({
    required this.fromCurrency,
    required this.toCurrency,
    required this.rate,
    required this.lastUpdated,
    required this.changePercent,
  });

  String get pair => '$fromCurrency/$toCurrency';
  bool get isPositive => changePercent >= 0;
}