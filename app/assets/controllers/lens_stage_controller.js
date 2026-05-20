import { Controller } from "@hotwired/stimulus"

// Lens stage interaction controller.
// Drives all 8 lens primitives by manipulating hidden form fields the
// missions#advance controller consumes via params[:signal_payload].
export default class extends Controller {
  static targets = [
    "form", "advanceBtn",
    "microCheck", "affectiveTap", "predictValue", "choices", "elapsed",
    "microCheckBlock", "microCheckRationale",
    "predictSlider", "predictDisplay", "predictReveal", "predictRevealBtn",
    "compareGrid", "compareCard", "compareReveal",
    "narrativeScenes", "advanceSceneBtn", "narrativeMicroCheck", "narrativeFinal",
    "timerDisplay", "startTimerBtn", "stopTimerBtn", "embodiedReveal",
    "engineeringList", "engineeringCount", "engineeringReveal", "engineeringRevealText"
  ]

  static values = {
    lensType: String,
    duration: Number,
    mustPick: Number,
    outcomes: Object
  }

  connect() {
    this.reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this._choices = []
    this._picked = []
    this._timerId = null
    this._timerStart = null
  }

  disconnect() {
    if (this._timerId) clearInterval(this._timerId)
  }

  // ── Shared: micro_check ─────────────────────────────────────────
  recordMicroCheck(event) {
    const btn = event.currentTarget
    const correct = btn.dataset.lensStageCorrectParam === "true"
    if (this.hasMicroCheckTarget) this.microCheckTarget.value = correct ? "true" : "false"

    // Highlight buttons in the same block
    const block = btn.closest("[data-lens-stage-target='microCheckBlock']") || this.element
    block.querySelectorAll(".lens-option-btn").forEach(b => {
      b.classList.remove("lens-option-btn--selected", "lens-option-btn--correct", "lens-option-btn--wrong")
      b.disabled = true
    })
    btn.classList.add(correct ? "lens-option-btn--correct" : "lens-option-btn--wrong")

    // Reveal rationale (scoped to nearest block)
    const rationale = block.querySelector("[data-lens-stage-target='microCheckRationale']")
    if (rationale) rationale.hidden = false
  }

  // ── Compare cases (ethical) ─────────────────────────────────────
  recordCompareChoice(event) {
    const card = event.currentTarget
    const choice = card.dataset.lensStageChoiceParam
    if (this.hasAffectiveTapTarget) this.affectiveTapTarget.value = choice

    this.compareCardTargets.forEach(c => {
      c.classList.remove("lens-compare-card--selected")
      c.disabled = true
    })
    card.classList.add("lens-compare-card--selected")
    if (this.hasCompareRevealTarget) this.compareRevealTarget.hidden = false
  }

  // ── Predict slider (statistical) ────────────────────────────────
  updatePredictDisplay(event) {
    if (!this.hasPredictDisplayTarget) return
    const slider = event.currentTarget
    const unit = slider.dataset.lensStageUnitParam || ""
    const value = slider.value
    this.predictDisplayTarget.innerHTML =
      `${value}<span class="text-[14px] ml-1" style="color: var(--text-muted);">${unit}</span>`
  }

  revealPredict() {
    if (this.hasPredictSliderTarget && this.hasPredictValueTarget) {
      this.predictValueTarget.value = this.predictSliderTarget.value
    }
    if (this.hasPredictRevealTarget) this.predictRevealTarget.hidden = false
    if (this.hasPredictRevealBtnTarget) {
      this.predictRevealBtnTarget.disabled = true
      this.predictRevealBtnTarget.style.opacity = "0.55"
    }
    if (this.hasPredictSliderTarget) this.predictSliderTarget.disabled = true
    this._unlockAdvance()
  }

  _unlockAdvance() {
    if (!this.hasAdvanceBtnTarget) return
    this.advanceBtnTarget.disabled = false
    this.advanceBtnTarget.style.opacity = ""
    this.advanceBtnTarget.style.cursor = ""
  }

  // ── Narrative (card stack) ──────────────────────────────────────
  recordNarrativeChoice(event) {
    const btn = event.currentTarget
    const label = btn.dataset.lensStageLabelParam
    const scene = btn.dataset.lensStageSceneParam
    this._choices.push({ scene, label })
    if (this.hasChoicesTarget) this.choicesTarget.value = JSON.stringify(this._choices)

    // Highlight and disable siblings
    const parent = btn.parentElement
    if (parent) {
      parent.querySelectorAll(".lens-option-btn").forEach(b => {
        b.classList.remove("lens-option-btn--selected")
        b.disabled = true
      })
    }
    btn.classList.add("lens-option-btn--selected")
  }

  advanceScene() {
    if (!this.hasNarrativeScenesTarget) return
    const scenes = this.narrativeScenesTarget.querySelectorAll(".lens-narrative-scene")
    let unlocked = null
    for (const s of scenes) {
      if (s.classList.contains("lens-narrative-scene--locked")) { unlocked = s; break }
    }
    if (unlocked) {
      unlocked.classList.remove("lens-narrative-scene--locked")
      if (!this.reducedMotion) unlocked.classList.add("anim-fade-up")
      unlocked.scrollIntoView({ behavior: this.reducedMotion ? "auto" : "smooth", block: "center" })
    }

    const stillLocked = Array.from(scenes).some(s => s.classList.contains("lens-narrative-scene--locked"))
    if (!stillLocked) {
      if (this.hasAdvanceSceneBtnTarget) {
        this.advanceSceneBtnTarget.disabled = true
        this.advanceSceneBtnTarget.style.opacity = "0.5"
      }
      if (this.hasNarrativeMicroCheckTarget) {
        const mc = this.narrativeMicroCheckTarget
        mc.classList.remove("lens-narrative-micro-check--locked")
        mc.setAttribute("aria-hidden", "false")
        if (!this.reducedMotion) mc.classList.add("anim-fade-up")
      }
    }
  }

  // ── Embodied (first_person) timer ───────────────────────────────
  startTimer() {
    if (this._timerId) return
    const duration = this.hasDurationValue ? this.durationValue : 30
    this._remaining = duration
    this._timerStart = Date.now()

    if (this.hasStartTimerBtnTarget) {
      this.startTimerBtnTarget.disabled = true
      this.startTimerBtnTarget.style.opacity = "0.55"
    }
    if (this.hasStopTimerBtnTarget) this.stopTimerBtnTarget.disabled = false

    this._tick()
    this._timerId = setInterval(() => this._tick(), 1000)
  }

  _tick() {
    if (!this.hasTimerDisplayTarget) return
    const elapsed = Math.floor((Date.now() - this._timerStart) / 1000)
    const duration = this.hasDurationValue ? this.durationValue : 30
    const remaining = Math.max(0, duration - elapsed)
    this.timerDisplayTarget.textContent = `${remaining}s`
    if (remaining <= 0) {
      clearInterval(this._timerId)
      this._timerId = null
      this._autoReveal()
    }
  }

  stopTimer() {
    if (this._timerId) {
      clearInterval(this._timerId)
      this._timerId = null
    }
    this._autoReveal()
  }

  _autoReveal() {
    if (this.hasEmbodiedRevealTarget) this.embodiedRevealTarget.hidden = false
    if (this.hasStopTimerBtnTarget) this.stopTimerBtnTarget.disabled = true
    if (this._timerStart && this.hasElapsedTarget) {
      const seconds = Math.floor((Date.now() - this._timerStart) / 1000)
      this.elapsedTarget.value = String(seconds)
    }
  }

  // ── Engineering (drag-list lite) ────────────────────────────────
  pickConstraint(event) {
    const btn = event.currentTarget
    const id = btn.dataset.lensStageIdParam
    const must = this.hasMustPickValue ? this.mustPickValue : 3

    const isSelected = btn.classList.contains("lens-engineering-chip--selected")
    if (isSelected) {
      btn.classList.remove("lens-engineering-chip--selected")
      this._picked = this._picked.filter(x => x !== id)
    } else {
      if (this._picked.length >= must) return
      btn.classList.add("lens-engineering-chip--selected")
      this._picked.push(id)
    }

    if (this.hasEngineeringCountTarget) {
      this.engineeringCountTarget.textContent = String(this._picked.length)
    }

    // Persist into choices payload for completeness
    if (this.hasChoicesTarget) {
      this.choicesTarget.value = JSON.stringify({ picked: this._picked })
    }

    if (this._picked.length === must) {
      this._revealEngineeringOutcome()
    } else if (this.hasEngineeringRevealTarget) {
      this.engineeringRevealTarget.hidden = true
    }
  }

  _revealEngineeringOutcome() {
    const outcomes = this.hasOutcomesValue ? this.outcomesValue : {}
    const sorted = [...this._picked].sort()
    const key = sorted.join("+")
    let text = outcomes[key]

    if (!text) {
      // Fallback: try any permutation order matching
      const target = new Set(sorted)
      for (const k of Object.keys(outcomes)) {
        const parts = k.split("+").sort()
        if (parts.length === sorted.length && parts.every((p, i) => p === sorted[i])) {
          text = outcomes[k]; break
        }
        // loose match: same set ignoring order
        if (new Set(k.split("+")).size === target.size &&
            [...new Set(k.split("+"))].every(p => target.has(p))) {
          text = outcomes[k]; break
        }
      }
    }

    if (!text) text = "Cada escolha tem um preço. Pense: o que você deixou de fora?"
    if (this.hasEngineeringRevealTextTarget) this.engineeringRevealTextTarget.textContent = text
    if (this.hasEngineeringRevealTarget) this.engineeringRevealTarget.hidden = false
  }
}
