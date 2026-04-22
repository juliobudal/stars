// ui_modal_controller.js — LittleStars modal logic for custom overlay
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { id: String }

  connect() {
    // Hidden by default in ERB, but we can show it here if needed
    // or keep it visible and let CSS animations handle it.
  }

  open(event) {
    event.preventDefault()
    const id = event.params.id || this.idValue
    const modal = document.getElementById(id)
    if (modal) {
      modal.style.display = "flex"
      document.body.style.overflow = "hidden"
    }
  }

  close(event) {
    if (event) event.preventDefault()
    
    // If controller is on the overlay
    if (this.element.classList.contains("modal-overlay")) {
      this.element.style.display = "none"
    } else {
      // If controller is on a button, find closest overlay
      const overlay = this.element.closest(".modal-overlay")
      if (overlay) overlay.style.display = "none"
    }
    
    document.body.style.overflow = "auto"
  }

  // To close when clicking the overlay but not the modal content
  closeOnOverlay(event) {
    if (event.target === event.currentTarget) {
      this.close()
    }
  }
}
