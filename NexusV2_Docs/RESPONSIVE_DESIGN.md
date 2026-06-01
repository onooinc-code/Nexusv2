# 03 - Responsive Design

## 📱 Mobile-First Strategy
While Nexus is a powerful desktop productivity tool, the UI is built using a **Mobile-First** approach to ensure critical AI interactions and contact management are accessible on the go.

## 📏 Breakpoints

| Breakpoint | Range | Navigation Style |
|------------|-------|------------------|
| **Mobile** | `< 768px` | Bottom Tab Bar + Fullscreen Modals |
| **Tablet** | `768px - 1024px` | Collapsed Left Sidebar + Floating Hub Panel |
| **Desktop** | `> 1024px` | Full 3-Pane Layout |

---

## 🏗️ Adaptive Component Behavior

### The 3-Pane Layout on Mobile
The desktop 3-pane layout transforms into a **Stack-and-Slide** system:
1. **List View**: Users see the entity list (Hub Sidebar).
2. **Detail View**: Clicking an entity slides in a fullscreen view (Workspace).
3. **Back Button**: Always present in the top-left of the Detail View to return to the List.

### Navigation Transition
- **Desktop**: Persistent sidebar on the left.
- **Mobile**: A bottom navigation bar with 5 icons: `Agents`, `Memory`, `Contacts`, `Workflows`, `Search`.

---

## 🖱️ Touch vs. Cursor
- **Targets**: Interactive elements on mobile have a minimum tap area of `44x44px`.
- **Gestures**: 
    - **Swipe Right**: Go back (in Detail views).
    - **Swipe Left on Item**: Quick actions (Delete, Archive, Star).
    - **Pull-to-Refresh**: Available on all list views.

---

## 🖼️ Responsive Tables & Data
High-density data in hubs (like Logs or Task lists) uses an **Adaptive Row** pattern:
- **Desktop**: Full multi-column table.
- **Mobile**: Table rows transform into "Cards" showing only primary data (Title, Status, Date) with a "Tap for more" chevron.

---

## ⌨️ Input Handling
- **Mobile AI Input**: Larger "Microphone" button for voice-to-text.
- **Keyboard Optimization**: Inputs on mobile trigger appropriate keyboard types (Email, Number, Text) and use `sticky` positioning for the input bar above the virtual keyboard.
