## Planned Feature
🚨 1. High-Priority Improvements (Data Integrity for Sync)
- Migrate to UUIDs (Improvement/Refactor): Currently, transactions use local SQLite auto-increment IDs. If you sync data from Device A to Device B, there will be ID collisions. Refactoring the database to use UUIDs and origin tracking is critical before real-world P2P usage.

commit: Refactor the SQLite database and Dart data models to migrate from auto-increment IDs to UUIDs to prepare for real-world P2P synchronization.

- history should also show that transaction is recurring just like how recurring transactions how
- Tombstones for Deletions (Improvement): Right now, deleted transactions are excluded from sync. If Device A deletes a record and syncs with Device B, Device B will just keep its old copy. You need a "tombstone" mechanism to tell other devices that a record was explicitly deleted.
- DataChannel Chunking (Improvement): WebRTC DataChannels have message size limits. Since your database includes images, sending the full transaction set in one message will fail on large databases. Implementing chunking is essential for reliability.

🌐 2. Networking Feature
- TURN Server Integration (Feature): Your current WebRTC implementation is STUN-only, which works on local networks or permissive NATs, but will reliably fail if one device is on cellular data or a strict symmetric NAT. Adding TURN server support will make the P2P sharing bulletproof across any network.

🎨 4. UI/UX Changes & Roadmap
- Sync Progress UI (UI Change): If you implement data chunking (mentioned in section 1), you will need a UI that shows the real-time progress of the transfer (e.g., a progress bar or "X of Y records synced") rather than a static loading spinner.

# Unreleased:
### features
- feat: implement secure P2P synchronization architecture with E2EE crypto service, signaling support, and pairing UI
- feat: Image Attachments for Transactions 
### fixes
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






