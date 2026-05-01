import { Controller } from "@hotwired/stimulus"

const COOLDOWN_MS = 7 * 24 * 60 * 60 * 1000
const KEY = "pwa-install-dismissed-at"

export default class extends Controller {
  static targets = ["installButton", "dismissButton"]

  connect() {
    if (this._isStandalone() || this._isDismissed()) return

    this.deferredPrompt = null
    this._onBeforeInstall = (e) => this._capture(e)
    this._onInstalled = () => { this.element.hidden = true }

    window.addEventListener("beforeinstallprompt", this._onBeforeInstall)
    window.addEventListener("appinstalled", this._onInstalled)
  }

  disconnect() {
    window.removeEventListener("beforeinstallprompt", this._onBeforeInstall)
    window.removeEventListener("appinstalled", this._onInstalled)
  }

  _capture(event) {
    event.preventDefault()
    this.deferredPrompt = event
    this.element.hidden = false
  }

  async install() {
    if (!this.deferredPrompt) { this.element.hidden = true; return }
    this.deferredPrompt.prompt()
    try {
      const { outcome } = await this.deferredPrompt.userChoice
      console.info("[pwa] install outcome:", outcome)
    } catch (err) {
      console.warn("[pwa] install error:", err)
    } finally {
      this.deferredPrompt = null
      this.element.hidden = true
    }
  }

  dismiss() {
    try {
      localStorage.setItem(KEY, String(Date.now()))
    } catch (_e) {
      // localStorage may be unavailable (private mode); fail silently
    }
    this.element.hidden = true
  }

  _isDismissed() {
    let raw = "0"
    try {
      raw = localStorage.getItem(KEY) || "0"
    } catch (_e) {
      return false
    }
    const at = parseInt(raw, 10)
    return at > 0 && (Date.now() - at) < COOLDOWN_MS
  }

  _isStandalone() {
    return (
      window.matchMedia && window.matchMedia("(display-mode: standalone)").matches
    ) || window.navigator.standalone === true
  }
}
