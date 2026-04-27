import { Controller } from "@hotwired/stimulus"

// Visual 1–10 star difficulty selector. Updates a hidden input + readout +
// repaints each cell as filled/empty according to the chosen value.
export default class extends Controller {
  static targets = ["cell", "readout"]
  static values = {
    value: Number,
    input: String
  }

  connect() {
    this.repaint()
  }

  select(event) {
    event.preventDefault()
    const cell = event.currentTarget
    const next = parseInt(cell.dataset.value, 10)
    if (Number.isNaN(next)) return
    this.valueValue = next
    const input = this.inputValue ? document.getElementById(this.inputValue) : null
    if (input) {
      input.value = String(next)
      input.dispatchEvent(new Event("input", { bubbles: true }))
      input.dispatchEvent(new Event("change", { bubbles: true }))
    }
    this.repaint()
  }

  repaint() {
    const value = this.valueValue
    this.cellTargets.forEach((cell) => {
      const i = parseInt(cell.dataset.value, 10)
      const filled = i <= value
      const svg = cell.querySelector("svg, i")
      if (filled) {
        cell.style.background = "var(--star-soft)"
        cell.style.borderColor = "var(--star)"
        cell.style.boxShadow = "0 3px 0 var(--star-2)"
      } else {
        cell.style.background = "var(--surface-muted)"
        cell.style.borderColor = "var(--hairline)"
        cell.style.boxShadow = "none"
      }
      if (svg && svg.style) {
        svg.style.color = filled ? "var(--star)" : "var(--text-soft)"
      }
    })
    if (this.hasReadoutTarget) {
      const word = value === 1 ? "estrelinha" : "estrelinhas"
      this.readoutTarget.textContent = `${value} ${word}`
    }
  }
}
