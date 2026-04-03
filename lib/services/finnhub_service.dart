import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/stock.dart';
import '../utils/theme.dart';

class FinnhubService {
  final String apiToken;
  static const Duration _timeout = Duration(seconds: 10);
  static const List<String> _markerLabels = ['A', 'B', 'C', 'D', 'E'];

  FinnhubService(this.apiToken);

  bool get hasToken => apiToken.isNotEmpty;

  // Fetch company news for a symbol within a date range
  Future<List<NewsItem>> fetchNews(
    String symbol, {
    required DateTime from,
    required DateTime to,
  }) async {
    if (!hasToken) return [];
    try {
      final fromStr = '${from.year}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}';
      final toStr = '${to.year}-${to.month.toString().padLeft(2, '0')}-${to.day.toString().padLeft(2, '0')}';

      // Strip exchange suffix for Finnhub (.NS, .BO)
      final cleanSymbol = symbol.split('.').first;

      final uri = Uri.parse(
        '${AppConstants.finnhubBase}/company-news?symbol=$cleanSymbol&from=$fromStr&to=$toStr&token=$apiToken',
      );
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as List;
      final items = data
          .take(20)
          .map((j) => NewsItem.fromFinnhub(j as Map<String, dynamic>))
          .where((n) => n.headline.isNotEmpty)
          .toList();

      // Assign A, B, C... labels to the first few — spaced out across the time window
      final labeled = _selectRepresentativeNews(items, from, to);
      return labeled;
    } catch (_) {
      return [];
    }
  }

  // Pick up to 5 evenly-spaced news items and assign A, B, C...
  List<NewsItem> _selectRepresentativeNews(
    List<NewsItem> items,
    DateTime from,
    DateTime to,
  ) {
    if (items.isEmpty) return [];
    items.sort((a, b) => a.datetime.compareTo(b.datetime));
    if (items.length <= _markerLabels.length) {
      for (int i = 0; i < items.length; i++) {
        items[i].markerLabel = _markerLabels[i];
      }
      return items;
    }
    // Pick evenly spaced
    final step = items.length ~/ _markerLabels.length;
    final selected = <NewsItem>[];
    for (int i = 0; i < _markerLabels.length; i++) {
      final item = items[i * step];
      item.markerLabel = _markerLabels[i];
      selected.add(item);
    }
    return selected;
  }

  // Fetch general market news (for a news feed tab later)
  Future<List<NewsItem>> fetchMarketNews({String category = 'general'}) async {
    if (!hasToken) return [];
    try {
      final uri = Uri.parse(
        '${AppConstants.finnhubBase}/news?category=$category&token=$apiToken',
      );
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as List;
      return data
          .take(30)
          .map((j) => NewsItem.fromFinnhub(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
