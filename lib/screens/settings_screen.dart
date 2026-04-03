import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/watchlist_provider.dart';
import '../utils/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _tokenCtrl;

  @override
  void initState() {
    super.initState();
    final token = context.read<WatchlistProvider>().finnhubToken;
    _tokenCtrl = TextEditingController(text: token);
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
          color: AppTheme.textMuted,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionLabel('Data Sources'),
          const SizedBox(height: 8),
          _card(children: [
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.show_chart_rounded, color: AppTheme.accentGreen, size: 20),
              title: Text('Yahoo Finance', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
              subtitle: Text('Prices, quotes, charts · No key needed', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              trailing: _ActiveBadge(),
            ),
            Divider(height: 0.5, color: AppTheme.divider),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.newspaper_rounded, color: AppTheme.accentBlue, size: 20),
              const SizedBox(width: 12),
              const Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Finnhub', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                  Text('News & sentiment markers', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                ],
              )),
            ]),
            const SizedBox(height: 10),
            TextField(
              controller: _tokenCtrl,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontFamily: 'Courier'),
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Paste your Finnhub API token',
                hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                filled: true,
                fillColor: AppTheme.bgHighlight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.bgCardBorder, width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.bgCardBorder, width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.accentBlue, width: 1),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Free tier at finnhub.io — sign up to get a token.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentBlue.withValues(alpha: 0.12),
                  foregroundColor: AppTheme.accentBlue,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  await context.read<WatchlistProvider>().saveFinnhubToken(_tokenCtrl.text.trim());
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Finnhub token saved'),
                        backgroundColor: AppTheme.bgCard,
                      ),
                    );
                  }
                },
                child: const Text('Save token'),
              ),
            ),
          ]),

          const SizedBox(height: 24),
          _sectionLabel('About'),
          const SizedBox(height: 8),
          _card(children: [
            const _InfoRow(label: 'App', value: 'Stockfolio'),
            Divider(height: 16, color: AppTheme.divider),
            const _InfoRow(label: 'Version', value: '1.0.0'),
            Divider(height: 16, color: AppTheme.divider),
            const _InfoRow(label: 'Data', value: 'Yahoo Finance · Finnhub'),
            Divider(height: 16, color: AppTheme.divider),
            const _InfoRow(label: 'Storage', value: 'Local only · No backend'),
          ]),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text.toUpperCase(),
    style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, letterSpacing: 0.8),
  );

  Widget _card({required List<Widget> children}) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.bgCard,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.bgCardBorder, width: 0.5),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.accentGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text('Active', style: TextStyle(color: AppTheme.accentGreen, fontSize: 10)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        Text(value, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontFamily: 'Courier')),
      ],
    );
  }
}
