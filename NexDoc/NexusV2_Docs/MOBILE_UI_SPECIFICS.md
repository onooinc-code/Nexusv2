# Mobile UI Specifics

## Adaptation Strategy
- **Navigation:** The standard desktop sidebar (`NxNavRail`) collapses into a `MobileHeader` with a hamburger menu or bottom navigation bar on smaller screens.
- **Data Tables:** Complex grids (`NxDataGrid`) adapt to list views or horizontally scrollable containers to preserve data integrity on narrow viewports.
- **Overlays:** Modals and draw-outs take up full screen width on mobile to maximize tap targets.

## Touch Interactions
- Integration of `use-haptic.ts` to provide physical feedback on mobile devices for key interactions (e.g., button presses, toggles).
