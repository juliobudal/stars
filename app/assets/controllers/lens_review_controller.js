import { Controller } from "@hotwired/stimulus"

// Lens review mode — disables interactivity on the embedded lens primitive
// and reveals all hidden answer/rationale sections so the kid can browse
// the content statically. The original lens_stage controller is still
// attached (to keep ERB partials happy) but its actions become no-ops
// because all buttons are disabled and forms are absent on this page.
export default class extends Controller {
  connect() {
    // 1. Disable every interactive control inside the review wrapper.
    this.element.querySelectorAll("button, input, select, textarea")
      .forEach((el) => { el.disabled = true })

    // 2. Reveal every section the kid would have unlocked by interacting.
    //    Targets used across primitives:
    //      [hidden], [data-lens-stage-target='microCheckRationale'],
    //      [data-lens-stage-target='predictReveal'],
    //      [data-lens-stage-target='compareReveal'],
    //      [data-lens-stage-target='embodiedReveal'],
    //      [data-lens-stage-target='engineeringReveal'],
    //      .lens-narrative-scene--locked
    this.element.querySelectorAll("[hidden]").forEach((el) => { el.hidden = false })
    this.element.querySelectorAll(".lens-narrative-scene--locked")
      .forEach((el) => el.classList.remove("lens-narrative-scene--locked"))
  }
}
