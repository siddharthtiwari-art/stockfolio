import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/watchlist_provider.dart';
import '../models/stock.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';

class StockDetailScreen extends StatefulWidget {
  final WatchlistItem item;

  const StockDetailScreen({super.key, required this.item});

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  int _periodIndex = 2; // default: 1M
  StockQuote? _quote;
  List<ChartDataPoint> _chartData = [];
  List<ChartDataPoint> _compareData1 = [];
  List<ChartDataPoint> _compareData2 = [];
  List<NewsItem> _news = [];
  bool _loadingChart = true;
  bool _loadingQuote = true;

  String? _compareSymbol1;
  String? _compareSymbol2;

  NewsItem? _activeNews;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadQuote(), _loadChart()]);
    _loadNews();
  }

  Future<void> _loadQuote() async {
    setState(() => _loadingQuote = true);
    final provider = context.read<WatchlistProvider>();
    final q = await provider.yahoo.fetchQuoteWithFallback(widget.item.yahooSymbol);
    setState(() {
      _quote = q;
      _loadingQuote = false;
    });
  }

  Future<void> _loadChart() async {
    setState(() => _loadingChart = true);
    final period = AppConstants.chartPeriods[_periodIndex];
    final provider = context.read<WatchlistProvider>();
    final data = await provider.yahoo.fetchChart(
      widget.item.yahooSymbol,
      range: period['range']!,
      interval: period['interval']!,
    );
    setState(() {
      _chartData = data;
      _loadingChart = false;
    });

    // Reload compare overlays for new period
    if (_compareSymbol1 != null) _loadCompare1(_compareSymbol1!);
    if (_compareSymbol2 != null) _loadCompare2(_compareSymbol2!);
  }

  Future<void> _loadNews() async {
    final provider = context.read<WatchlistProvider>();
    if (!provider.finnhub.hasToken) return;
    final period = AppConstants.chartPeriods[_periodIndex];
    final now = DateTime.now();
    DateTime from;
    switch (period['range']) {
      case '1d': from = now.subtract(const Duration(days: 1)); break;
      case '5d': from = now.subtract(const Duration(days: 7)); break;
      case '1mo': from = now.subtract(const Duration(days: 32)); break;
      case '3mo': from = now.subtract(const Duration(days: 95)); break;
      case '1y': from = now.subtract(const Duration(days: 370)); break;
      default: from = now.subtract(const Duration(days: 1825)); break;
    }
    final news = await provider.finnhub.fetchNews(
      widget.item.symbol,
      from: from,
      to: now,
    );
    setState(() => _news = news);
  }

  Future<void> _loadCompare1(String symbol) async {
    final period = AppConstants.chartPeriods[_periodIndex];
    final provider = context.read<WatchlistProvider>();
    final data = await provider.yahoo.fetchChart(symbol, range: period['range']!, interval: period['interval']!);
    setState(() => _compareData1 = data);
  }

  Future<void> _loadCompare2(String symbol) async {
    final period = AppConstants.chartPeriods[_periodIndex];
    final provider = context.read<WatchlistProvider>();
    final data = await provider.yahoo.fetchChart(symbol, range: period['range']!, interval: period['interval']!);
    setState(() => _compareData2 = data);
  }

  void _showAddCompare(int slot) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Compare with ${slot == 1 ? 'stock 1' : 'stock 2'}',
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'Courier'),
              decoration: const InputDecoration(
                hintText: 'Symbol (e.g. TCS.NS, MSFT)',
                hintStyle: TextStyle(color: AppTheme.textMuted),
                filled: true,
                fillColor: AppTheme.bgHighlight,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      if (slot == 1) setState(() { _compareSymbol1 = null; _compareData1 = []; });
                      if (slot == 2) setState(() { _compareSymbol2 = null; _compareData2 = []; });
                      Navigator.pop(context);
                    },
                    child: const Text('Remove', style: TextStyle(color: AppTheme.accentRed)),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue.withValues(alpha: 0.15), foregroundColor: AppTheme.accentBlue, elevation: 0),
                    onPressed: () {
                      final sym = ctrl.text.trim().toUpperCase();
                      if (sym.isNotEmpty) {
                        if (slot == 1) { setState(() => _compareSymbol1 = sym); _loadCompare1(sym); }
                        if (slot == 2) { setState(() => _compareSymbol2 = sym); _loadCompare2(sym); }
                      }
                      Navigator.pop(context);
                    },
                    child: const Text('Add'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final quote = _quote;
    final currency = (item.exchange == 'NSE' || item.exchange == 'BSE') ? '₹' : '\$';

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: Stack(
        children: [
          SafeArea(
            child: ListView(
              children: [
                // Back bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.textMuted),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _showEditBuyPrice(context, item, currency),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.bgCard,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.divider, width: 0.5),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.edit_outlined, size: 12, color: AppTheme.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                item.buyPrice != null
                                    ? 'Bought at $currency${item.buyPrice!.toStringAsFixed(item.buyPrice! >= 100 ? 0 : 2)}'
                                    : 'Set buy price',
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(item.symbol,
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppTheme.bgHighlight, borderRadius: BorderRadius.circular(4)),
                            child: Text(item.exchange, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontFamily: 'Courier')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      if (_loadingQuote)
                        const ShimmerBox(width: 140, height: 30)
                      else if (quote != null) ...[
                        Text(
                          '$currency${_fmtPrice(quote.price)}',
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 28, fontWeight: FontWeight.w700, fontFamily: 'Courier', letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 3),
                        Row(children: [
                          ChangeChip(value: quote.changePercent, fontSize: 12),
                          const SizedBox(width: 8),
                          Text('today', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                        ]),
                      ],
                      const SizedBox(height: 2),
                      Text(item.name, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                    ],
                  ),
                ),

                // Period selector
                const SizedBox(height: 14),
                _PeriodSelector(
                  selected: _periodIndex,
                  onSelect: (i) {
                    setState(() => _periodIndex = i);
                    _loadChart();
                    _loadNews();
                  },
                ),

                // Compare row
                const SizedBox(height: 8),
                _CompareRow(
                  symbol1: _compareSymbol1,
                  symbol2: _compareSymbol2,
                  onAdd1: () => _showAddCompare(1),
                  onAdd2: () => _showAddCompare(2),
                ),

                // Chart
                const SizedBox(height: 8),
                _ChartArea(
                  loading: _loadingChart,
                  mainData: _chartData,
                  compareData1: _compareData1,
                  compareData2: _compareData2,
                  news: _news,
                  onNewsTap: (n) => setState(() => _activeNews = n),
                ),

                // Metrics
                const SizedBox(height: 12),
                if (quote != null)
                  _MetricsGrid(quote: quote, currency: currency),

                // Position card
                if (item.buyPrice != null && quote != null) ...[
                  const SizedBox(height: 12),
                  _PositionCard(item: item, quote: quote, currency: currency),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),

          // News popup overlay
          if (_activeNews != null)
            _NewsOverlay(
              news: _activeNews!,
              onDismiss: () => setState(() => _activeNews = null),
            ),
        ],
      ),
    );
  }

  String _fmtPrice(double price) {
    if (price >= 1000) return price.toStringAsFixed(0);
    if (price >= 10) return price.toStringAsFixed(2);
    return price.toStringAsFixed(3);
  }

  void _showEditBuyPrice(BuildContext context, WatchlistItem item, String currency) {
    final ctrl = TextEditingController(text: item.buyPrice?.toString() ?? '');
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edit buy price', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'Courier'),
              decoration: InputDecoration(
                prefixText: currency,
                prefixStyle: const TextStyle(color: AppTheme.textSecondary),
                hintText: '0.00',
                hintStyle: const TextStyle(color: AppTheme.textMuted),
                filled: true, fillColor: AppTheme.bgHighlight,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue.withValues(alpha: 0.15), foregroundColor: AppTheme.accentBlue, elevation: 0),
                onPressed: () {
                  final v = double.tryParse(ctrl.text.trim());
                  context.read<WatchlistProvider>().updateBuyPrice(item.symbol, item.exchange, v);
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Period selector ─────────────────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;

  const _PeriodSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: AppConstants.chartPeriods.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final p = AppConstants.chartPeriods[i];
          final isSelected = i == selected;
          return GestureDetector(
            onTap: () => onSelect(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.accentBlue.withValues(alpha: 0.12) : AppTheme.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppTheme.accentBlue.withValues(alpha: 0.5) : AppTheme.divider,
                  width: 0.5,
                ),
              ),
              child: Text(
                p['label']!,
                style: TextStyle(
                  color: isSelected ? AppTheme.accentBlue : AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Compare row ─────────────────────────────────────────────────────────────

class _CompareRow extends StatelessWidget {
  final String? symbol1;
  final String? symbol2;
  final VoidCallback onAdd1;
  final VoidCallback onAdd2;

  const _CompareRow({this.symbol1, this.symbol2, required this.onAdd1, required this.onAdd2});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text('vs', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          const SizedBox(width: 8),
          _chip(symbol1, AppConstants.compareColors[0], onAdd1),
          const SizedBox(width: 6),
          _chip(symbol2, AppConstants.compareColors[1], onAdd2),
        ],
      ),
    );
  }

  Widget _chip(String? symbol, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: symbol != null ? color.withValues(alpha: 0.4) : AppTheme.divider, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (symbol != null) ...[
              Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(symbol, style: TextStyle(color: color, fontSize: 11, fontFamily: 'Courier')),
            ] else ...[
              Icon(Icons.add, color: AppTheme.textMuted, size: 12),
              const SizedBox(width: 4),
              const Text('Add', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Chart area ──────────────────────────────────────────────────────────────

class _ChartArea extends StatelessWidget {
  final bool loading;
  final List<ChartDataPoint> mainData;
  final List<ChartDataPoint> compareData1;
  final List<ChartDataPoint> compareData2;
  final List<NewsItem> news;
  final ValueChanged<NewsItem> onNewsTap;

  const _ChartArea({
    required this.loading,
    required this.mainData,
    required this.compareData1,
    required this.compareData2,
    required this.news,
    required this.onNewsTap,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: AppTheme.accentBlue, strokeWidth: 1.5),
        ),
      );
    }
    if (mainData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text('No chart data available', style: TextStyle(color: AppTheme.textMuted)),
        ),
      );
    }

    final mainSpots = _normalize(mainData);
    final cmp1Spots = compareData1.isNotEmpty ? _normalize(compareData1) : <FlSpot>[];
    final cmp2Spots = compareData2.isNotEmpty ? _normalize(compareData2) : <FlSpot>[];

    // Map news to chart x positions
    final newsMarkers = _mapNewsToX(news, mainData);

    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(color: AppTheme.bgCardBorder, strokeWidth: 0.5),
                ),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  // Main line
                  LineChartBarData(
                    spots: mainSpots,
                    isCurved: true,
                    color: AppTheme.accentGreen,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [AppTheme.accentGreen.withValues(alpha: 0.12), Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  if (cmp1Spots.isNotEmpty)
                    LineChartBarData(
                      spots: cmp1Spots,
                      isCurved: true,
                      color: AppConstants.compareColors[0],
                      barWidth: 1.3,
                      dotData: const FlDotData(show: false),
                      dashArray: [4, 2],
                    ),
                  if (cmp2Spots.isNotEmpty)
                    LineChartBarData(
                      spots: cmp2Spots,
                      isCurved: true,
                      color: AppConstants.compareColors[1],
                      barWidth: 1.3,
                      dotData: const FlDotData(show: false),
                      dashArray: [4, 2],
                    ),
                ],
              ),
            ),
          ),
          // News marker overlays
          ...newsMarkers.map((m) => _NewsMarkerWidget(
                label: m.$1.markerLabel ?? '?',
                xFraction: m.$2,
                onTap: () => onNewsTap(m.$1),
              )),
        ],
      ),
    );
  }

  List<FlSpot> _normalize(List<ChartDataPoint> data) {
    if (data.isEmpty) return [];
    final base = data.first.close;
    return data.asMap().entries.map((e) {
      final pct = base == 0 ? 0.0 : ((e.value.close - base) / base) * 100;
      return FlSpot(e.key.toDouble(), pct);
    }).toList();
  }

  List<(NewsItem, double)> _mapNewsToX(List<NewsItem> news, List<ChartDataPoint> data) {
    if (news.isEmpty || data.isEmpty) return [];
    final first = data.first.timestamp.millisecondsSinceEpoch.toDouble();
    final last = data.last.timestamp.millisecondsSinceEpoch.toDouble();
    final range = last - first;
    if (range == 0) return [];
    return news.map((n) {
      final t = n.datetime.millisecondsSinceEpoch.toDouble();
      final frac = ((t - first) / range).clamp(0.05, 0.95);
      return (n, frac);
    }).toList();
  }
}

class _NewsMarkerWidget extends StatelessWidget {
  final String label;
  final double xFraction;
  final VoidCallback onTap;

  const _NewsMarkerWidget({required this.label, required this.xFraction, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: xFraction * (MediaQuery.of(context).size.width - 52),
      top: 8,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.accentPurpleLight,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: AppTheme.accentPurple, width: 0.8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(color: AppTheme.accentBlue, fontSize: 9, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

// ── Metrics grid ────────────────────────────────────────────────────────────

class _MetricsGrid extends StatelessWidget {
  final StockQuote quote;
  final String currency;

  const _MetricsGrid({required this.quote, required this.currency});

  @override
  Widget build(BuildContext context) {
    final pe = quote.peRatio != null ? '${quote.peRatio!.toStringAsFixed(1)}x' : 'N/A';
    final mcap = _fmtMcap(quote.marketCap, currency);
    final divYield = quote.dividendYield != null ? '${(quote.dividendYield! * 100).toStringAsFixed(2)}%' : 'N/A';
    final eps = quote.eps != null ? '$currency${quote.eps!.toStringAsFixed(2)}' : 'N/A';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(children: [
            Expanded(child: MetricCard(label: 'P/E Ratio', value: pe, subtext: 'Trailing 12M')),
            const SizedBox(width: 8),
            Expanded(child: MetricCard(label: 'Mkt Cap', value: mcap)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: MetricCard(
                label: '52W Range',
                value: quote.fiftyTwoWeekHigh != null ? '${_fmt(quote.fiftyTwoWeekLow!)}–${_fmt(quote.fiftyTwoWeekHigh!)}' : 'N/A',
                suffix: quote.fiftyTwoWeekHigh != null
                    ? RangeBar(low: quote.fiftyTwoWeekLow!, high: quote.fiftyTwoWeekHigh!, current: quote.price)
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: MetricCard(label: 'Div Yield', value: divYield, subtext: quote.eps != null ? 'EPS $eps' : null)),
          ]),
        ],
      ),
    );
  }

  String _fmt(double v) => v >= 1000 ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  String _fmtMcap(double? mc, String curr) {
    if (mc == null) return 'N/A';
    if (mc >= 1e12) return '$curr${(mc / 1e12).toStringAsFixed(1)}T';
    if (mc >= 1e9) return '$curr${(mc / 1e9).toStringAsFixed(1)}B';
    if (mc >= 1e6) return '$curr${(mc / 1e6).toStringAsFixed(0)}M';
    return '$curr${mc.toStringAsFixed(0)}';
  }
}

// ── Position card ───────────────────────────────────────────────────────────

class _PositionCard extends StatelessWidget {
  final WatchlistItem item;
  final StockQuote quote;
  final String currency;

  const _PositionCard({required this.item, required this.quote, required this.currency});

  @override
  Widget build(BuildContext context) {
    final pct = item.pnlPercent ?? 0;
    final abs = item.pnlAbsolute ?? 0;
    final isPos = pct >= 0;
    final color = isPos ? AppTheme.accentGreen : AppTheme.accentRed;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.bgCardBorder, width: 0.5),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MY POSITION', style: TextStyle(color: AppTheme.textMuted, fontSize: 9, letterSpacing: 0.6)),
                const SizedBox(height: 4),
                Text('Bought at $currency${item.buyPrice!.toStringAsFixed(item.buyPrice! >= 100 ? 0 : 2)}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$currency${quote.price >= 1000 ? quote.price.toStringAsFixed(0) : quote.price.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontFamily: 'Courier', fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${isPos ? "▲" : "▼"} ${isPos ? "+" : ""}${pct.toStringAsFixed(2)}% · ${abs >= 0 ? "+" : ""}$currency${abs.abs().toStringAsFixed(0)}',
                  style: TextStyle(color: color, fontSize: 11, fontFamily: 'Courier'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── News overlay popup ──────────────────────────────────────────────────────

class _NewsOverlay extends StatelessWidget {
  final NewsItem news;
  final VoidCallback onDismiss;

  const _NewsOverlay({required this.news, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        child: SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {}, // don't dismiss when tapping the card
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.divider, width: 0.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            color: AppTheme.accentPurpleLight,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.accentPurple, width: 0.8),
                          ),
                          alignment: Alignment.center,
                          child: Text(news.markerLabel ?? '?',
                              style: const TextStyle(color: AppTheme.accentBlue, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _fmtDate(news.datetime),
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontFamily: 'Courier'),
                        ),
                        const Spacer(),
                        Text(news.source, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onDismiss,
                          child: const Icon(Icons.close, color: AppTheme.textMuted, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      news.headline,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500, height: 1.5),
                    ),
                    if (news.summary.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        news.summary.length > 200 ? '${news.summary.substring(0, 200)}...' : news.summary,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.6),
                      ),
                    ],
                    if (news.sentiment != null) ...[
                      const SizedBox(height: 10),
                      Row(children: [
                        const Text('Sentiment', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                        const SizedBox(width: 8),
                        _SentimentPill(sentiment: news.sentiment!),
                      ]),
                    ],
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _openUrl(news.url),
                      child: Row(children: [
                        const Icon(Icons.open_in_new_rounded, size: 12, color: AppTheme.accentBlue),
                        const SizedBox(width: 4),
                        const Text('Read full article', style: TextStyle(color: AppTheme.accentBlue, fontSize: 12)),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  void _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _SentimentPill extends StatelessWidget {
  final String sentiment;

  const _SentimentPill({required this.sentiment});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    switch (sentiment.toLowerCase()) {
      case 'positive':
        bg = AppTheme.accentGreen.withValues(alpha: 0.1); fg = AppTheme.accentGreen; break;
      case 'negative':
        bg = AppTheme.accentRed.withValues(alpha: 0.1); fg = AppTheme.accentRed; break;
      default:
        bg = AppTheme.bgHighlight; fg = AppTheme.textMuted;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(
        sentiment[0].toUpperCase() + sentiment.substring(1),
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w500),
      ),
    );
  }
}
