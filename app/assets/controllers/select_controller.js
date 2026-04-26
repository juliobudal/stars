import { Controller } from "@hotwired/stimulus"

// Custom Select component
//   - Mirrors selection to a hidden native <select> so forms still submit normally.
//   - Dispatches a real `change` event on the native select after each pick.
//   - Keyboard: Enter/Space toggles, Esc closes, Arrow keys cycle options.
//   - Click-outside closes.
export default class extends Controller {
  static targets = ["native", "trigger", "panel", "option", "label"]

  connect() {
    this.handleDocClick = this.onDocumentClick.bind(this)
    document.addEventListener("click", this.handleDocClick)
  }

  disconnect() {
    document.removeEventListener("click", this.handleDocClick)
  }

  toggle(event) {
    event.preventDefault()
    this.isOpen() ? this.close() : this.open()
  }

  open() {
    this.panelTarget.classList.remove("hidden")
    this.triggerTarget.setAttribute("aria-expanded", "true")
    const active = this.optionTargets.find(o => o.getAttribute("aria-selected") === "true") || this.optionTargets[0]
    if (active) active.focus({ preventScroll: true })
  }

  close() {
    this.panelTarget.classList.add("hidden")
    this.triggerTarget.setAttribute("aria-expanded", "false")
  }

  isOpen() {
    return !this.panelTarget.classList.contains("hidden")
  }

  choose(event) {
    event.preventDefault()
    const value = event.currentTarget.dataset.selectValue
    const label = event.currentTarget.querySelector("span")?.textContent ?? value
    this.applyValue(value, label)
    this.close()
    this.triggerTarget.focus({ preventScroll: true })
  }

  applyValue(value, label) {
    this.nativeTarget.value = value
    this.labelTarget.textContent = label
    this.optionTargets.forEach(o => {
      const match = o.dataset.selectValue === value
      o.setAttribute("aria-selected", match ? "true" : "false")
      o.classList.toggle("bg-primary-soft", match)
      o.classList.toggle("text-primary", match)
      o.classList.toggle("text-foreground", !match)
    })
    this.nativeTarget.dispatchEvent(new Event("change", { bubbles: true }))
    this.nativeTarget.dispatchEvent(new Event("input", { bubbles: true }))
  }

  onKeydown(event) {
    const k = event.key
    if (k === "Enter" || k === " " || k === "ArrowDown") {
      event.preventDefault()
      if (!this.isOpen()) this.open()
      return
    }
    if (k === "Escape") {
      event.preventDefault()
      this.close()
    }
  }

  onDocumentClick(event) {
    if (!this.isOpen()) return
    if (this.element.contains(event.target)) return
    this.close()
  }
}
