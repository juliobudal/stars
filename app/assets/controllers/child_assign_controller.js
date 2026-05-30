// child_assign_controller.js — on the per-child management panel, toggles a
// single mission on/off for that child. The server reconciles the mission's
// full assignment set (so siblings keep theirs) and replies with a turbo-stream
// that re-renders the row, reflecting committed state. A 422 (e.g. removing the
// child would leave the mission with nobody) reverts the row and shows a toast.

import { Controller } from "@hotwired/stimulus"
import { patchTurbo, flashToast } from "./support/live_toggle"

export default class extends Controller {
  static targets = ["toast"]

  async toggle(event) {
    const checkbox = event.target
    const url = checkbox.dataset.url
    if (!url) return

    const rowId = checkbox.closest("[id^='manage_mission_']")?.id
    const body = new URLSearchParams({ mission_id: checkbox.value, assigned: checkbox.checked })
    try {
      const res = await patchTurbo(url, body)
      if (!res.ok) flashToast(this.#toast, "Uma missão precisa de ao menos uma criança. Pause-a no catálogo.", 3000)
      // The row is swapped out by the replace; restore keyboard focus to it.
      if (rowId) document.getElementById(rowId)?.querySelector("input[type=checkbox]")?.focus()
    } catch (_e) {
      checkbox.checked = !checkbox.checked // revert optimistic toggle — nothing was saved
      flashToast(this.#toast, "Erro ao salvar. Tente novamente.", 3000)
    }
  }

  get #toast() {
    return this.hasToastTarget ? this.toastTarget : null
  }
}
