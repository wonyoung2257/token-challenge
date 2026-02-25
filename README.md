# TokenChallenge

A macOS menu bar app that tracks your daily Claude Code token usage and helps you hit a daily goal.

## Features

- **Menu bar widget** — Live token count with a progress ring icon
- **Daily goal tracking** — Set a target (5M, 10M, 20M, 50M, or custom) and watch your progress
- **Streak counter** — Track consecutive days of hitting your goal
- **Trends & charts** — Daily bar chart, hourly usage pattern, and model distribution (donut chart)
- **Per-model breakdown** — See usage split across Opus, Sonnet, Haiku, etc.
- **Localization** — English and Korean (한국어) supported
- **Lightweight** — Pure Swift, no external dependencies, runs as a menu bar accessory

## Install

### Homebrew (recommended)

```bash
brew tap wonyoung2257/token-challenge
brew install --cask token-challenge
```

Since the app is not code-signed, macOS will block it on first launch. To allow it:

1. Open **System Settings → Privacy & Security**
2. Scroll down and click **"Open Anyway"**

Or run:

```bash
xattr -d com.apple.quarantine /Applications/TokenChallenge.app
```

### Build from source

```bash
git clone https://github.com/wonyoung2257/token-challenge.git
cd token-challenge
swift build -c release
./install.sh
```

## How It Works

TokenChallenge reads Claude Code's JSONL session logs from `~/.claude/projects/` to calculate token usage. It polls for changes periodically and aggregates input, output, cache creation, and cache read tokens per model per day.

## Requirements

- macOS 14 (Sonoma) or later

## License

MIT
