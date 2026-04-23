// count_up_controller.js — LittleStars animated balance counter
// Usage: data-controller="count-up" data-count-up-value-value="150" on wrapper
//   data-count-up-target="display" on the number element

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display"]
  static values = {
    current: Number,
    duration: { type: Number, default: 600 }
  }

  connect() {
    this.displayed = isNaN(this.currentValue) ? 0 : this.currentValue
  }

  // Call animateTo(newValue) externally or via data-action
  animateTo(newValue) {
    const start = this.displayed
    const diff = newValue - start
    const steps = 18
    const interval = this.durationValue / steps
    let i = 0

    const timer = setInterval(() => {
      i++
      this.displayed = Math.round(start + (diff * i / steps))
      if (this.hasDisplayTarget) {
        this.displayTarget.textContent = this.displayed
      }
      if (i >= steps) {
        this.displayed = newValue
        clearInterval(timer)
      }
    }, interval)
  }

  // Called via Turbo stream morphing when points update
  currentValueChanged(value, previousValue) {
    if (previousValue !== undefined && value !== previousValue) {
      this.animateTo(value)
    } else {
      this.displayed = value
    }
  }
}
