import { Controller } from "@hotwired/stimulus"

// Controls the "Repetível no período" toggle on the global_task form.
//
// - When the toggle is off, the numeric input is hidden, disabled, and forced to 1.
// - When the toggle is on, the numeric input is visible, enabled, and defaults to 3.
// - The frequency select is observed so the helper label tracks "dia / semana / mês".
// - When frequency changes to "once", the toggle is forced off and disabled.
export default class extends Controller {
  static targets = ["toggle", "input", "field", "helper"]
  static values = { defaultMax: { type: Number, default: 3 } }

  connect() {
    this.syncFromInput()
    this.syncFromFrequency()
    this.observeFrequency()
  }

  toggle() {
    if (this.toggleTarget.checked) {
      this.fieldTarget.classList.remove("hidden")
      this.inputTarget.disabled = false
      if (parseInt(this.inputTarget.value, 10) <= 1) {
        this.inputTarget.value = this.defaultMaxValue
      }
    } else {
      this.fieldTarget.classList.add("hidden")
      this.inputTarget.disabled = false // keep submittable
      this.inputTarget.value = 1
    }
  }

  syncFromInput() {
    const max = parseInt(this.inputTarget.value, 10) || 1
    if (max > 1) {
      this.toggleTarget.checked = true
      this.fieldTarget.classList.remove("hidden")
    } else {
      this.toggleTarget.checked = false
      this.fieldTarget.classList.add("hidden")
    }
  }

  observeFrequency() {
    const radios = document.querySelectorAll('input[name="global_task[frequency]"]')
    radios.forEach((radio) => radio.addEventListener("change", () => this.syncFromFrequency()))
  }

  syncFromFrequency() {
    const selected = document.querySelector('input[name="global_task[frequency]"]:checked')?.value || "daily"
    const labels = { daily: "dia", weekly: "semana", monthly: "mês", once: "" }
    if (this.hasHelperTarget) {
      this.helperTarget.textContent = `Quantas vezes por ${labels[selected] || "dia"}?`
    }
    if (selected === "once") {
      this.toggleTarget.checked = false
      this.toggleTarget.disabled = true
      this.fieldTarget.classList.add("hidden")
      this.inputTarget.value = 1
    } else {
      this.toggleTarget.disabled = false
    }
  }
}
