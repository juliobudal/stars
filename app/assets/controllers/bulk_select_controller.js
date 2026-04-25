// bulk_select_controller.js — toggles bulk action buttons and submits a
// dynamically-built form on click. Avoids wrapping markup in a <form> so
// row-level button_to forms remain valid (HTML forbids nested forms;
// browsers leak _method=patch from inner forms into the outer submission).

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "submit"]

  connect() {
    this.#updateSubmit()
  }

  change() {
    this.#updateSubmit()
  }

  submit(event) {
    event.preventDefault()
    const url = event.currentTarget.dataset.bulkUrl
    if (!url) return
    const ids = this.checkboxTargets.filter(cb => cb.checked).map(cb => cb.value)
    if (ids.length === 0) return

    const form = document.createElement("form")
    form.method = "POST"
    form.action = url
    form.style.display = "none"

    const tokenMeta = document.querySelector('meta[name="csrf-token"]')
    if (tokenMeta) {
      const tokenInput = document.createElement("input")
      tokenInput.type = "hidden"
      tokenInput.name = "authenticity_token"
      tokenInput.value = tokenMeta.content
      form.appendChild(tokenInput)
    }

    ids.forEach(id => {
      const input = document.createElement("input")
      input.type = "hidden"
      input.name = "approval_ids[]"
      input.value = id
      form.appendChild(input)
    })

    document.body.appendChild(form)
    form.submit()
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
