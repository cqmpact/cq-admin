# Contributing to cq-admin

Thank you for your interest in contributing to the cq-admin resource!

This resource is licensed under the Mozilla Public License 2.0 (MPL-2.0). By submitting a pull request, you agree your contribution will be licensed under MPL-2.0.

- License: `MPL-2.0`
- SPDX identifier: `MPL-2.0`
- License file: `LICENSE` (included in this repository)

## Ground rules

- Follow the existing code style and patterns used in cq-admin modules.
- Keep changes focused and narrowly scoped; prefer small PRs over large ones.
- Be respectful in discussions. Assume good intent and provide constructive feedback.
- Do not include third-party copyrighted content without permission and proper attribution.

## Commit and PR guidelines

- Use Conventional Commits for PR titles and commits when possible, e.g.:
  - `feat: add vehicle neon color picker`
  - `fix(admin): prevent nil player index in spectate`
- Link issues in PR descriptions when applicable.
- Fill out the provided PR template: `.github/pull_request_template.md`.
- CI must be green before merge: see `.github/workflows/`.

## Development workflow (typical)

1. Create a feature branch.
2. Make changes within this resource: `server-data/resources/[code]/cq-admin`.
3. Test locally on a FiveM server:
   - Start a local server and `ensure cq-admin`.
   - Watch for console errors on start and during use.
   - Grant yourself temporary ACEs as needed for admin features and verify affected sections.
4. Update docs (e.g., this `README.md`) when adding/removing features.
5. Run checks locally if available; push and open a PR.

## Code style and languages

This resource uses Lua (and may include small HTML/CSS/JS assets). Mirror existing patterns.

When adding new source files, include an SPDX header when appropriate:

```
-- SPDX-License-Identifier: MPL-2.0    (Lua)
// SPDX-License-Identifier: MPL-2.0    (TS/JS)
<!-- SPDX-License-Identifier: MPL-2.0 --> (HTML)
```
And add your name and GitHub link to the contributor table on top of the file you're modifying.

## Licensing of contributions (MPL-2.0)

- Files modified from MPL-2.0-covered originals must remain under MPL-2.0.
- New files you add may be licensed; however, you choose, as long as you comply with MPL-2.0 regarding any 
  MPL-covered files you modify. For simplicity and consistency, I recommend MPL-2.0 for new files too.
- If you include or modify third-party code, ensure its license is compatible and include proper attribution and license notices as required.

## Security

If you believe you have found a security vulnerability, please do not open a public issue. Instead, contact the maintainers privately so a fix can be coordinated before public disclosure.

## Getting help

- Bug reports: `.github/ISSUE_TEMPLATE/bug_report.md`
- Feature requests: `.github/ISSUE_TEMPLATE/feature_request.md`
- Discussions and questions: open an issue if no better channel exists.

Thanks for contributing!
