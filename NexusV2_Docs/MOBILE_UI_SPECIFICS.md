# 08 - Mobile UI Specifics

## 📱 Mobile Experience Goals
The mobile app is optimized for **fast capture** and **on-the-go reference**. It is not intended for heavy configuration, which is reserved for desktop.

---

## 🏗️ Navigation: The "Action Orb"
The central navigation item on mobile is a **floating purple orb** (Hédra).
- **Single Tap**: Opens the "Quick Capture" input (Voice/Text).
- **Double Tap**: Triggers immediate "Surrounding Context" analysis (using camera/mic if permitted).

---

## 👆 Gestures & Shortcuts

### Swipe Actions in Lists
- **Swipe Right**: "Done" (Tasks) or "Call" (Contacts).
- **Swipe Left**: "Delete" or "Archive".

### Long Press (Haptic Touch)
- **Contacts**: Preview beliefs/details without opening full profile.
- **Messages**: Open "Refine AI Response" context menu.

---

## 🎤 Voice-First Integration
- **Dictation Mode**: A dedicated fullscreen view with waveform animation.
- **Audio Feedback**: Subtle haptic pulses while Hédra is "listening."

---

## 🔒 Security: Bio-Auth
On mobile, sensitive hubs (Memory, Security Settings) can be locked behind **FaceID / Fingerprint** authentication.
- **UI**: A lock icon overlay on the hub sidebar item.

---

## 🔋 Battery & Data Savings
- **Reduced Mode**: On low battery, background sync and heavy glassmorphism blurs are reduced.
- **Data Guard**: High-resolution image analysis and heavy model calls require a "Confirm" tap if on cellular data.
