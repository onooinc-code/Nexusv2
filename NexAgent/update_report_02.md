# Update Report 2

The following files were updated to fix the build errors:

## Frontend (Nexus-Frontend)
1. `components/NxImportModal.tsx`
   - Fixed the `NxSelect` component usage. The component does not accept an `options` prop, but rather standard `<option>` elements as `children`. Modified the code to pass `<option>` tags explicitly instead of the `options` array.
