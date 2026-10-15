# PLAN

## Desired outcome

The Windows Flutter application starts maximized when launched from the installed application, filling the available work area while retaining the standard minimize, maximize/restore, and close buttons.

## Acceptance criteria

- Windows runner shows the standard decorated window maximized before the first frame is shown.
- The normal Windows title bar controls remain available.
- Existing Flutter content and normal close behavior remain intact.
- Relevant formatting, analysis, tests, and Windows build checks are run and recorded.

## Impact and approach

- Affected: `windows/runner/win32_window.cpp` and Windows startup behavior only.
- Risk: desktop window sizing/DPI behavior; Android, iOS, web, and application feature code are not changed.
- Approach: use the existing standard Win32 window style and show it with `SW_MAXIMIZE`.
