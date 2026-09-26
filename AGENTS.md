# Design system delivery contract

Read `CLAUDE.md`, `docs/design-system.md` and **`docs/design-guideline.md` (visual style: page header/info bar/card layout, token colours, component choices, do/don't)** before implementation. User instructions take precedence.

For iPad UI design, button placement, spacing, responsive layout or visual review, read and apply the project skill [yellow-ribbon-ipad-ui](.claude/skills/yellow-ribbon-ipad-ui/SKILL.md). It maps Apple HIG to this repository's shared components and visual validation; it does not expand a UI fix into unrelated page or content changes.

## Product goal

New visual designs must become part of the shared system: **theme definition → SystemTheme → production components → pages**, with those exact production components represented in Widgetbook. A page merely using a few theme colors is not a completed migration.

## Required implementation rules

- Use `SystemTheme.of(context)` for semantic colors, typography, spacing and radii. App-level selection/subscription belongs in `SystemThemeScope`; never couple visual components to GetIt, Firebase or editor drafts.
- Use `SystemPage` for migrated page chrome, `SystemSectionCard` for titled sections and the shared card decoration/border for related surfaces. Layout may vary by task; header, controls and surface styling must remain consistent.
- Do not introduce page-specific ThemeExtensions, duplicate palettes, hardcoded brand colors, or a second implementation just for Widgetbook. Structural dimensions such as icon sizes, touch targets and responsive breakpoints may be explicit; explain exceptions when necessary.
- Separate service/navigation adapters from reusable visual components. Inject data and callbacks. Previews use synthetic fixtures and the memory theme repository, never production student data or Firebase initialization.
- Use the dynamic theme catalog; never introduce a closed enum/list of allowed theme IDs. Draft changes stay inside the editor until explicitly published. Widgetbook's memory catalog is separate from the App's repository.
- Preserve existing data, navigation, save/exit, attachment rollback and authorization behavior while migrating visuals.

## Definition of done

1. Register new or changed public product components and their cases in `docs/design-system-components.json` and `widgetbook_gallery/lib/usecases/` in the same change.
2. Include applicable ready/loading/empty/error/disabled/long-content states, Light/Dark, and touch/keyboard interaction. Do not make a disabled action look enabled.
3. Generate `main.directories.g.dart` with build_runner; never edit it manually. Check App and Widgetbook actually use the same component classes.
4. Run `tool/check_design_system.ps1` with the compatible Flutter SDK. This checks catalog coverage, theme propagation, functional regressions, Widgetbook code generation and offline previews.
5. Visually compare related pages under the same theme, including list → detail → edit → back. Check 1024×768, 768×1024, 1194×834, 834×1194 and 507×768 as appropriate. Automated overflow checks alone do not establish visual quality.
6. Report the actual migration scope and evidence; list remaining legacy areas. Do not claim the entire application is tokenized when only some pages are migrated.

No implementation is complete solely because it compiles, has a new theme file, or has a standalone look-alike demo.
