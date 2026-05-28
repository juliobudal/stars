import { Controller } from "@hotwired/stimulus"

// Drives the step-by-step reveal of a lesson ("pílula"):
// enigma → clues → revelation → check → hook. Only one step is visible at a
// time. The check step records the chosen option into a hidden field so the
// completion form submits it.
//
// Targets:
//   step        — each step section (ordered in DOM)
//   choiceInput — hidden input carrying the check answer index
//   option      — check answer buttons
//   feedback    — check feedback container (correct/wrong + explanation)
//   verdictCorrect / verdictWrong — textual+icon verdict lines (color-independent a11y)
//   continue    — the "continue" button on the check step (hidden until answered)
export default class extends Controller {
  static targets = ["step", "choiceInput", "option", "feedback", "continue", "verdictCorrect", "verdictWrong"]

  connect() {
    this.index = 0
    this.show(0)
  }

  next() {
    if (this.index < this.stepTargets.length - 1) {
      this.show(this.index + 1)
    }
  }

  show(i) {
    this.index = i
    this.stepTargets.forEach((step, idx) => {
      step.hidden = idx !== i
    })
    const active = this.stepTargets[i]
    if (active) {
      const focusable = active.querySelector("button, [href], input, [tabindex]")
      if (focusable) focusable.focus({ preventScroll: false })
      active.scrollIntoView({ behavior: this.prefersReducedMotion ? "auto" : "smooth", block: "nearest" })
    }
  }

  answer(event) {
    const btn = event.currentTarget
    const chosen = parseInt(btn.dataset.index, 10)
    const correctIndex = parseInt(this.element.dataset.academyPillCorrectIndex, 10)
    const isCorrect = chosen === correctIndex

    if (this.hasChoiceInputTarget) this.choiceInputTarget.value = chosen

    this.optionTargets.forEach((opt) => {
      const i = parseInt(opt.dataset.index, 10)
      opt.disabled = true
      if (i === correctIndex) {
        opt.dataset.state = "correct"
      } else if (i === chosen) {
        opt.dataset.state = "wrong"
      } else {
        opt.dataset.state = "muted"
      }
    })

    if (this.hasVerdictCorrectTarget) this.verdictCorrectTarget.hidden = !isCorrect
    if (this.hasVerdictWrongTarget) this.verdictWrongTarget.hidden = isCorrect

    if (this.hasFeedbackTarget) {
      this.feedbackTarget.dataset.result = isCorrect ? "correct" : "wrong"
      this.feedbackTarget.hidden = false
    }
    if (this.hasContinueTarget) this.continueTarget.hidden = false
  }

  get prefersReducedMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }
}
