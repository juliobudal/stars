import { Controller } from "@hotwired/stimulus"

const COOLDOWN_MS = 7 * 24 * 60 * 60 * 1000
const KEY = "pwa-ios-hint-dismissed-at"

export default class extends Controller {
  connect() {
    if (!this._shouldShow()) return
    this.element.hidden = false
  }

  dismiss() {
    try {
      localStorage.setItem(KEY, String(Date.now()))
    } catch (_e) {
      // localStorage may be unavailable (private mode); fail silently
    }
    this.element.hidden = true
  }

  _shouldShow() {
    if (this._isDismissed()) return false
    const ua = navigator.userAgent || ""
    const isIos = /iPad|iPhone|iPod/.test(ua) && !window.MSStream
    if (!isIos) return false
    const standaloneByMq =
      window.matchMedia && window.matchMedia("(display-mode: standalone)").matches
    const standaloneByApi = window.navigator.standalone === true
    return !(standaloneByMq || standaloneByApi)
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
}
