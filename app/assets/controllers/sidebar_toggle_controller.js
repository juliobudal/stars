import { Controller } from "@hotwired/stimulus"

// Off-canvas parent drawer (mobile). Mirrors the modal a11y contract:
// focus moves in on open, Tab is trapped, Escape closes, focus returns to
// the trigger, and every open/close syncs aria-expanded on the triggers.
export default class extends Controller {
  static targets = ["sidebar", "backdrop"]

  connect() {
    this.onResize = this.onResize.bind(this)
    this.onKeydown = this.onKeydown.bind(this)
    window.addEventListener("resize", this.onResize)
    this.triggers = Array.from(
      this.element.querySelectorAll('[data-action~="click->sidebar-toggle#open"]')
    )
  }

  disconnect() {
    window.removeEventListener("resize", this.onResize)
    window.removeEventListener("keydown", this.onKeydown)
  }

  open(event) {
    this.lastTrigger = (event && event.currentTarget) || this.triggers[0]
    this.sidebarTarget.classList.remove("-translate-x-full")
    this.sidebarTarget.classList.add("translate-x-0")
    this.backdropTarget.classList.remove("hidden")
    this.triggers.forEach((t) => t.setAttribute("aria-expanded", "true"))
    window.addEventListener("keydown", this.onKeydown)
    const first = this.sidebarTarget.querySelector("a[href], button")
    if (first) first.focus()
  }

  close() {
    this.sidebarTarget.classList.remove("translate-x-0")
    this.sidebarTarget.classList.add("-translate-x-full")
    this.backdropTarget.classList.add("hidden")
    this.triggers.forEach((t) => t.setAttribute("aria-expanded", "false"))
    window.removeEventListener("keydown", this.onKeydown)
    if (this.lastTrigger && document.contains(this.lastTrigger)) {
      this.lastTrigger.focus()
      this.lastTrigger = null
    }
  }

  onKeydown(event) {
    if (event.key === "Escape") {
      this.close()
      return
    }
    if (event.key !== "Tab") return
    const focusables = this.sidebarTarget.querySelectorAll(
      'a[href], button:not([disabled]), input:not([disabled]), [tabindex]:not([tabindex="-1"])'
    )
    if (!focusables.length) return
    const first = focusables[0]
    const last = focusables[focusables.length - 1]
    if (event.shiftKey && document.activeElement === first) {
      event.preventDefault()
      last.focus()
    } else if (!event.shiftKey && document.activeElement === last) {
      event.preventDefault()
      first.focus()
    }
  }

  onResize() {
    if (window.innerWidth >= 1024) this.close()
  }
}
