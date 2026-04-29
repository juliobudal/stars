// ui_modal_controller.js — LittleStars modal logic for custom overlay
import { Controller } from "@hotwired/stimulus"

const FOCUSABLE_SELECTOR = [
  "a[href]",
  "button:not([disabled])",
  "textarea:not([disabled])",
  "input:not([disabled]):not([type='hidden'])",
  "select:not([disabled])",
  "[tabindex]:not([tabindex='-1'])"
].join(",")

// Module-level store so the open() instance (wrapper) and close()/onKeydown()
// instance (overlay) can share the previously-focused element reference.
let _previouslyFocused = null

export default class extends Controller {
  static values = { id: String }

  connect() {}

  disconnect() {
    this._restoreBackgroundInert(false)
  }

  open(event) {
    event.preventDefault()
    const id = event.params.id || this.idValue
    const modal = document.getElementById(id)
    if (!modal) return

    // Teleport to body so position:fixed escapes any scroll container or stacking context
    if (modal.parentElement !== document.body) document.body.appendChild(modal)

    // Ensure the trigger element is focusable so focus() returns to it on close.
    // The wrapper div (#profile_task_N) carries data-controller="ui-modal" and acts
    // as the logical trigger; make it programmatically focusable if it isn't already.
    const trigger = this.element
    if (!trigger.hasAttribute("tabindex")) trigger.setAttribute("tabindex", "-1")
    _previouslyFocused = (document.activeElement && document.activeElement !== document.body)
      ? document.activeElement
      : trigger

    modal.style.display = "flex"
    document.body.style.overflow = "hidden"
    this._restoreBackgroundInert(true, modal)

    requestAnimationFrame(() => {
      const dialog = modal.querySelector('[role="dialog"]') || modal
      const first = dialog.querySelector(FOCUSABLE_SELECTOR) || dialog
      first.focus({ preventScroll: true })
    })
  }

  close(event) {
    if (event) event.preventDefault()

    const overlay = this.element.classList.contains("modal-overlay")
      ? this.element
      : this.element.closest(".modal-overlay")

    if (!overlay) return
    overlay.style.display = "none"
    document.body.style.overflow = "auto"
    this._restoreBackgroundInert(false)

    if (_previouslyFocused && typeof _previouslyFocused.focus === "function") {
      _previouslyFocused.focus({ preventScroll: true })
      _previouslyFocused = null
    }
  }

  // To close when clicking the overlay but not the modal content
  closeOnOverlay(event) {
    if (event.target === event.currentTarget) this.close()
  }

  onKeydown(event) {
    const overlay = this.element.classList.contains("modal-overlay")
      ? this.element
      : this.element.closest(".modal-overlay")
    if (!overlay || overlay.style.display === "none") return

    if (event.key === "Escape") {
      event.preventDefault()
      this.close()
      return
    }

    if (event.key !== "Tab") return

    const dialog = overlay.querySelector('[role="dialog"]') || overlay
    const focusables = Array.from(dialog.querySelectorAll(FOCUSABLE_SELECTOR))
      .filter(el => el.offsetParent !== null)
    if (focusables.length === 0) return

    const first = focusables[0]
    const last = focusables[focusables.length - 1]
    const active = document.activeElement

    if (event.shiftKey && active === first) {
      event.preventDefault()
      last.focus()
    } else if (!event.shiftKey && active === last) {
      event.preventDefault()
      first.focus()
    }
  }

  _restoreBackgroundInert(activate, modal = null) {
    const main = document.querySelector("main, #main, [data-modal-root='main']")
    if (!main) return
    if (activate && modal && main.contains(modal)) return
    if (activate) {
      main.setAttribute("inert", "")
      main.setAttribute("aria-hidden", "true")
    } else {
      main.removeAttribute("inert")
      main.removeAttribute("aria-hidden")
    }
  }
}
