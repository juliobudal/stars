import { Controller } from "@hotwired/stimulus"

// Kid interests picker. Enforces min/max selection on the client.
// Backend re-validates so this is UX, not security.
export default class extends Controller {
  static targets = ["chip", "checkbox", "count"]
  static values = { min: Number, max: Number }

  connect() {
    this.element.addEventListener("change", this.refresh.bind(this))
    this.element.addEventListener("click", this.handleClick.bind(this))
    this.refresh()
  }

  handleClick(e) {
    const chip = e.target.closest("[data-interest-picker-target='chip']")
    if (!chip) return
    const cb = chip.querySelector("input[type='checkbox']")
    if (!cb || cb === e.target) return
    e.preventDefault()
    if (!cb.checked && this.selectedCount() >= this.maxValue) return
    cb.checked = !cb.checked
    this.refresh()
  }

  selectedCount() {
    return this.checkboxTargets.filter((c) => c.checked).length
  }

  refresh() {
    const count = this.selectedCount()
    this.chipTargets.forEach((chip) => {
      const cb = chip.querySelector("input[type='checkbox']")
      const checked = !!cb && cb.checked
      chip.dataset.checked = checked
      chip.style.background = checked ? "var(--primary-soft)" : "var(--surface-2, #F7F7F7)"
      chip.style.border = `2px solid ${checked ? "var(--primary)" : "transparent"}`
      chip.style.boxShadow = checked ? "0 4px 0 var(--primary-glow, rgba(0,0,0,0.08))" : "none"
      chip.style.color = checked ? "var(--primary)" : "var(--text)"
    })
    if (this.hasCountTarget) {
      this.countTarget.textContent = `${count} escolhidas. Mínimo ${this.minValue}, máximo ${this.maxValue}`
    }
  }
}
