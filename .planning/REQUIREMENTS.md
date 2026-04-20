# Requirements: Milestone 2 - UI/UX Duolingo Rebranding 🦉

## Functional Requirements
- **FR1: Font Integration:** Application must load "Fredoka" from Google Fonts for all rounded headers and body text.
- **FR2: 3D Button Components:** All primary actions must use buttons with "depth" effect (thick bottom border that depresses on active).
- **FR3: Celebration Effects:** Implement real-time confetti using `canvas-confetti` on reward redemptions and task approvals.
- **FR4: Layout Consistency:** Apply the same design language (3D borders, vibrant colors) to both Parent and Kid namespaces.
- **FR5: Iconography:** Maintain Lucide icons but wrap them in high-contrast, colorful circular containers where applicable.

## Non-Functional Requirements
- **NFR1: Performance:** Animations should be CSS-based or lightweight Stimulus to ensure smooth 60fps interaction inside Docker.
- **NFR2: Themeability:** Style should use centralized Tailwind variables in `brand.css` and `theme.css`.
- **NFR3: Accessibility:** Maintain touch target sizes (min 48x48px) suitable for kids.

## Design Specs (Duolingo Look & Feel)
- **Palette:**
  - Success/Green: #58cc02 (Base) / #46a302 (Depth)
  - Info/Blue: #1cb0f6 (Base) / #1899d6 (Depth)
  - Warning/Yellow: #ffc800 (Base) / #e5a400 (Depth)
  - Error/Red: #ff4b4b (Base) / #d33131 (Depth)
  - Secondary/White: #ffffff (Base) / #e5e5e5 (Depth)
- **Borders:** Default rounded-2xl or rounded-3xl.
- **Border Width:** 2px for content, 4-6px for depth effects.
