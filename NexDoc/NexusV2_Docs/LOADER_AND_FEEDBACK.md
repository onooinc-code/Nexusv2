# Loader and Feedback Systems

## Loading States
- **Skeletons:** `NxSkeleton.tsx` and `SkeletonLoaders.tsx` provide immediate structural placeholders while asynchronous data fetches.
- **Progress Bars:** `TransitionProgressBar.tsx` is used for page navigation and long-running linear tasks.
- **Indicators:** `NxThinkingIndicator.tsx` is specifically used within chat interfaces to denote AI processing.

## Feedback Mechanisms
- **Toasts:** `NxToast.tsx` handles transient success, error, and warning messages.
- **Job Monitor:** `GlobalJobMonitor.tsx` provides persistent background task tracking, showing percentages and failure states (e.g., using XCircle icons).
- **Status Badges:** `NxStatusBadge` and `NxAgentStatusOrb` provide at-a-glance health metrics for entities.
