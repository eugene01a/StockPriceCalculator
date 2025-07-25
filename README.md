# Stock Price Calculator (iOS, SwiftUI)

A simple SwiftUI app that lets you:

- View the current stock price for any symbol
- Calculate percent increases or decreases interactively
- View 5–30 day historical min/max prices
- Toggle between **day** or **week**-based date ranges
- Uses the Yahoo Finance API (via RapidAPI)

---

## Features

- Live stock price from Yahoo Finance
- Displays price as of exact timestamp
- Computes min/max close prices for custom date range
- Slider for interactive % change simulation
- Automatic error handling for invalid symbols
- API key securely stored using `.plist` (not hardcoded)

---

## Setup Instructions

### 1. Clone the Repo

```bash
git clone https://github.com/your-username/stock-price-calculator.git
cd stock-price-calculator
```

### 2. Open in Xcode

- Requires **Xcode 14.3+**
- Supports **iOS 15+** and **SwiftUI**

Open the `.xcodeproj` or `.xcworkspace` file and let Xcode resolve the packages.

---

## Secure API Key Setup

### 3. Create `Secrets.plist` (DO NOT commit this file)

**Path**: In your project root, add a new file: `Secrets.plist`

Contents:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>RapidAPIKey</key>
  <string>YOUR_RAPIDAPI_KEY_HERE</string>
</dict>
</plist>
```

You can get a free API key from [RapidAPI – Yahoo Finance](https://rapidapi.com/apidojo/api/yh-finance/).

## Run the App

- Plug in your device or choose a simulator.
- Hit **Cmd + R** to build and run.

---

## Notes

- Free RapidAPI plan gives 500 requests/month.
- If you exceed this quota or enter an invalid stock symbol, the app will gracefully handle the error.
- The app uses only closing prices (not real-time tick data).

---

## License

MIT — free to use, modify, and share.

