import { Controller } from "@hotwired/stimulus"

// Reveals + enables a dependent fieldset when a controlling radio is chosen.
// The radio carries:
//   data-controls="<fieldset id>"        the field to toggle
//   data-controls-value="<value>"        the radio value that reveals it
//   data-action="change->fields#enable"
// Used by the global-task frequency picker: "Mensal" reveals "Dia do mês".
// Without this, the field stays hidden+disabled and the monthly validation
// bounces a parent for a field they were never shown.
export default class extends Controller {
  enable(event) {
    const input = event.target
    const fieldId = input.dataset.controls
    if (!fieldId) return
    const field = document.getElementById(fieldId)
    if (!field) return
    const show = input.value === input.dataset.controlsValue
    field.classList.toggle("hidden", !show)
    field.disabled = !show // <fieldset disabled> cascades to its inputs
  }
}
