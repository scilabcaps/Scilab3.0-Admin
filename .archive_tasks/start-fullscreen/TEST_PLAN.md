# TEST PLAN

- Run `dart format` on changed Dart files if applicable; no Dart source changes are expected.
- Run `flutter analyze`.
- Run the relevant Flutter tests.
- Build the Windows target and, where available, launch it to verify it opens borderless and fills the monitor.
- Check that the window can still be closed normally.
