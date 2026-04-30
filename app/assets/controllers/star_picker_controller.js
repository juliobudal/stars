import { Controller } from "@hotwired/stimulus"

// Visual 1–10 star difficulty selector + free-form numeric input.
// Picker repaints visually for 1..10. Custom input accepts 1..999 and
// drives the hidden form field. Picker click syncs the custom input.
export default class extends Controller {
  static targets = ["cell", "readout", "custom", "hidden"]
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
    this.applyValue(next)
  }

  typeCustom(event) {
    const raw = parseInt(event.target.value, 10)
    if (Number.isNaN(raw)) return
    const next = Math.min(Math.max(raw, 1), 999)
    this.valueValue = next
    this.writeHidden(next)
    this.repaintCells()
    this.repaintReadout()
  }

  applyValue(next) {
    const clamped = Math.min(Math.max(next, 1), 999)
    this.valueValue = clamped
    this.writeHidden(clamped)
    if (this.hasCustomTarget) this.customTarget.value = String(clamped)
    this.repaint()
  }

  writeHidden(value) {
    const input = this.hasHiddenTarget
      ? this.hiddenTarget
      : (this.inputValue ? document.getElementById(this.inputValue) : null)
    if (!input) return
    input.value = String(value)
    input.dispatchEvent(new Event("input", { bubbles: true }))
    input.dispatchEvent(new Event("change", { bubbles: true }))
  }

  repaint() {
    this.repaintCells()
    this.repaintReadout()
  }

  repaintCells() {
    const visualValue = Math.min(this.valueValue, 10)
    this.cellTargets.forEach((cell) => {
      const i = parseInt(cell.dataset.value, 10)
      const filled = i <= visualValue
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
  }

  repaintReadout() {
    if (!this.hasReadoutTarget) return
    const word = this.valueValue === 1 ? "estrelinha" : "estrelinhas"
    this.readoutTarget.textContent = word
  }
}
