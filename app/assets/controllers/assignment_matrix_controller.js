// assignment_matrix_controller.js — live-saves a mission's child assignments.
// On any checkbox toggle it gathers the whole row's checked children and
// PATCHes them; the server replies with a turbo-stream that re-renders the row
// (so the boxes always reflect committed state). On a 422 (e.g. "needs at
// least one child") the re-render reverts the box and we surface a toast.

import { Controller } from "@hotwired/stimulus"
import { patchTurbo, flashToast } from "./support/live_toggle"

export default class extends Controller {
  static targets = ["toast"]

  async save(event) {
    const checkbox = event.target
    const row = checkbox.closest("[data-assign-row]")
    if (!row) return

    // Drop any lingering "saved" chips from previous toggles.
    this.element.querySelectorAll("[data-saved-chip]").forEach(el => el.remove())

    const url = row.dataset.assignUrl
    const rowId = row.id // assign_row_<missionId>; stable across the re-render
    const value = checkbox.value
    const ids = Array.from(row.querySelectorAll("input[type=checkbox]:checked")).map(c => c.value)
    const body = new URLSearchParams()
    ids.forEach(id => body.append("profile_ids[]", id))

    try {
      const res = await patchTurbo(url, body)
      if (!res.ok) flashToast(this.#toast, "Selecione ao menos uma criança ou pause a missão.")
      this.#restoreFocus(`#${rowId} input[type=checkbox][value="${value}"]`)
    } catch (_e) {
      checkbox.checked = !checkbox.checked // revert optimistic toggle — nothing was saved
      flashToast(this.#toast, "Erro ao salvar. Tente novamente.")
    }
  }

  get #toast() {
    return this.hasToastTarget ? this.toastTarget : null
  }

  // The toggled row is swapped out by the turbo-stream replace, so keyboard
  // focus would fall back to <body>. Re-focus the equivalent checkbox in the
  // freshly-rendered row to keep multi-cell keyboard editing fluid.
  #restoreFocus(selector) {
    const el = document.querySelector(selector)
    if (el) el.focus()
  }
}
