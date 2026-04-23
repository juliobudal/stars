// bulk_select_controller.js — enables/disables the bulk-approve submit button
// based on whether any approval checkboxes are checked.

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "submit"]

  connect() {
    this.#updateSubmit()
  }

  change() {
    this.#updateSubmit()
  }

  #updateSubmit() {
    const anyChecked = this.checkboxTargets.some(cb => cb.checked)
    this.submitTargets.forEach(btn => {
      btn.disabled = !anyChecked
      btn.style.opacity = anyChecked ? "1" : ".65"
      btn.style.cursor = anyChecked ? "pointer" : "not-allowed"
    })
  }
}
