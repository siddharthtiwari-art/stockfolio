# Stockfolio

A personal stock tracker for Android — watchlist, price & volume trends, compare overlays, news markers, and P&L tracking. No backend, pure Flutter frontend.

## Features

- **Watchlist** — track NSE, BSE, NASDAQ, NYSE stocks with live prices
- **Trend view** — price chart with 1D / 1W / 1M / 3M / 1Y / 5Y periods and volume bars
- **Compare** — overlay up to 2 other stocks on the same chart (normalised %)
- **News markers** — A / B / C pins on the chart, tap to read the headline + sentiment
- **P&L tracking** — set your buy price per stock, see % and absolute gain/loss
- **Metrics** — P/E ratio, market cap, 52-week range, dividend yield

## Data Sources

| Source | Used for | Key needed? |
|---|---|---|
| Yahoo Finance | Prices, quotes, charts, search | ❌ No |
| Finnhub | Company news + sentiment | ✅ Free tier at finnhub.io |

## Getting Started

### Prerequisites

- Flutter 3.32+ (`flutter --version`)
- Java 17
- Android SDK with `compileSdk 36`

### Run locally

```bash
git clone https://github.com/YOUR_USERNAME/stockfolio.git
cd stockfolio
flutter pub get
flutter run
```

### Configure Finnhub (for news markers)

1. Sign up at https://finnhub.io — free tier is enough
2. Copy your API token
3. Open the app → Settings (⚙ top right) → paste token → Save

## Build with Codemagic

1. Push this repo to GitHub
2. Log in to https://codemagic.io and connect your repo
3. Codemagic will auto-detect `codemagic.yaml`
4. Trigger a build — the debug APK is the fastest to iterate with
5. Download the APK from the build artifacts and install on your device

### Release signing (optional for now)

When you're ready for signed builds, add these environment variables to a Codemagic variable group named `keystore_credentials`:

- `CM_KEYSTORE` — base64-encoded `.jks` keystore (`base64 -i keystore.jks | pbcopy`)
- `CM_KEY_ALIAS` — key alias
- `CM_KEY_PASSWORD` — key password
- `CM_STORE_PASSWORD` — store password

## Project Structure

```
lib/
  main.dart                  — app entry, theme, provider setup
  utils/
    theme.dart               — AppTheme colors + AppConstants
  models/
    stock.dart               — WatchlistItem, StockQuote, ChartDataPoint, NewsItem
  services/
    yahoo_service.dart       — Yahoo Finance HTTP calls
    finnhub_service.dart     — Finnhub news + sentiment
    watchlist_provider.dart  — ChangeNotifier state, persistence
  screens/
    watchlist_screen.dart    — Home screen, list of stocks
    stock_detail_screen.dart — Chart, metrics, news markers, P&L
    add_stock_screen.dart    — Search and add a stock
    settings_screen.dart     — API token config
  widgets/
    common_widgets.dart      — SparklineWidget, ChangeChip, MetricCard, RangeBar, ShimmerBox
```

## Iteration Roadmap

- [ ] Volume chart below price line
- [ ] Portfolio summary card (total invested, total current, overall P&L)
- [ ] Alerts / price notifications
- [ ] Dark/light theme toggle
- [ ] Export watchlist as CSV
- [ ] iPad / tablet layout
