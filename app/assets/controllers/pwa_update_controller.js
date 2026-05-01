import { Controller } from "@hotwired/stimulus"

// Listens for the `pwa:update-available` CustomEvent dispatched by app/assets/entrypoints/pwa.js
// and renders an update toast (markup mounted in kid + parent layouts).
export default class extends Controller {
  connect() {
    this.dismissed = sessionStorage.getItem("pwa-update-dismissed") === "1"
    this.registration = null
    this._onAvailable = (e) => this.show(e.detail && e.detail.registration)
    window.addEventListener("pwa:update-available", this._onAvailable)
  }

  disconnect() {
    window.removeEventListener("pwa:update-available", this._onAvailable)
  }

  show(registration) {
    if (this.dismissed) return
    this.registration = registration
    this.element.hidden = false
  }

  apply() {
    const waiting = this.registration && this.registration.waiting
    if (waiting) {
      waiting.postMessage({ type: "SKIP_WAITING" })
      // pwa.js controllerchange listener handles location.reload()
    } else {
      location.reload()
    }
  }

  dismiss() {
    sessionStorage.setItem("pwa-update-dismissed", "1")
    this.dismissed = true
    this.element.hidden = true
  }
}
