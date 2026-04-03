class WatchlistItem {
  final String symbol;
  final String name;
  final String exchange; // NSE, BSE, NASDAQ, NYSE
  double? buyPrice;
  double? currentPrice;
  double? changePercent;
  double? change;
  double? volume;
  List<double> sparklineData;
  DateTime lastUpdated;

  WatchlistItem({
    required this.symbol,
    required this.name,
    required this.exchange,
    this.buyPrice,
    this.currentPrice,
    this.changePercent,
    this.change,
    this.volume,
    this.sparklineData = const [],
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  // Yahoo Finance appends .NS for NSE, .BO for BSE
  String get yahooSymbol {
    if (exchange == 'NSE') return '$symbol.NS';
    if (exchange == 'BSE') return '$symbol.BO';
    return symbol;
  }

  double? get pnlPercent {
    if (buyPrice == null || currentPrice == null || buyPrice == 0) return null;
    return ((currentPrice! - buyPrice!) / buyPrice!) * 100;
  }

  double? get pnlAbsolute {
    if (buyPrice == null || currentPrice == null) return null;
    return currentPrice! - buyPrice!;
  }

  bool get isPositive => (changePercent ?? 0) >= 0;
  bool get isPnlPositive => (pnlPercent ?? 0) >= 0;

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'name': name,
        'exchange': exchange,
        'buyPrice': buyPrice,
      };

  factory WatchlistItem.fromJson(Map<String, dynamic> json) => WatchlistItem(
        symbol: json['symbol'],
        name: json['name'],
        exchange: json['exchange'],
        buyPrice: (json['buyPrice'] as num?)?.toDouble(),
      );

  WatchlistItem copyWith({
    double? currentPrice,
    double? changePercent,
    double? change,
    double? volume,
    List<double>? sparklineData,
    double? buyPrice,
  }) =>
      WatchlistItem(
        symbol: symbol,
        name: name,
        exchange: exchange,
        buyPrice: buyPrice ?? this.buyPrice,
        currentPrice: currentPrice ?? this.currentPrice,
        changePercent: changePercent ?? this.changePercent,
        change: change ?? this.change,
        volume: volume ?? this.volume,
        sparklineData: sparklineData ?? this.sparklineData,
        lastUpdated: DateTime.now(),
      );
}

class StockQuote {
  final String symbol;
  final String name;
  final double price;
  final double change;
  final double changePercent;
  final double volume;
  final double? marketCap;
  final double? peRatio;
  final double? fiftyTwoWeekHigh;
  final double? fiftyTwoWeekLow;
  final double? dividendYield;
  final double? eps;
  final String currency;

  const StockQuote({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.volume,
    this.marketCap,
    this.peRatio,
    this.fiftyTwoWeekHigh,
    this.fiftyTwoWeekLow,
    this.dividendYield,
    this.eps,
    this.currency = 'USD',
  });

  bool get isPositive => changePercent >= 0;
}

class ChartDataPoint {
  final DateTime timestamp;
  final double close;
  final double? volume;
  final double? open;
  final double? high;
  final double? low;

  const ChartDataPoint({
    required this.timestamp,
    required this.close,
    this.volume,
    this.open,
    this.high,
    this.low,
  });
}

class NewsItem {
  final String id;
  final String headline;
  final String summary;
  final String source;
  final String url;
  final DateTime datetime;
  final String? sentiment; // positive, negative, neutral
  final String? ticker;
  String? markerLabel; // A, B, C assigned at display time

  NewsItem({
    required this.id,
    required this.headline,
    required this.summary,
    required this.source,
    required this.url,
    required this.datetime,
    this.sentiment,
    this.ticker,
    this.markerLabel,
  });

  factory NewsItem.fromFinnhub(Map<String, dynamic> json) => NewsItem(
        id: json['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        headline: json['headline'] ?? '',
        summary: json['summary'] ?? '',
        source: json['source'] ?? '',
        url: json['url'] ?? '',
        datetime: DateTime.fromMillisecondsSinceEpoch((json['datetime'] as int) * 1000),
        sentiment: json['sentiment'],
        ticker: json['related'],
      );
}


