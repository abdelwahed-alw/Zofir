# Zofir

Zofir is an offline-first Flutter app for splitting shared expenses among roommates (2–6 people). Add who paid for what, see live balances, get a simplified “who owes whom” plan, and settle debts with receiver-PIN confirmation.

Built with Flutter + Material 3, Provider state management, and Hive local persistence. Bilingual English / Arabic with full RTL support.

## Features

- **Roommate setup (2–6 people)**
  - Unique names + 4-digit PIN per person
  - PIN is used later as receiver confirmation for settlements
- **Expenses**
  - Description, amount in MAD, payer, flexible participant list
  - History sorted newest-first, swipe-to-delete
- **Balances**
  - Net balance per user: `+` = is owed money, `-` = owes money
  - Total spent card
- **Debt simplification**
  - Greedy creditor/debtor matching to minimize number of payments
  - “All settled” state when balances are within 0.01 MAD
- **Settle Up with PIN verification**
  - To mark `A → B` as paid, B’s PIN must be entered
  - Settlements are stored separately and offset balances
  - Visible in history as settlement entries
- **Persistence**
  - Hive box `expense_box`: users, expenses, settlements, theme, locale
  - Survives restarts, fully offline, no backend
- **Theming & i18n**
  - Light / dark Material 3 (teal seed color), persisted
  - English / Arabic toggle, forced RTL layout in Arabic, persisted
  - Reset keeps theme + locale
- **Custom branding**
  - Vector-style logo painted in code (`ZofirLogo`) + SVG/PNG assets in `assets/icon/`, launcher icons via `flutter_launcher_icons`

## Screenshots

> Add screenshots here, e.g.:
>
> `docs/screenshots/setup.png`, `home.png`, `add-expense.png`, `settle.png`

## Tech Stack

- Flutter 3.38 / Dart 3.10, Material 3
- `provider` ^6.1.2 – app state (`AppState`)
- `hive` + `hive_flutter` – local storage
- `intl` – date formatting (`dd MMM, HH:mm`)
- `uuid` – IDs for users, expenses, settlements
- `cupertino_icons`, `flutter_lints`, `flutter_launcher_icons`

## Project Structure

```text
lib/
  main.dart                # Hive init, Provider wiring, MaterialApp + theme/locale/RTL
  app_state.dart           # AppState: users, expenses, settlements, balances, debts, theme, locale, persistence
  models.dart              # AppUser, Expense, Settlement, Debt
  l10n/strings.dart        # EN/AR dictionary, accessed via AppState.tr()
  screens/
    setup_screen.dart      # 2–6 users, name + PIN validation
    home_screen.dart       # total, balances, debts, history, settle dialog, reset
    add_expense_screen.dart# expense form: description, amount, payer, participants
  widgets/
    app_bar_actions.dart   # theme toggle + EN/AR toggle
    zofir_logo.dart        # CustomPaint logo (teal squircle + Z + ÷ coin)

assets/icon/
  zofir_logo.svg, app_icon.png, logo_512.png, logo_192.png, logo_180.png
```

## How It Works

### Balances (`AppState.getBalances()`)

For each expense `e` with amount `A` paid by `P` split among `N` participants:

- `balance[P] += A`
- each participant `p`: `balance[p] -= A / N`

For each settlement `s` from `F` to `T` of amount `A`:

- `balance[F] += A`
- `balance[T] -= A`

### Simplified debts (`AppState.getSimplifiedDebts()`)

1. Split balances into creditors (`> 0.01`) sorted descending, debtors (`< -0.01`) sorted ascending.
2. Greedily match largest debtor to largest creditor, emitting `Debt(fromId, toId, amount)` until all edges < 0.01.

### Settlement flow

1. User taps **Settle Up** on a `from → to` debt.
2. Dialog asks for receiver (`to`) PIN.
3. `verifyReceiverPin()` compares input to stored PIN (legacy empty PIN = no verification).
4. On success `settleDebt()` appends a `Settlement`, persists, updates UI.

## Getting Started

### Prerequisites

- Flutter stable (tested with 3.38.7)
- Android Studio / VS Code + emulator or physical device
- Chrome for web (optional)

### Install & run

```bash
flutter pub get
flutter run
```

Run on a specific device:

```bash
flutter devices
flutter run -d <device_id>
flutter run -d chrome
```

### Analyze, test, build

```bash
flutter analyze
flutter test
flutter build apk --release
flutter build appbundle --release
flutter build web --release
```

### Launcher icons

Icons are configured in `pubspec.yaml` (`flutter_launcher_icons`):

```bash
dart run flutter_launcher_icons
```

Source: `assets/icon/app_icon.png`, adaptive background `#0F766E`.

## Data Model

```dart
AppUser { id, name, pin }                    // pin: 4-digit string
Expense { id, description, amount, paidById, participantIds, date }
Settlement { id, fromId, toId, amount, date }
Debt { fromId, toId, amount }                // derived, not persisted
```

Hive keys in `expense_box`: `users`, `expenses`, `settlements`, `themeMode` (`light`/`dark`), `locale` (`en`/`ar`).

Reset (`resetAll()`) clears users/expenses/settlements but keeps theme + locale.

## Localization

All strings live in `lib/l10n/strings.dart`, no codegen:

```dart
state.tr('settleExplain', params: {'name': receiverName})
```

`main.dart` forces `TextDirection.rtl` when `localeCode == 'ar'`.

To add a language: add a map entry in `AppStrings.values`, allow the code in `setLocale()` / `init()`.

## Limitations / Notes

- PINs are stored in plaintext in Hive — fine for a local demo, not for production auth.
- Equal-split only (no shares / percentages yet).
- Currency is hardcoded to MAD.
- No cloud sync, no multi-device support.

Possible next steps: uneven splits, expense categories, export CSV, edit expense, biometric instead of PIN.

## Contributing

1. Fork / branch: `git checkout -b feat/my-change`
2. `flutter pub get && flutter analyze && flutter test`
3. Open a PR with a short description and screenshots for UI changes.

## License

No license file yet. Add one (e.g. MIT) if you plan to publish or accept contributions.
