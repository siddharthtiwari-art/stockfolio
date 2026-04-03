import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/stock.dart';
import '../utils/theme.dart';

class YahooFinanceService {
  static const Duration _timeout = Duration(seconds: 15);

  static const Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    'Accept': 'application/json, text/plain, */*',
    'Accept-Language': 'en-US,en;q=0.9',
    'Origin': 'https://finance.yahoo.com',
    'Referer': 'https://finance.yahoo.com/',
  };

  Future<StockQuote?> fetchQuote(String yahooSymbol) async {
    try {
      final uri = Uri.parse(
        '${AppConstants.yahooQuoteBase}?symbols=$yahooSymbol&fields=shortName,regularMarketPrice,regularMarketChange,regularMarketChangePercent,regularMarketVolume,marketCap,trailingPE,fiftyTwoWeekHigh,fiftyTwoWeekLow,trailingAnnualDividendYield,epsTrailingTwelveMonths,currency',
      );
      final response = await http.get(uri, headers: _headers).timeout(_timeout);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final result = data['quoteResponse']?['result'];
      if (result == null || result.isEmpty) return null;

      final q = result[0] as Map<String, dynamic>;
      return StockQuote(
        symbol: yahooSymbol,
        name: q['shortName'] ?? yahooSymbol,
        price: (q['regularMarketPrice'] as num?)?.toDouble() ?? 0,
        change: (q['regularMarketChange'] as num?)?.toDouble() ?? 0,
        changePercent: (q['regularMarketChangePercent'] as num?)?.toDouble() ?? 0,
        volume: (q['regularMarketVolume'] as num?)?.toDouble() ?? 0,
        marketCap: (q['marketCap'] as num?)?.toDouble(),
        peRatio: (q['trailingPE'] as num?)?.toDouble(),
        fiftyTwoWeekHigh: (q['fiftyTwoWeekHigh'] as num?)?.toDouble(),
        fiftyTwoWeekLow: (q['fiftyTwoWeekLow'] as num?)?.toDouble(),
        dividendYield: (q['trailingAnnualDividendYield'] as num?)?.toDouble(),
        eps: (q['epsTrailingTwelveMonths'] as num?)?.toDouble(),
        currency: q['currency'] ?? 'USD',
      );
    } catch (_) {
      return null;
    }
  }

  // Fallback: extract price from chart endpoint which is more permissive
  Future<StockQuote?> fetchQuoteWithFallback(String yahooSymbol) async {
    final quote = await fetchQuote(yahooSymbol);
    if (quote != null && quote.price > 0) return quote;

    try {
      final points = await fetchChart(yahooSymbol, range: '1d', interval: '1m');
      if (points.isEmpty) return null;
      final latest = points.last;
      final first = points.first;
      final change = latest.close - first.close;
      final changePct = first.close > 0 ? (change / first.close) * 100 : 0.0;
      return StockQuote(
        symbol: yahooSymbol,
        name: yahooSymbol,
        price: latest.close,
        change: change,
        changePercent: changePct,
        volume: latest.volume ?? 0,
        currency: yahooSymbol.endsWith('.NS') || yahooSymbol.endsWith('.BO') ? 'INR' : 'USD',
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<ChartDataPoint>> fetchChart(
    String yahooSymbol, {
    required String range,
    required String interval,
  }) async {
    try {
      final uri = Uri.parse(
        '${AppConstants.yahooBase}/$yahooSymbol?range=$range&interval=$interval&includePrePost=false',
      );
      final response = await http.get(uri, headers: _headers).timeout(_timeout);
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      final chart = data['chart']?['result'];
      if (chart == null || chart.isEmpty) return [];

      final result = chart[0] as Map<String, dynamic>;
      final timestamps = (result['timestamp'] as List?)?.cast<int>() ?? [];
      final quote = result['indicators']?['quote']?[0] as Map<String, dynamic>?;
      if (quote == null) return [];

      final closes = (quote['close'] as List?)?.cast<num?>() ?? [];
      final volumes = (quote['volume'] as List?)?.cast<num?>() ?? [];
      final opens = (quote['open'] as List?)?.cast<num?>() ?? [];
      final highs = (quote['high'] as List?)?.cast<num?>() ?? [];
      final lows = (quote['low'] as List?)?.cast<num?>() ?? [];

      final points = <ChartDataPoint>[];
      for (int i = 0; i < timestamps.length; i++) {
        final close = i < closes.length ? closes[i]?.toDouble() : null;
        if (close == null) continue;
        points.add(ChartDataPoint(
          timestamp: DateTime.fromMillisecondsSinceEpoch(timestamps[i] * 1000),
          close: close,
          volume: i < volumes.length ? volumes[i]?.toDouble() : null,
          open: i < opens.length ? opens[i]?.toDouble() : null,
          high: i < highs.length ? highs[i]?.toDouble() : null,
          low: i < lows.length ? lows[i]?.toDouble() : null,
        ));
      }
      return points;
    } catch (_) {
      return [];
    }
  }

  Future<List<double>> fetchSparkline(String yahooSymbol) async {
    final points = await fetchChart(yahooSymbol, range: '5d', interval: '1d');
    return points.map((p) => p.close).toList();
  }

  Future<List<Map<String, String>>> searchSymbols(String query) async {
    try {
      final uri = Uri.parse(
        'https://query1.finance.yahoo.com/v1/finance/search?q=${Uri.encodeComponent(query)}&quotesCount=8&newsCount=0',
      );
      final response = await http.get(uri, headers: _headers).timeout(_timeout);
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body);
      final quotes = data['quotes'] as List? ?? [];
      return quotes
          .where((q) => q['quoteType'] == 'EQUITY')
          .map<Map<String, String>>((q) => {
                'symbol': q['symbol'] ?? '',
                'name': q['shortname'] ?? q['longname'] ?? '',
                'exchange': q['exchange'] ?? '',
              })
          .where((q) => q['symbol']!.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }
}
