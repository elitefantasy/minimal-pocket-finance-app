# Minimal Pocket Finance

A clean, privacy-focused, offline-first personal finance manager built with **Flutter** following modern architecture and Material 3 design principles.

Minimal Pocket Finance helps you track daily income and expenses while keeping all your financial data completely offline on your device. No cloud sync, no accounts, no subscriptions, no ads—just a fast, lightweight, and powerful pocket finance tracker.

---

## ✨ Features

### 📊 Dashboard & Overview
* **Financial Summary Cards**: View current net balance, total income, total expense, and current month expense at a glance.
* **Top Expense Categories**: Quick visual breakdown of your highest spending categories for the current period.
* **Recent Transactions**: Instant feed of latest transactions with quick actions and history navigation.
* **Year Selector**: Switch active context year for financial calculations across the application.

### 💳 Transaction Management
* **Income & Expense Tracking**: Quickly log earnings and expenditures with amount, date, category, and notes.
* **Edit & Update**: Modify details of existing transactions effortlessly.
* **Trash Bin & Soft Delete**: Deleted transactions are moved to a 30-day Trash Bin for safe recovery before permanent deletion.
* **Restore & Permanent Removal**: Restore trashed items back to active history or clear the Trash Bin completely.
* **Undo Delete**: Instant snackbar action to quickly restore accidental deletions.
* **Smart Date Selection**: Remembers your last selected transaction date across consecutive entries.
* **Visual Recurring Badges**: Clear visual indicators distinguishing recurring items from manual one-time entries.

### 🔍 Search, Filter & Sort History
* **Real-time Search**: Search transactions instantaneously by category name or notes content.
* **Type Filter**: Narrow down transaction list by All, Income, or Expense.
* **Category Filter**: Filter history by specific custom categories.
* **Date & Range Filter**: Filter records by month, year, or custom filter chips.
* **Recurring Filter**: Filter between recurring scheduled transactions and one-time entries.
* **Multi-Criterion Sorting**: Sort history by Newest First, Oldest First, Highest Amount, Lowest Amount, or Category (A–Z).

### 🏷️ Category Management
* **Custom Categories**: Create tailored categories for both Income and Expense types.
* **Category Renaming**: Update category labels across your entire transaction history.
* **Delete Protection**: Prevents deletion of categories currently assigned to active transactions to maintain data integrity.
* **Usage Statistics**: View total number of transactions linked to each category.

### 🔄 Recurring Transactions Engine
* **Automated Monthly Entries**: Schedule recurring monthly income (e.g. salary) and expenses (e.g. rent, bills, subscriptions).
* **Scheduled Date Execution**: Automatically generates transaction entries on their designated processing date.
* **Active Status Toggle**: Easily enable or pause recurring rules without losing configurations.
* **Relational Origin Tracking**: Maintains relational links between recurring rules and generated transactions.

### 📈 Statistics & Analytics
* **Comprehensive Metrics**: Track total income, expense, net balance, and overall transaction volume.
* **Highs & Highlights**: Identify highest single income entry and highest expense payment.
* **Category Spend Distribution**: View exact category totals alongside percentage breakdown of monthly spending.
* **Monthly Average Spending**: Calculate average monthly expense rates per category to spot long-term spending patterns.

### 💾 Data Management & Multi-Database System
* **Multi-Database Support**: Create, manage, rename, and switch between separate isolated SQLite databases (e.g., Personal, Business, Household).
* **Database Backup & Import**: Backup full SQLite database files or import existing databases into the app safely.
* **CSV Export**: Export transaction records to standard CSV format for use in Excel, Google Sheets, or external analysis tool.
* **Local Storage & Privacy**: 100% offline database using local SQLite with zero telemetry or network tracking.

### 📱 UI & Experience
* **Material 3 Design**: Clean design with custom color palettes, responsive layouts, and cohesive typography.
* **Centralized Feedback**: Interactive notifications and snackbars for user actions.
* **About & App Information**: Displays application version, database schema version (v4), platform info, release notes, and repository links.

---

## 🛠️ Tech Stack

* **Framework**: Flutter (Dart)
* **State Management**: Riverpod (`flutter_riverpod`)
* **Navigation**: GoRouter (`go_router`)
* **Database**: SQLite (`sqflite`, `sqflite_common_ffi` for Desktop)
* **UI Architecture**: Material 3 Design System
* **Platform Storage**: `path_provider` & Storage Access Framework (Android)
* **App Info**: `package_info_plus`

---

## 📁 Project Structure

```text
lib/
├── app/                  # Application configuration & theme bindings
├── core/                 # Core utilities, constants, database, theme & snackbar services
│   ├── constants/
│   ├── database/
│   ├── notifications/
│   └── theme/
├── features/             # Feature modules (Clean Architecture)
│   ├── about/            # App & database metadata screen
│   ├── categories/       # Category management
│   ├── dashboard/        # Dashboard overview & summary cards
│   ├── data_management/  # Multi-database management, backup, CSV export & import
│   ├── recurring/        # Monthly recurring engine & schedule management
│   ├── statistics/       # Financial metrics, totals & monthly averages
│   └── transactions/     # Transaction entry, history, search/filter & trash bin
├── models/               # Domain data models (Transaction, Category, RecurringTransaction, etc.)
├── repositories/         # SQLite data access repositories
├── routes/               # GoRouter route configurations
├── services/             # Export/Import file services
├── shared/               # Shared reusable UI widgets & layout scaffolds
└── main.dart             # Application entry point
```

---

## 🏛️ Architecture

The app follows a feature-based Clean Architecture:

```text
UI (Widgets / Screens)
        ↓
Riverpod State Notifiers
        ↓
Data Repositories
        ↓
SQLite Database (sqflite / sqflite_common_ffi)
```

* **Decoupled Business Logic**: Riverpod handles UI state, isolating data logic from widgets.
* **Repository Pattern**: Abstracted data layer facilitates database queries and multi-database switching.
* **Offline First**: All storage operations run locally against SQLite.

---

## 🗄️ Database

* **Engine**: SQLite
* **Schema Version**: **1**
* **Multi-Database Support**: Enables creation and switching between multiple database files on device.
* **Foreign Keys & Migrations**: Foreign keys enforced with automatic versioned database migration scripts.

---

## 💻 Supported Platforms

| Platform | Status |
| --- | --- |
| **Android** | ✅ Supported |
| **Windows** | ✅ Supported |
| **Linux / macOS** | 🔄 Compatible |
| **Web** | 📌 Planned |

---

## 🚀 Building & Running

### Prerequisites
* Flutter SDK (3.x or higher)
* Android SDK (for Android build) or Visual Studio Build Tools (for Windows Desktop)

### Debug Mode
```bash
flutter run
```

### Build Android APK
```bash
flutter build apk --release
```

### Build Windows App
```bash
flutter build windows --release
```

---

## 🔒 Privacy & Philosophy

Minimal Pocket Finance is built on three core pillars:

1. **Your Data Belongs to You**: All records stay locally on your device.
2. **100% Offline Capability**: Fully functional without any internet connection.
3. **Speed, Simplicity & Control**: Zero ads, zero trackers, zero forced cloud accounts or monthly subscriptions.

---

## 🤝 Contributing

Contributions, bug reports, and feature requests are always welcome!
Feel free to open an issue or submit a pull request on GitHub.

* **GitHub Repository**: https://github.com/elitefantasy/minimal-pocket-finance-app

---

## 📄 License

Distributed under the **MIT License**. See `LICENSE` for details.

---

## 👨‍💻 Author

**Anil Maurya**
* GitHub: [@elitefantasy](https://github.com/elitefantasy)
