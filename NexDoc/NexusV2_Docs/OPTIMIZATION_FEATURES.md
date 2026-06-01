# Optimization Features

## AI Resource Management
- **Token Budgeting:** The system visualizes and caps token usage (`NxTokenBudget.tsx`) to prevent runaway costs from autonomous agents.
- **Model Routing:** Logic exists to route simpler queries to faster, cheaper models (`gemini-3.5-flash`) and complex structural reasoning tasks to heavier models (`gemini-3.1-pro-preview`).

## Frontend Asset Optimization
- Strict configuration in `next.config.ts` for image optimization.
- PostCSS and Tailwind v4 setup ensures that only used CSS classes are included in the final production build.
