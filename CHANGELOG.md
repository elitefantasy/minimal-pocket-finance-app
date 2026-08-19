## Planned Feature





# Unreleased:
## Version 2.2.0
- fix(analytics): standardize monthly average calculation across dashboard and category statistics
- feat(export): custom export folder management with file migration prompt
- feat(export): prompt user to rename database when exporting with prefilled default


# version 2.1.1
- chore: rename package to minimal_pocket_finance_app in pubspec.yaml
- fix(about): enable dynamic versioning from pubspec.yaml and platform config
- feat: configure Android build settings and migrate flutter_launcher_icons to dev_dependencies so that app size decreases
- UI: style(dashboard): reorder home screen section layout

# Version 2.1.0
### features
- feat(categories): add category deletion confirmation dialog and auto-recreation of default categories
- feat(sync): add transaction categories to P2P sync payload
- feat(sync): add WebRTC ACK protocol and fix one-way push timeout issue
- feat(sync): Directional Sync Choices and Enhanced Connection States
- feat: implement tombstone mechanism for P2P sync deletions
- feat(ui): update recurring transaction chip styling
- feat(sync): add recurring transactions to P2P sync and use UUID deduplication
- feat: Refactor the SQLite database and Dart data models to migrate from auto-increment IDs to UUIDs to prepare for real-world P2P synchronization.
- feat: implement secure P2P synchronization architecture with E2EE crypto service, signaling support, and pairing UI
- feat: Image Attachments for Transactions 
### fixes
- fix(database): resolve v2.0.0 database migration crash and add dynamic DB version to about screen
- fix: process recurring transactions before normal transactions during sync
- fix(sync): add signature fallback to prevent duplicates from v5 migration
- fix: overflow issue with trash transaction tiles
- fix: in windows fixed missingpluginexception error because SAF plugin channels are native to Android and do not exist on Desktop platforms. 
- fix: more menu is missing by bottom 39 pixel


# Released: v2.0.0
### 🚀 New Features
- feat: add full export path resolution for Android database and CSV exports 
- feat: trash bin implementation
- feat: add persisted global year filter
- feat(transactions): preserve selected date across navigation
- feat(dashboard): add monthly average expense card based on recorded expense months
- feat: quickly open related transactions from dashboard and statistics
- feat: add searchable category picker with smart category creation
### changes
- changes: reset database version to 1 
- changes: timestamped database backups/exports.
- changes: read app version dynamically using package_info_plus
### UI and themes
- feat(ui): make transaction notes optional with animated expandable field
- feat(theme): add centralized design system infrastructure
- feat(theme): complete Material 3 design system infrastructure
- Add application launcher icons
- feat(dashboard): polish finance overview visuals
- feat(forms): polish transaction entry experience
- feat(history): polish transaction activity experience
- feat(statistics): polish summary and category insights UI
- feat(categories): polish category management UI
- feat(recurring): polish recurring transaction management UI
- style(data-management): polish danger zone card style: unify Material 3 presentation consistency
 
### optimization
- Optimization: The expensive calculations inside dashboardSummaryProvider are not recomputed
refactor(dashboard): separate top category sorting from dashboard summary and improve sort indicator UI
- refactor(theme): align component defaults with design tokens
- refactor(ui): migrate reusable widgets to design system tokens

### 🐛 Bug Fixes
- fix: initialize SQLite FFI before desktop app startup
- fix: initialize history filters after first frame
- fix: in windows shows full path where exported database is located

# v1.0.0
### 🚀 New Features
- Add centralized app snackbar service
- Implemented recurring transaction origin tracking with a relational nullable origin column instead of any note-based inference.
- feat(about): add clickable GitHub link using UrlLauncherService
- Release: v1 release codebase






