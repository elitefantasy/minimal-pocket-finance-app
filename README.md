# Minimal Pocket Finance

A clean, offline-first personal finance manager built with **Flutter** following modern architecture and Material 3 design principles.

Minimal Pocket Finance helps you manage your daily income and expenses while keeping your financial data completely offline on your device. No account, no cloud sync, no advertisements—just a fast and lightweight finance tracker.

---

## ✨ Features

### Dashboard

* Current balance
* Total income
* Total expense
* Current month expense
* Top expense categories
* Recent transactions

### Transactions

* Add income and expenses
* Edit transactions
* Delete transactions
* Undo delete
* Search transactions
* Filter transactions
* Sort transactions
* Transaction notes
* Date selection

### Categories

* Create custom categories
* Rename categories
* Delete unused categories
* Protection against deleting categories currently in use

### Recurring Transactions

* Monthly recurring income and expenses
* Configurable processing start date
* Automatic monthly transaction generation
* Enable or disable recurring entries
* Edit recurring transactions

### Statistics

* Income summary
* Expense summary
* Current balance
* Transaction count
* Highest income
* Highest expense
* Category-wise expense totals
* Average monthly expenses by category

### Data Management

* Multiple SQLite databases
* Create databases
* Rename databases
* Switch databases
* Delete databases
* Database backup
* Database import
* Database export
* CSV export

### About

* App version
* Database version
* Export information
* Release notes
* GitHub repository

---

## Design Goals

* Offline-first
* Fast startup
* Lightweight
* Material 3 UI
* Responsive layout
* Production-ready architecture
* Beginner-friendly and maintainable codebase

---

## Tech Stack

* Flutter
* Dart
* Riverpod
* GoRouter
* SQLite (sqflite)
* Material 3
* Path Provider
* Storage Access Framework (Android)
* url_launcher

---

## Project Structure

```text
lib/
├── app/
├── core/
│   ├── constants/
│   ├── database/
│   ├── notifications/
│   └── theme/
├── features/
│   ├── about/
│   ├── dashboard/
│   ├── transactions/
│   ├── categories/
│   ├── recurring/
│   ├── statistics/
│   └── data_management/
├── models/
├── repositories/
├── routes/
├── services/
├── shared/
└── main.dart
```

---

## Architecture

The application follows a feature-based architecture.

```
UI
    ↓
Riverpod Notifiers
    ↓
Repositories
    ↓
SQLite Database
```

This separation keeps business logic independent from the user interface and makes the application easier to maintain and extend.

---

## Database

* SQLite
* Schema version: **4**
* Supports multiple databases
* Automatic migration support
* Foreign key constraints enabled

---

## Supported Platforms

| Platform | Status      |
| -------- | ----------- |
| Android  | ✅ Supported |
| Windows  | ✅ Supported |
| Web      | Planned     |

---

## Building

### Debug

```bash
flutter run
```

### Release APK

```bash
flutter build apk --release
```

---

## Philosophy

Minimal Pocket Finance is designed around three simple principles:

* Your financial data belongs to you.
* Everything should work completely offline.
* The application should remain fast, simple, and easy to use.

No accounts.
No subscriptions.
No cloud dependency.

---

## Roadmap

### Version 1.x

* Improved statistics
* Better recurring transaction management
* UI refinements
* Performance improvements
* Additional export options

### Future

* CSV import
* Budget planning
* Charts and analytics
* Material You support
* Tablet optimization
* Web support

---

## Contributing

Bug reports, feature requests, and pull requests are welcome.

If you find a bug or have an idea for improvement, please open an issue on GitHub.

GitHub:
https://github.com/elitefantasy/minimal-pocket-finance-app

---

## License

This project is licensed under the MIT License.

---

## Author

**Anil Maurya**

GitHub: https://github.com/elitefantasy

---

If you find this project useful, consider giving it a ⭐ on GitHub.
