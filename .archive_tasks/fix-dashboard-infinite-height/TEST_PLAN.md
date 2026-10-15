# Test plan

## Cases and expected results

- Inspect the dashboard row inside `SingleChildScrollView`: it uses content-sized vertical alignment.
- Run targeted Dart analysis for the dashboard page.
- Run the relevant Flutter tests and build the Windows app.
- Render a loaded dashboard at a desktop viewport with two chart records and recent activity; expect no layout exception.

## Coverage gaps

- Live dashboard rendering requires the Windows app and configured backend data; runtime inspection will be attempted separately.
