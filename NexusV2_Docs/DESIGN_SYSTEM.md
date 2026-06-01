# 01 - Design System

## 🎨 Visual Identity
The Nexus (Hédra) visual identity is designed to be **sophisticated, minimalist, and high-tech**, yet approachable. It uses a "Glassmorphism" aesthetic with deep space tones, vibrant accents, and clean typography to evoke a sense of advanced intelligence.

## 🌈 Color Palette

### Primary Brand Colors
- **Nexus Blue**: `#007AFF` (Action, focus, Primary CTA)
- **Hédra Purple**: `#6366F1` (Intelligence, AI signals, Brand identity)
- **Deep Space**: `#0B0E14` (Main background)
- **Surface Dark**: `#161B22` (Card and component backgrounds)

### Functional Colors
- **Success**: `#10B981`
- **Warning**: `#F59E0B`
- **Error**: `#EF4444`
- **Info**: `#3B82F6`

### Text Colors
- **High Emphasis**: `#F9FAFB` (95% contrast)
- **Medium Emphasis**: `#9CA3AF` (60% contrast)
- **Low Emphasis**: `#6B7280` (40% contrast)
- **Disabled**: `#374151`

---

## 🔡 Typography

- **Primary Font**: `Inter` (Sans-serif)
- **Secondary/Code Font**: `JetBrains Mono`

| Style | Weight | Size | Line Height | Use Case |
|-------|--------|------|-------------|----------|
| **Display** | Bold | 48px | 1.1 | Large hero headings |
| **H1** | Bold | 32px | 1.2 | Page titles |
| **H2** | Semibold | 24px | 1.3 | Section headers |
| **H3** | Semibold | 20px | 1.4 | Card titles |
| **Body Large** | Regular | 18px | 1.5 | Large paragraphs |
| **Body Main** | Regular | 16px | 1.6 | Standard content |
| **Body Small** | Regular | 14px | 1.6 | Meta data, labels |
| **Caption** | Medium | 12px | 1.4 | Tiny descriptors |

---

## 📐 Layout & Spacing

Nexus uses a **4px baseline grid** for all spacing.

- **Base Unit**: `4px`
- **Small (S)**: `8px`
- **Medium (M)**: `16px`
- **Large (L)**: `24px`
- **Extra Large (XL)**: `32px`
- **Giant (XXL)**: `48px`

### Container Max Widths
- **Desktop**: `1440px`
- **Tablet**: `768px`
- **Mobile**: `375px`

---

## 🧊 Effects & Depth

### Glassmorphism (The "Nexus Look")
Most UI components use a frosted glass effect to maintain depth.
- **Background**: `rgba(22, 27, 34, 0.7)`
- **Blur**: `backdrop-filter: blur(12px)`
- **Border**: `1px solid rgba(255, 255, 255, 0.1)`

### Shadow System
- **Elevation 1**: `0 4px 6px -1px rgba(0, 0, 0, 0.3)` (Cards)
- **Elevation 2**: `0 10px 15px -3px rgba(0, 0, 0, 0.5)` (Dropdowns)
- **Elevation 3**: `0 20px 25px -5px rgba(0, 0, 0, 0.7)` (Modals)

---

## 🔘 Core UI Components

### Buttons
- **Primary**: Solid Nexus Blue, white text.
- **Secondary**: Glassmorphism border, high-emphasis text.
- **Ghost**: No background/border until hover.
- **Icon-only**: Circle or square glass containers for action icons.

### Form Inputs
- **Background**: Darker surface (`#0D1117`).
- **Focus State**: 2px Nexus Blue glow.
- **Border Radius**: `8px` (Standard for all components).

---

## 🎭 Iconography
- **Set**: `Lucide Icons` (Stroke-based, 2px weight).
- **Style**: Minimal, consistent stroke width, often paired with subtle glows in AI contexts.

---

## 🎞️ Brand Motion
Motion is critical to the "living" feel of Hédra.
- **AI Thinking**: A pulsing purple/blue gradient glow.
- **Entry Animations**: Subtle 10px slide-up with fade-in (300ms).
- **Hover Transitions**: 200ms ease-in-out.
