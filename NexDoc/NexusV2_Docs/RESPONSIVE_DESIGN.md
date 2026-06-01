# Responsive Design

## Framework
Utilizes Tailwind CSS's mobile-first breakpoint system:
- `sm:` (640px)
- `md:` (768px)
- `lg:` (1024px)
- `xl:` (1280px)

## Implementation
- Fluid typographies using `clamp()` where necessary.
- Flexbox and CSS Grid are used extensively in components like `NxGlassCard` and `AppLayout` to ensure elements reflow logically as the screen size changes.
- The `use-mobile.ts` hook allows components to conditionally render or alter logic based on viewport width programmatically.
