import { Controller } from "@hotwired/stimulus"

// Counts down a Lightning Round timer (default 90s). Visual only — server
// doesn't enforce the cap; if the kid takes longer that's fine, the score
// just shows the elapsed time.
export default class extends Controller {
  static targets = ["display"]
  static values  = { start: Number }

  connect() {
    this.remaining = this.startValue || 90
    this.tick()
    this.interval = setInterval(() => this.tick(), 1000)
  }

  disconnect() { clearInterval(this.interval) }

  tick() {
    if (this.remaining <= 0) {
      this.displayTarget.textContent = "0"
      clearInterval(this.interval)
      return
    }
    this.displayTarget.textContent = String(this.remaining)
    this.remaining -= 1
  }
}
