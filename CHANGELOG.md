# Changelog

All notable changes to **Minimal Pocket Finance** will be documented in this file.

The format is based on **Keep a Changelog**, and this project follows **Semantic Versioning**.

---

## [1.0.0] - 2026-07-06

Initial public release of **Minimal Pocket Finance**.

### Added

* Dashboard showing:

  * Current Balance
  * Total Income
  * Total Expense
  * Current Month Expense
  * Top Expense Category
  * Recent Transactions
* Add income and expense transactions.
* Edit existing transactions.
* Delete transactions.
* Undo transaction deletion.
* Transaction history screen.
* Transaction search.
* Transaction filtering.
* Transaction sorting.
* Optional notes for transactions.
* Custom category management.
* Protection against deleting categories that are currently in use.
* Monthly recurring income and expense support.
* Automatic recurring transaction processing.
* Edit and delete recurring transactions.
* Statistics dashboard including:

  * Income
  * Expense
  * Balance
  * Transaction count
  * Highest income
  * Highest expense
  * Category totals
  * Monthly average expense by category
* Multiple SQLite database support.
* Create, rename, delete, and switch databases.
* Database import support.
* Database export support.
* CSV transaction export.
* About screen with application information.
* Clickable GitHub repository link.
* Dynamic application version detection using `package_info_plus`.
* Centralized snackbar service for user feedback.

### Changed

* Recurring transactions now generate transactions only on their scheduled processing date instead of immediately upon creation.
* Recurring transaction origin tracking migrated from note-based detection to relational origin tracking.
* Export and import workflows improved for better consistency.

### Technical

* Flutter application using Material 3.
* Riverpod state management.
* GoRouter navigation.
* SQLite local database.
* Repository pattern.
* Feature-based project structure.
* Offline-first architecture.
* Android support.
* Windows desktop support.

### Fixed

* Various stability improvements during the initial development cycle.

---

## [Unreleased]

### Added

* Application launcher icons.

### Improved

* Complete Material 3 design system.
* Centralized theme infrastructure.
* Shared spacing, typography, sizing, radius, icons, and color tokens.
* Reusable UI components.
* Dashboard layout and visual polish.
* Transaction entry experience.
* Transaction history experience.
* Statistics screen.
* Category management interface.
* Recurring transaction interface.
* Data management interface.
* Danger Zone redesign.
* Monthly average dashboard calculations.
* Dashboard performance optimizations.
* Last selected transaction date is preserved across navigation.

### Fixed

* Windows SQLite FFI initialization during desktop startup.
