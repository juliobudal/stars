import { Controller } from "@hotwired/stimulus"

// Kid interests picker. Enforces min/max selection on the client.
// Backend re-validates so this is UX, not security.
export default class extends Controller {
  static targets = ["chip", "checkbox", "count"]
  static values = { min: Number, max: Number }

  connect() {
    this.element.addEventListener("change", this.onChange.bind(this))
    this.element.addEventListener("click", this.handleClick.bind(this))
    this.element.addEventListener("focusin", this.handleFocus.bind(this))
    this.element.addEventListener("focusout", this.handleBlur.bind(this))
    this.refresh()
  }

  // Pointer path: the visible chip (label) is the tap target; toggle its
  // hidden checkbox and enforce the cap here.
  handleClick(e) {
    const chip = e.target.closest("[data-interest-picker-target='chip']")
    if (!chip) return
    const cb = chip.querySelector("input[type='checkbox']")
    if (!cb || cb === e.target) return
    e.preventDefault()
    if (!cb.checked && this.selectedCount() >= this.maxValue) {
      this.flashCap()
      return
    }
    cb.checked = !cb.checked
    this.refresh()
  }

  // Keyboard path (Space on the focused checkbox): same cap the pointer path
  // enforces, so a switch/keyboard user can never exceed the max either.
  onChange(e) {
    const cb = e.target.closest("input[type='checkbox']")
    if (!cb) return
    if (cb.checked && this.selectedCount() > this.maxValue) {
      cb.checked = false
      this.flashCap()
      return
    }
    this.refresh()
  }

  flashCap() {
    if (!this.hasCountTarget) return
    this.countTarget.classList.remove("anim-pulse-once")
    void this.countTarget.offsetWidth // restart the pulse
    this.countTarget.classList.add("anim-pulse-once")
    this.countTarget.textContent = `Máximo de ${this.maxValue}! Tire uma pra trocar.`
  }

  // Visible focus ring on the chip while its (hidden) checkbox is keyboard-focused.
  handleFocus(e) {
    const cb = e.target.closest("input[type='checkbox']")
    if (!cb) return
    const chip = cb.closest("[data-interest-picker-target='chip']")
    if (chip && cb.matches(":focus-visible")) {
      chip.style.outline = "2px solid var(--primary)"
      chip.style.outlineOffset = "2px"
    }
  }

  handleBlur(e) {
    const cb = e.target.closest("input[type='checkbox']")
    if (!cb) return
    const chip = cb.closest("[data-interest-picker-target='chip']")
    if (chip) chip.style.outline = "none"
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
      chip.style.background = checked ? "var(--primary-soft)" : "var(--surface-2)"
      chip.style.border = `1px solid ${checked ? "var(--primary)" : "transparent"}`
      chip.style.boxShadow = checked ? "0 4px 0 var(--primary-glow)" : "none"
      chip.style.color = checked ? "var(--primary)" : "var(--text)"
    })
    if (this.hasCountTarget) {
      this.countTarget.textContent = `${count} de ${this.maxValue} escolhidas (mínimo ${this.minValue})`
    }
  }
}
