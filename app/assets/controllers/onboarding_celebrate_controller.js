// onboarding_celebrate_controller.js
// Fires a single confetti burst on connect for the kid onboarding "ready"
// screen. Respects prefers-reduced-motion. Idempotent — only fires once
// per controller lifecycle, so re-renders don't spam confetti.
//
// Uses a dedicated full-screen canvas with `useWorker: false` because the
// app's CSP disallows blob workers (canvas-confetti's default optimization).

import { Controller } from "@hotwired/stimulus"
import confetti from "canvas-confetti"

export default class extends Controller {
  connect() {
    if (this._fired) return
    this._fired = true

    const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    if (reduced) return

    const canvas = document.createElement("canvas")
    Object.assign(canvas.style, {
      position: "fixed",
      inset: "0",
      width: "100vw",
      height: "100vh",
      pointerEvents: "none",
      zIndex: "9999",
    })
    canvas.setAttribute("aria-hidden", "true")
    document.body.appendChild(canvas)

    const fire = confetti.create(canvas, { resize: true, useWorker: false })
    const styles = getComputedStyle(this.element || document.documentElement)
    const colors = ["--primary", "--star", "--c-sky", "--c-coral", "--c-lilac", "--danger"]
      .map((name) => styles.getPropertyValue(name).trim())
      .filter(Boolean)

    fire({
      particleCount: 70,
      spread: 80,
      origin: { y: 0.5 },
      colors,
      disableForReducedMotion: true,
    })

    setTimeout(() => {
      fire({
        particleCount: 120,
        spread: 140,
        startVelocity: 38,
        origin: { y: 0.45 },
        colors,
        disableForReducedMotion: true,
      })
    }, 250)

    // Clean up the canvas after the animation has had time to settle.
    setTimeout(() => canvas.remove(), 4500)
  }
}
