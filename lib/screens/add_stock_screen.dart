import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/watchlist_provider.dart';
import '../services/yahoo_service.dart';
import '../models/stock.dart';
import '../utils/theme.dart';

class AddStockScreen extends StatefulWidget {
  const AddStockScreen({super.key});

  @override
  State<AddStockScreen> createState() => _AddStockScreenState();
}

class _AddStockScreenState extends State<AddStockScreen> {
  final _searchCtrl = TextEditingController();
  final _buyCtrl = TextEditingController();
  List<Map<String, String>> _results = [];
  Map<String, String>? _selected;
  bool _searching = false;
  String _exchange = 'NSE';

  final _yahoo = YahooFinanceService();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _buyCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    final results = await _yahoo.searchSymbols(q.trim());
    setState(() {
      _results = results;
      _searching = false;
    });
  }

  String _inferExchange(String symbol, String exchange) {
    if (symbol.endsWith('.NS')) return 'NSE';
    if (symbol.endsWith('.BO')) return 'BSE';
    final ex = exchange.toUpperCase();
    if (ex.contains('NSE') || ex.contains('NMS')) return 'NSE';
    if (ex.contains('BSE') || ex.contains('BOM')) return 'BSE';
    if (ex.contains('NAS') || ex.contains('NASDAQ')) return 'NASDAQ';
    if (ex.contains('NYSE') || ex.contains('NYQ')) return 'NYSE';
    return exchange.isEmpty ? 'NASDAQ' : exchange;
  }

  String _cleanSymbol(String symbol) {
    return symbol.replaceAll('.NS', '').replaceAll('.BO', '');
  }

  void _selectResult(Map<String, String> result) {
    setState(() {
      _selected = result;
      _exchange = _inferExchange(result['symbol']!, result['exchange']!);
      _searchCtrl.text = '${_cleanSymbol(result['symbol']!)} — ${result['name']}';
      _results = [];
    });
  }

  Future<void> _addToWatchlist() async {
    if (_selected == null) return;
    final provider = context.read<WatchlistProvider>();
    final rawSymbol = _selected!['symbol']!;
    final cleanSym = _cleanSymbol(rawSymbol);
    final buyPriceStr = _buyCtrl.text.trim();
    final buyPrice = buyPriceStr.isEmpty ? null : double.tryParse(buyPriceStr);

    final item = WatchlistItem(
      symbol: cleanSym,
      name: _selected!['name']!,
      exchange: _exchange,
      buyPrice: buyPrice,
    );
    await provider.addStock(item);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('Add Stock'),
        backgroundColor: AppTheme.bgPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
          color: AppTheme.textMuted,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search field
            _label('Search symbol or company name'),
            const SizedBox(height: 6),
            TextField(
              controller: _searchCtrl,
              autofocus: true,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'e.g. RELIANCE, AAPL, Infosys...',
                hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                filled: true,
                fillColor: AppTheme.bgCard,
                prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted, size: 18),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.accentBlue)),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.bgCardBorder, width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.bgCardBorder, width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.accentBlue, width: 1),
                ),
              ),
              onChanged: (v) => _search(v),
            ),
            const SizedBox(height: 8),

            // Search results
            if (_results.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.bgCardBorder, width: 0.5),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => Divider(height: 0.5, color: AppTheme.divider),
                  itemBuilder: (_, i) {
                    final r = _results[i];
                    final sym = _cleanSymbol(r['symbol']!);
                    final ex = _inferExchange(r['symbol']!, r['exchange']!);
                    return InkWell(
                      onTap: () => _selectResult(r),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Text(
                              sym,
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Courier'),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppTheme.bgHighlight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(ex, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9, fontFamily: 'Courier')),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                r['name'] ?? '',
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            if (_selected != null) ...[
              const SizedBox(height: 20),
              _label('Buy price (optional)'),
              const SizedBox(height: 6),
              Row(
                children: [
                  // Currency prefix
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                      border: Border.all(color: AppTheme.bgCardBorder, width: 0.5),
                    ),
                    child: Text(
                      (_exchange == 'NSE' || _exchange == 'BSE') ? '₹' : '\$',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontFamily: 'Courier'),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _buyCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontFamily: 'Courier'),
                      decoration: InputDecoration(
                        hintText: 'Enter your purchase price',
                        hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        filled: true,
                        fillColor: AppTheme.bgCard,
                        border: OutlineInputBorder(
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                          borderSide: const BorderSide(color: AppTheme.bgCardBorder, width: 0.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                          borderSide: const BorderSide(color: AppTheme.bgCardBorder, width: 0.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                          borderSide: const BorderSide(color: AppTheme.accentBlue, width: 1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Used to show your P&L on the watchlist and trend view.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
            ],

            const Spacer(),
            if (_selected != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addToWatchlist,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentBlue.withValues(alpha: 0.15),
                    foregroundColor: AppTheme.accentBlue,
                    side: const BorderSide(color: AppTheme.accentBlue, width: 0.8),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Add ${_cleanSymbol(_selected!['symbol']!)} to watchlist',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, letterSpacing: 0.3),
  );
}
