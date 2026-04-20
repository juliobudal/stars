// celebration_controller.js — LittleStars confetti burst
// Usage: data-controller="celebration" on the screen wrapper
//   data-action="celebration#burst" on a button/element
//   data-celebration-target="layer" on the confetti-layer div

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["layer"]

  burst() {
    if (!this.hasLayerTarget) return
    // Guard: skip if fired within the last 500ms (prevents repeat-spam)
    const now = Date.now()
    if (this._lastBurstAt && now - this._lastBurstAt < 500) return
    this._lastBurstAt = now
    const layer = this.layerTarget
    layer.style.display = "block"
    layer.innerHTML = ""

    const colors = ["#ffc41a", "#ff8a5c", "#ff5a8a", "#3ed49e", "#38b6ff", "#9b7aff"]
    const shapes = ["50%", "20%", "4px"]

    // Create 60 confetti pieces
    for (let i = 0; i < 60; i++) {
      const el = document.createElement("div")
      el.className = "confetti"
      el.style.cssText = `
        left: ${Math.random() * 100}%;
        top: -20px;
        background: ${colors[i % colors.length]};
        border-radius: ${shapes[i % shapes.length]};
        width: ${8 + Math.random() * 10}px;
        height: ${8 + Math.random() * 10}px;
        animation-delay: ${Math.random() * 0.3}s;
        transform: rotate(${Math.random() * 360}deg);
      `
      layer.appendChild(el)
    }

    // Glow burst at center
    const glow = document.createElement("div")
    glow.className = "glow-burst"
    glow.style.cssText = "left: 50%; top: 50%;"
    layer.appendChild(glow)

    // Clean up after animation
    setTimeout(() => {
      layer.style.display = "none"
      layer.innerHTML = ""
    }, 2500)
  }

  // Call this from Turbo stream after approval to auto-trigger
  connect() {
    const shouldCelebrate = this.element.dataset.celebrationAutoValue
    if (shouldCelebrate === "true") {
      setTimeout(() => this.burst(), 300)
    }
  }
}
