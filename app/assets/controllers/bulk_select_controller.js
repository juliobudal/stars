// bulk_select_controller.js — toggles bulk action buttons and submits a
// dynamically-built form on click. Avoids wrapping markup in a <form> so
// row-level button_to forms remain valid (HTML forbids nested forms;
// browsers leak _method=patch from inner forms into the outer submission).

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "submit", "selectAll", "count"]

  connect() {
    this.#updateSubmit()
  }

  change() {
    this.#syncSelectAll()
    this.#updateSubmit()
  }

  toggleAll(event) {
    const checked = event.currentTarget.checked
    this.checkboxTargets.forEach(cb => { cb.checked = checked })
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
    // requestSubmit (not submit) fires the submit event so Turbo intercepts it
    // and applies the turbo_stream response in place — the active tab/panel is
    // preserved instead of a full-page reload resetting to the default tab.
    form.requestSubmit()
  }

  #updateSubmit() {
    const selected = this.checkboxTargets.filter(cb => cb.checked).length
    const anyChecked = selected > 0
    this.submitTargets.forEach(btn => {
      btn.disabled = !anyChecked
      btn.style.opacity = anyChecked ? "1" : ".65"
      btn.style.cursor = anyChecked ? "pointer" : "not-allowed"
    })
    this.countTargets.forEach(el => {
      el.textContent = anyChecked ? `${selected} selecionado${selected === 1 ? "" : "s"}` : "Selecione para agir em lote"
    })
  }

  #syncSelectAll() {
    if (!this.hasSelectAllTarget) return
    const total = this.checkboxTargets.length
    const checked = this.checkboxTargets.filter(cb => cb.checked).length
    this.selectAllTarget.checked = total > 0 && checked === total
    this.selectAllTarget.indeterminate = checked > 0 && checked < total
  }
}
