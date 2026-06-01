# Performance Guidelines

## Frontend Optimization
- **Lazy Loading:** Routes and heavy components should be dynamically imported where applicable to reduce initial bundle size.
- **State Management:** Avoid unnecessary re-renders by selecting specific state slices from the Zustand store.
- **Virtualization:** Implement virtual scrolling for long lists (e.g., in `NxDataGrid`) to maintain 60fps performance.

## Network Efficiency
- **Caching:** Utilize `localStorage` for hydrating initial state (e.g., `hydrateMemories`) before falling back to network requests.
- **Debouncing:** Input fields that trigger network requests (like global search in `NxCommandBar`) must be debounced.
