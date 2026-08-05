---
name: LUNA Mental Health
colors:
  surface: '#f8f9fe'
  surface-dim: '#d8dadf'
  surface-bright: '#f8f9fe'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f3f8'
  surface-container: '#eceef3'
  surface-container-high: '#e7e8ed'
  surface-container-highest: '#e1e2e7'
  on-surface: '#191c1f'
  on-surface-variant: '#464652'
  inverse-surface: '#2e3134'
  inverse-on-surface: '#eff0f5'
  outline: '#767684'
  outline-variant: '#c6c5d5'
  surface-tint: '#4b53bb'
  primary: '#4b53bb'
  on-primary: '#ffffff'
  primary-container: '#8b93ff'
  on-primary-container: '#1d238f'
  inverse-primary: '#bec2ff'
  secondary: '#605a79'
  on-secondary: '#ffffff'
  secondary-container: '#e0d8fd'
  on-secondary-container: '#625d7c'
  tertiary: '#20667b'
  on-tertiary: '#ffffff'
  tertiary-container: '#67a5bc'
  on-tertiary-container: '#003948'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e0e0ff'
  primary-fixed-dim: '#bec2ff'
  on-primary-fixed: '#00016d'
  on-primary-fixed-variant: '#3239a2'
  secondary-fixed: '#e6deff'
  secondary-fixed-dim: '#c9c2e6'
  on-secondary-fixed: '#1c1833'
  on-secondary-fixed-variant: '#484361'
  tertiary-fixed: '#b8eaff'
  tertiary-fixed-dim: '#91cfe8'
  on-tertiary-fixed: '#001f28'
  on-tertiary-fixed-variant: '#004d61'
  background: '#f8f9fe'
  on-background: '#191c1f'
  surface-variant: '#e1e2e7'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  display-lg-mobile:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 32px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 28px
  label-sm:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  unit: 8px
  container-padding-mobile: 24px
  container-padding-desktop: 64px
  gutter: 16px
  stack-sm: 12px
  stack-md: 24px
  stack-lg: 48px
---

## Brand & Style
The design system is built on a foundation of **Modern Minimalism** infused with **Soft Glassmorphism**. It is designed for a Gen Z audience, prioritizing an atmosphere of digital serenity, emotional safety, and radical clarity. The UI should evoke the feeling of a "deep breath"—spacious, quiet, and profoundly attentive.

The aesthetic avoids corporate coldness by using organic motion and soft, tactile surfaces. It balances the futuristic nature of AI with a grounded, human-centric "Nurturing Assistant" persona. Every interaction should feel like a supportive gesture rather than a mechanical response.

## Colors
The palette utilizes a core triad of **Periwinkle (Primary)**, **Lavender (Secondary)**, and **Sky Blue (Tertiary)**. 

- **Primary (#8B93FF):** Used for active states, primary actions, and the core identity of the assistant.
- **Secondary (#E2DAFF):** Primarily used for soft backgrounds and subtle container highlights.
- **Tertiary (#A7E6FF):** Reserved for "nurturing" moments, progress indicators, and breath-work guidance.
- **Neutral (#F8F9FE):** A cool-tinted off-white that prevents screen fatigue and provides the "lots of whitespace" required by the brand.

Surface colors should use high-transparency overlays of the primary and secondary colors to maintain a cohesive, airy feel.

## Typography
This design system employs **Inter** exclusively to achieve a systematic yet approachable feel. 

- **Generous Line Heights:** To reduce cognitive load and improve readability for users who may be in a state of stress, body text uses a highly expanded line height (approx 1.75x).
- **Lowercase Emphasis:** For a more casual, Gen Z-friendly tone, secondary headings and labels may occasionally use sentence case or lowercase to feel less "institutional."
- **Optical Sizing:** Use Inter's variable axes to ensure legibility in smaller labels while maintaining tight, clean characters in display headings.

## Layout & Spacing
The layout follows a **Fluid Grid** model with an emphasis on vertical rhythm. 

- **Breathing Room:** We utilize "Stack" variables to ensure significant vertical separation between distinct emotional sections.
- **Mobile First:** Given the target audience, the design is optimized for 1-column layouts with floating elements. 
- **Safe Zones:** High-priority buttons and AI input fields are always placed within the "thumb-zone" (bottom 40% of the screen) to reduce physical strain during long journaling or chat sessions.

## Elevation & Depth
Depth in this design system is created through **Glassmorphism** and **Ambient Shadows** rather than traditional elevation.

- **Surface Layers:** The background is a soft gradient. Content sits on "Glass Plates"—semi-transparent surfaces with a `backdrop-filter: blur(20px)` and a thin `1px` white border at 40% opacity to define the edge.
- **Shadows:** Use extremely diffused, large-radius shadows (e.g., `box-shadow: 0 20px 40px rgba(139, 147, 255, 0.1)`). Shadows should carry a slight tint of the primary periwinkle to feel integrated with the environment.
- **Interaction:** Upon interaction, surfaces should "lift" by increasing blur and shadow spread, mimicking a physical cushion.

## Shapes
The shape language is dominated by **Hyper-Rounded** forms. 

- **Standard Elements:** Buttons, cards, and input fields use a base radius of 24px to ensure no sharp edges exist in the UI.
- **Pill Shapes:** Interactive chips and the primary AI input bar use a fully rounded (pill) style to maximize the friendly, modern aesthetic.
- **Fluidity:** Icons should have rounded terminals and soft corners to match the UI elements.

## Components
- **Buttons:** High-contrast primary buttons use the Primary Periwinkle with white text. Secondary buttons are "ghost" glass plates. All buttons have a minimum height of 56px for accessibility and a "squishy" press animation.
- **AI Chat Bubbles:** The Assistant's bubbles are glassmorphic with a Lavender tint. User bubbles are solid Periwinkle. All bubbles have a 24px radius, with the "tail" corner being slightly sharper (8px).
- **Cards:** Used for mood tracking and resource modules. They feature a `20px` blur, white inner border, and a subtle drop shadow.
- **Mood Sliders:** Thick, rounded tracks with a large, glowing thumb indicator that changes color from Lavender to Sky Blue based on the value.
- **Input Fields:** The chat bar is a floating pill shape with a glass effect, staying fixed at the bottom of the screen to invite constant interaction.
- **Progress Rings:** Soft, thick-stroked circles using the Tertiary Sky Blue for completion states, reflecting a gentle, non-pressured approach to goal tracking.