import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/stock.dart';
import '../services/yahoo_service.dart';
import '../services/finnhub_service.dart';
import '../utils/theme.dart';

class WatchlistProvider extends ChangeNotifier {
  final YahooFinanceService _yahoo = YahooFinanceService();
  late FinnhubService _finnhub;

  List<WatchlistItem> _items = [];
  bool _isRefreshing = false;
  String _finnhubToken = '';

  List<WatchlistItem> get items => _items;
  bool get isRefreshing => _isRefreshing;
  String get finnhubToken => _finnhubToken;
  FinnhubService get finnhub => _finnhub;
  YahooFinanceService get yahoo => _yahoo;

  WatchlistProvider() {
    _finnhub = FinnhubService('');
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _finnhubToken = prefs.getString(AppConstants.keyFinnhubToken) ?? '';
    _finnhub = FinnhubService(_finnhubToken);

    final raw = prefs.getStringList(AppConstants.keyWatchlist) ?? [];
    _items = raw.map((s) => WatchlistItem.fromJson(jsonDecode(s))).toList();
    notifyListeners();
    if (_items.isNotEmpty) refreshAll();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      AppConstants.keyWatchlist,
      _items.map((i) => jsonEncode(i.toJson())).toList(),
    );
  }

  Future<void> addStock(WatchlistItem item) async {
    if (_items.any((i) => i.symbol == item.symbol && i.exchange == item.exchange)) return;
    _items.add(item);
    await _persist();
    notifyListeners();
    _refreshSingle(item);
  }

  Future<void> removeStock(String symbol, String exchange) async {
    _items.removeWhere((i) => i.symbol == symbol && i.exchange == exchange);
    await _persist();
    notifyListeners();
  }

  Future<void> updateBuyPrice(String symbol, String exchange, double? price) async {
    final idx = _items.indexWhere((i) => i.symbol == symbol && i.exchange == exchange);
    if (idx == -1) return;
    _items[idx] = _items[idx].copyWith(buyPrice: price);
    await _persist();
    notifyListeners();
  }

  Future<void> refreshAll() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    notifyListeners();
    await Future.wait(_items.map((item) => _refreshSingle(item)));
    _isRefreshing = false;
    notifyListeners();
  }

  Future<void> _refreshSingle(WatchlistItem item) async {
    final quote = await _yahoo.fetchQuoteWithFallback(item.yahooSymbol);
    final sparkline = await _yahoo.fetchSparkline(item.yahooSymbol);
    final idx = _items.indexWhere((i) => i.symbol == item.symbol && i.exchange == item.exchange);
    if (idx == -1) return;
    if (quote != null) {
      _items[idx] = _items[idx].copyWith(
        currentPrice: quote.price,
        changePercent: quote.changePercent,
        change: quote.change,
        volume: quote.volume,
        sparklineData: sparkline,
      );
    }
    notifyListeners();
  }

  Future<void> saveFinnhubToken(String token) async {
    _finnhubToken = token;
    _finnhub = FinnhubService(token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyFinnhubToken, token);
    notifyListeners();
  }

  void reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = _items.removeAt(oldIndex);
    _items.insert(newIndex, item);
    _persist();
    notifyListeners();
  }
}
