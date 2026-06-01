# 05 - Loader and Feedback Patterns

## ⏱️ Handling Latency
Since Nexus integrates with multiple AI providers, latency is inevitable. We use a tiered loading strategy to manage user expectations.

---

## 🏗️ Loading States

### 1. Skeleton Screens (Preferred)
Used when loading lists or dashboards.
- **Style**: Grey pulsed shapes matching the final layout.
- **Animation**: Shimmer effect moving left-to-right.

### 2. The AI Pulse (Hédra Thinking)
Used during AI reasoning or generation.
- **Location**: Bottom-right orb or inline where text is appearing.
- **Effect**: A rotating gradient border around the text box.

### 3. Global Loading Bar
Used for heavy background operations (Exports, Database Migrations).
- **Style**: A 2px high Nexus Blue line at the very top of the window.

---

## 💬 Feedback Mechanisms

### Toasts (Snackbars)
- **Position**: Bottom-center on mobile, Top-right on desktop.
- **Duration**: 4 seconds.
- **Types**:
    - **Success**: "Task completed."
    - **Error**: "Failed to connect to Provider." (Includes 'Retry' button).
    - **Action**: "Message archived." (Includes 'Undo' button).

### Inline Validation
Form fields show errors in real-time.
- **Color**: Error Red (`#EF4444`).
- **Icon**: Small exclamation mark.

---

## 🤖 AI Progress Feedback
When AI generates long text:
- **Streaming**: Display text word-by-word as it arrives.
- **Typing Indicator**: Three pulsing dots if streaming is delayed.
- **Cost Estimate**: Update a small cost counter (e.g., "$0.02") in real-time as tokens are consumed.

---

## Empty States
Every hub must have an empty state illustration/message.
- **Style**: Minimalist outline illustration.
- **CTA**: Always provide a "Create First [Entity]" button.
- **Guidance**: "No contacts found. Start by importing from Google or adding manually."
# 05 - Loader and Feedback Patterns

## ⏱️ Handling Latency
Since Nexus integrates with multiple AI providers, latency is inevitable. We use a tiered loading strategy to manage user expectations.

---

## 🏗️ Loading States

### 1. Skeleton Screens (Preferred)
Used when loading lists or dashboards.
- **Style**: Grey pulsed shapes matching the final layout.
- **Animation**: Shimmer effect moving left-to-right.

### 2. The AI Pulse (Hédra Thinking)
Used during AI reasoning or generation.
- **Location**: Bottom-right orb or inline where text is appearing.
- **Effect**: A rotating gradient border around the text box.

### 3. Global Loading Bar
Used for heavy background operations (Exports, Database Migrations).
- **Style**: A 2px high Nexus Blue line at the very top of the window.

---

## 💬 Feedback Mechanisms

### Toasts (Snackbars)
- **Position**: Bottom-center on mobile, Top-right on desktop.
- **Duration**: 4 seconds.
- **Types**:
    - **Success**: "Task completed."
    - **Error**: "Failed to connect to Provider." (Includes 'Retry' button).
    - **Action**: "Message archived." (Includes 'Undo' button).

### Inline Validation
Form fields show errors in real-time.
- **Color**: Error Red (`#EF4444`).
- **Icon**: Small exclamation mark.

---

## 🤖 AI Progress Feedback
When AI generates long text:
- **Streaming**: Display text word-by-word as it arrives.
- **Typing Indicator**: Three pulsing dots if streaming is delayed.
- **Cost Estimate**: Update a small cost counter (e.g., "$0.02") in real-time as tokens are consumed.

---

## Empty States
Every hub must have an empty state illustration/message.
- **Style**: Minimalist outline illustration.
- **CTA**: Always provide a "Create First [Entity]" button.
- **Guidance**: "No contacts found. Start by importing from Google or adding manually."
