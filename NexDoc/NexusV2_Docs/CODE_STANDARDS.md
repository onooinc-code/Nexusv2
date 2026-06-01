# Code Standards

## TypeScript
- Strict mode is enabled.
- Avoid `any`; use precise types or `unknown`.
- Export all interfaces used in component props from a central `/types` directory where applicable.

## React & Next.js
- Prefer Server Components for static data. Use `"use client"` only when necessary (e.g., hooks, interactives).
- Use composition over inheritance.
- Always use Next.js `Image` component for optimized assets.

## Styling
- Use Tailwind utility classes.
- Encapsulate complex or repeating patterns using `@apply` in `/styles/tokens.css` or global css.
- Merge classes using `tailwind-merge` (often via a `cn()` utility).

## Linting
- Follow the provided `eslint.config.mjs` rules.
- Prettier is used for formatting (see `.prettierrc`).
