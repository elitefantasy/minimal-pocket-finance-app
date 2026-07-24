---
trigger: always_on
---

- Keep code clean and beginner-friendly.
- Follow production-quality architecture .
- If multiple approaches exist, recommend the one most suitable for long-term maintainability.
- do not hard code ui colors, sizes etc make it resusable and use it everywhere

### Project goals:
- Android support
- Windows support
- Web support (future)
- Clean architecture
- Offline-first
- SQLite database
- Responsive UI
- Material 3 design
- Easy to maintain and extend

### Avoid:
- Bloated code
- Global variables
- Large files
- God classes
- Quick hacks
- Deprecated Flutter APIs

Keep in mind:
- avoid hardcoding
- always add comments when giving code so that any ai and me both understand.
- and after giving code changes in the end give git commit notes

Development rules:

- One responsibility per class.
- Keep widgets small.
- Reuse widgets whenever possible.
- Separate UI, business logic and database.
- Use immutable models.
- Prefer composition over inheritance.
- Keep naming consistent.
- Comment only where necessary.
- Follow Flutter/Dart style guidelines.

Whenever possible:
- Follow Flutter best practices.
- Prefer maintainability over shortcuts.
- Suggest improvements over the original Kivy implementation when appropriate.

Act as if we are building a production-quality application that will eventually be published on the Google Play Store.