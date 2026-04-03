import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/watchlist_provider.dart';
import '../models/stock.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';
import 'stock_detail_screen.dart';
import 'add_stock_screen.dart';
import 'settings_screen.dart';

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(child: _buildList(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final provider = context.watch<WatchlistProvider>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                _dateLabel(),
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontFamily: 'Courier',
                ),
              ),
            ],
          ),
          const Spacer(),
          if (provider.isRefreshing)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppTheme.accentBlue,
              ),
            )
          else
            GestureDetector(
              onTap: provider.refreshAll,
              child: _iconButton(Icons.refresh_rounded),
            ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            child: _iconButton(Icons.tune_rounded),
          ),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.divider, width: 0.5),
      ),
      child: Icon(icon, color: AppTheme.textMuted, size: 18),
    );
  }

  String _dateLabel() {
    final now = DateTime.now();
    const months = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  Widget _buildList(BuildContext context) {
    final provider = context.watch<WatchlistProvider>();
    final items = provider.items;

    return RefreshIndicator(
      color: AppTheme.accentBlue,
      backgroundColor: AppTheme.bgCard,
      onRefresh: provider.refreshAll,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        children: [
          if (items.isEmpty) _emptyState(context),
          ...items.map((item) => _WatchlistTile(item: item)),
          const SizedBox(height: 12),
          _addButton(context),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const Icon(Icons.show_chart_rounded, color: AppTheme.textMuted, size: 40),
          const SizedBox(height: 12),
          const Text('Your watchlist is empty', style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
          const SizedBox(height: 6),
          const Text('Add stocks to start tracking', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => _goAdd(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.accentBlue.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Add your first stock', style: TextStyle(color: AppTheme.accentBlue, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _goAdd(context),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.divider, width: 0.5, style: BorderStyle.solid),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: AppTheme.textMuted, size: 18),
            SizedBox(width: 8),
            Text('Add stock', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  void _goAdd(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddStockScreen()));
  }
}

// ── Watchlist tile ──────────────────────────────────────────────────────────

class _WatchlistTile extends StatelessWidget {
  final WatchlistItem item;

  const _WatchlistTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final hasPrice = item.currentPrice != null;
    final sparkColor = item.isPositive ? AppTheme.accentGreen : AppTheme.accentRed;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => StockDetailScreen(item: item)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.bgCardBorder, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  item.symbol,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.bgHighlight,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.divider, width: 0.5),
                  ),
                  child: Text(
                    item.exchange,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 9, fontFamily: 'Courier'),
                  ),
                ),
                const Spacer(),
                hasPrice
                    ? Text(
                        _fmtPrice(item.currentPrice!, item.exchange),
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Courier',
                        ),
                      )
                    : const ShimmerBox(width: 72, height: 14),
              ],
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                hasPrice
                    ? ChangeChip(value: item.changePercent, fontSize: 11)
                    : const ShimmerBox(width: 52, height: 10),
              ],
            ),
            // Buy price / P&L row
            if (item.buyPrice != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    'Bought at ${_fmtPrice(item.buyPrice!, item.exchange)}',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                  ),
                  const Spacer(),
                  if (hasPrice)
                    _PnlChip(pct: item.pnlPercent, abs: item.pnlAbsolute, exchange: item.exchange),
                ],
              ),
            ],
            // Sparkline
            const SizedBox(height: 8),
            item.sparklineData.isNotEmpty
                ? SparklineWidget(data: item.sparklineData, color: sparkColor, height: 30)
                : const ShimmerBox(width: double.infinity, height: 30),
          ],
        ),
      ),
    );
  }

  String _fmtPrice(double price, String exchange) {
    final symbol = (exchange == 'NSE' || exchange == 'BSE') ? '₹' : '\$';
    if (price >= 1000) return '$symbol${price.toStringAsFixed(0)}';
    if (price >= 10) return '$symbol${price.toStringAsFixed(2)}';
    return '$symbol${price.toStringAsFixed(3)}';
  }
}

class _PnlChip extends StatelessWidget {
  final double? pct;
  final double? abs;
  final String exchange;

  const _PnlChip({this.pct, this.abs, required this.exchange});

  @override
  Widget build(BuildContext context) {
    if (pct == null) return const SizedBox.shrink();
    final isPos = pct! >= 0;
    final color = isPos ? AppTheme.accentGreen : AppTheme.accentRed;
    final bgColor = isPos ? AppTheme.accentGreen.withValues(alpha: 0.08) : AppTheme.accentRed.withValues(alpha: 0.08);
    final arrow = isPos ? '▲' : '▼';
    final sign = isPos ? '+' : '';
    final curr = (exchange == 'NSE' || exchange == 'BSE') ? '₹' : '\$';
    final absStr = abs != null ? ' · $curr${abs!.abs().toStringAsFixed(0)}' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$arrow $sign${pct!.toStringAsFixed(2)}%$absStr',
        style: TextStyle(color: color, fontSize: 10, fontFamily: 'Courier', fontWeight: FontWeight.w500),
      ),
    );
  }
}
