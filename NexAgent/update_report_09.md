# Update Report 09: SchedulerHub and LogsHub

## Summary of Changes
Completed a critical pass over the final set of systems: `LogsHub` and `SchedulerHub`, which were suffering from UI crashes and 404 connection errors.

### LogsHub 
- **Endpoint Prefix Update**: Updated all API calls in `app/logs/page.tsx` from hitting the non-existent root (`/logs`) to correctly hitting the validated endpoint group (`/v1/logs`).
- **Real-time Pipeline Polling**: Verified polling logic, channel definitions, and filtering components to ensure they properly authenticate to the `v1` group.

### SchedulerHub
- **Endpoint Prefix Update**: Updated the `apiClient` actions (`GET`, `POST`, `PUT`, `DELETE`) in `app/scheduler/page.tsx` to include the required `/v1/` prefix (e.g. `/v1/scheduler`).
- **Resource Actions Restored**: The UI can now safely create Webhooks, Commands, and Script execution triggers without the backend rejecting the traffic.

## Modified Files
- `Nexus-Frontend/app/logs/page.tsx`
- `Nexus-Frontend/app/scheduler/page.tsx`
