import { Controller } from "@hotwired/stimulus"

// Lens stage interaction controller.
// Drives all 8 lens primitives by manipulating hidden form fields the
// missions#advance controller consumes via params[:signal_payload].
export default class extends Controller {
  static targets = [
    "form", "advanceBtn",
    "microCheck", "affectiveTap", "predictValue", "choices", "elapsed",
    "microCheckBlock", "microCheckRationale",
    "mascotReactionCorrect", "mascotReactionWrong",
    "predictSlider", "predictDisplay", "predictReveal", "predictRevealBtn", "predictReaction",
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
    this._audioCtx = null
    this._fxOverlay = null
  }

  disconnect() {
    if (this._timerId) clearInterval(this._timerId)
    if (this._fxOverlay && this._fxOverlay.parentElement) this._fxOverlay.remove()
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

    // QW1: explosive feedback — sound, haptic, confetti + XP, card pulse
    this._playChime(correct)
    this._haptic(correct ? 12 : 35)
    this._pulseCard(block, correct)
    if (correct) this._burstFx(btn)

    // Reveal rationale (scoped to nearest block)
    const rationale = block.querySelector("[data-lens-stage-target='microCheckRationale']")
    if (rationale) rationale.hidden = false

    // QW5: surface the owl mascot reaction matching the answer. Scope to
    // the block so narrative + scientific micro_checks don't cross-pollinate.
    const mascotEl = block.querySelector(
      correct
        ? "[data-lens-stage-target='mascotReactionCorrect']"
        : "[data-lens-stage-target='mascotReactionWrong']"
    )
    if (mascotEl) mascotEl.hidden = false

    this.element.dispatchEvent(new CustomEvent("lens:micro-check-answered", {
      bubbles: true, detail: { correct }
    }))
  }

  // ── Feedback FX helpers (QW1) ───────────────────────────────────
  _audioContext() {
    if (this._audioCtx) return this._audioCtx
    const Ctor = window.AudioContext || window.webkitAudioContext
    if (!Ctor) return null
    try { this._audioCtx = new Ctor() } catch (e) { return null }
    return this._audioCtx
  }

  _playChime(correct) {
    if (this.reducedMotion) return
    const ctx = this._audioContext()
    if (!ctx) return
    if (ctx.state === "suspended") { try { ctx.resume() } catch (e) {} }
    try {
      const now = ctx.currentTime
      const osc = ctx.createOscillator()
      const gain = ctx.createGain()
      osc.connect(gain); gain.connect(ctx.destination)
      if (correct) {
        osc.type = "triangle"
        osc.frequency.setValueAtTime(660, now)
        osc.frequency.exponentialRampToValueAtTime(990, now + 0.13)
      } else {
        osc.type = "square"
        osc.frequency.setValueAtTime(220, now)
        osc.frequency.exponentialRampToValueAtTime(150, now + 0.18)
      }
      gain.gain.setValueAtTime(0.0001, now)
      gain.gain.exponentialRampToValueAtTime(correct ? 0.16 : 0.13, now + 0.02)
      gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.22)
      osc.start(now); osc.stop(now + 0.24)
    } catch (e) { /* swallow audio errors silently */ }
  }

  _haptic(ms) {
    if (this.reducedMotion) return
    if (!navigator.vibrate) return
    try { navigator.vibrate(ms) } catch (e) {}
  }

  _pulseCard(block, correct) {
    if (this.reducedMotion) return
    const card = (block && block.classList.contains("lens-card") ? block : null) ||
                 (block && block.closest(".lens-card")) ||
                 this.element.querySelector(".lens-card")
    if (!card) return
    const cls = correct ? "lens-fx-card-pulse-correct" : "lens-fx-card-pulse-wrong"
    card.classList.remove(cls)
    // Force reflow so the class re-add restarts the animation.
    void card.offsetWidth
    card.classList.add(cls)
    setTimeout(() => card.classList.remove(cls), 720)
  }

  _burstFx(anchor) {
    if (this.reducedMotion) return
    const rect = anchor.getBoundingClientRect()
    if (!rect.width || !rect.height) return
    const cx = rect.left + rect.width / 2
    const cy = rect.top + rect.height / 2

    const overlay = document.createElement("div")
    overlay.className = "lens-fx-overlay"
    overlay.style.position = "fixed"
    overlay.style.left = `${cx}px`
    overlay.style.top = `${cy}px`
    overlay.style.width = "0"
    overlay.style.height = "0"
    overlay.setAttribute("aria-hidden", "true")
    document.body.appendChild(overlay)
    this._fxOverlay = overlay

    const colors = this._brandConfettiColors()
    const N = 16
    for (let i = 0; i < N; i++) {
      const piece = document.createElement("span")
      piece.className = "lens-fx-confetti"
      const angle = (i / N) * Math.PI * 2 + (Math.random() - 0.5) * 0.5
      const dist = 60 + Math.random() * 70
      const dx = Math.cos(angle) * dist
      const dy = Math.sin(angle) * dist - 20 // bias upward
      piece.style.setProperty("--fx-dx", `calc(-50% + ${dx.toFixed(1)}px)`)
      piece.style.setProperty("--fx-dy", `calc(-50% + ${dy.toFixed(1)}px)`)
      piece.style.setProperty("--fx-rot", `${(Math.random() * 720 - 360).toFixed(0)}deg`)
      piece.style.background = colors[i % colors.length]
      piece.style.animationDelay = `${Math.floor(Math.random() * 80)}ms`
      overlay.appendChild(piece)
    }

    const xp = document.createElement("div")
    xp.className = "lens-fx-xp"
    xp.textContent = "+10 XP"
    overlay.appendChild(xp)

    setTimeout(() => {
      if (overlay.parentElement) overlay.remove()
      if (this._fxOverlay === overlay) this._fxOverlay = null
    }, 1300)
  }

  // Reads brand accent tokens off the controller element so per-kid palettes
  // (data-palette) cascade naturally. Falls back to documentElement.
  _brandConfettiColors() {
    const root = this.element || document.documentElement
    const styles = getComputedStyle(root)
    return ["--primary", "--star", "--c-sky", "--c-lilac", "--c-coral"]
      .map((name) => styles.getPropertyValue(name).trim())
      .filter(Boolean)
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

  revealPredict(event) {
    if (this.hasPredictSliderTarget && this.hasPredictValueTarget) {
      this.predictValueTarget.value = this.predictSliderTarget.value
    }
    if (this.hasPredictRevealTarget) this.predictRevealTarget.hidden = false

    // QW2: humorous reaction proportional to the miss.
    const btn = event && event.currentTarget
    if (btn && this.hasPredictSliderTarget && this.hasPredictReactionTarget) {
      const guess = parseFloat(this.predictSliderTarget.value)
      const real = parseFloat(btn.dataset.lensStageRealParam)
      const rmin = parseFloat(btn.dataset.lensStageRminParam ?? "0")
      const rmax = parseFloat(btn.dataset.lensStageRmaxParam ?? "100")
      if (!Number.isNaN(guess) && !Number.isNaN(real)) {
        const r = this._computePredictReaction({ guess, real, rmin, rmax })
        this._renderPredictReaction(this.predictReactionTarget, r)
        this.predictReactionTarget.hidden = false
        // Subtle audio cue on reveal (correct-ish, regardless of accuracy)
        this._playChime(r.tier === "bullseye" || r.tier === "close")
        if (r.tier === "bullseye") {
          this._haptic(15)
          this._burstFx(btn)
        } else if (r.tier === "astronomical" || r.tier === "way_off") {
          this._haptic(25)
        }
      }
    }

    if (this.hasPredictRevealBtnTarget) {
      this.predictRevealBtnTarget.disabled = true
      this.predictRevealBtnTarget.style.opacity = "0.55"
    }
    if (this.hasPredictSliderTarget) this.predictSliderTarget.disabled = true
    this._unlockAdvance()
  }

  // ── Predict reaction (QW2) — mirror of Academy::Lens::PredictReaction ──
  _computePredictReaction({ guess, real, rmin, rmax }) {
    const absDelta = Math.abs(guess - real)
    const range = Math.max(Math.abs(rmax - rmin), 1e-6)
    const pct = absDelta / range

    let tier
    if (absDelta < 0.5)      tier = "bullseye"
    else if (pct <= 0.02)    tier = "bullseye"
    else if (pct <= 0.05)    tier = "close"
    else if (pct <= 0.20)    tier = "off"
    else if (pct <= 0.50)    tier = "way_off"
    else                     tier = "astronomical"

    let mult = null
    if (Math.abs(real) > 0.0001 && Math.abs(guess) > 0.0001) {
      const m = Math.abs(guess) / Math.abs(real)
      mult = m >= 1 ? m : 1 / m
    }
    const dir = guess > real ? "a mais" : "a menos"
    const multTxt = mult ? `${Math.round(mult)}× ${dir}` : null

    const COPY = {
      bullseye: {
        emoji: "🎯",
        headline: "Cravou!",
        detail: "Você é mais calibrado que a maioria dos adultos nessa."
      },
      close: {
        emoji: "👀",
        headline: "Quase no ponto.",
        detail: "Sua intuição tava afinada — esses números são difíceis de chutar."
      },
      off: {
        emoji: "🤏",
        headline: "Foi por pouco.",
        detail: multTxt && mult >= 2
          ? `Errou por uns ${multTxt}. Dá pra calibrar com prática.`
          : "Errou por margem pequena. Dá pra calibrar com prática."
      },
      way_off: {
        emoji: "😅",
        headline: "Errou pela ordem de grandeza.",
        detail: multTxt
          ? `Você apostou cerca de ${multTxt} do real. Esse erro é exatamente o que essa lente revela.`
          : "Errou por margem larga. Esse erro é exatamente o que essa lente revela."
      },
      astronomical: {
        emoji: "🤯",
        headline: "Pirou!",
        detail: multTxt
          ? `Você apostou ${multTxt} do real. O mundo é mais raro (ou mais comum) do que parece.`
          : "A intuição te traiu feio aqui — o mundo nem sempre se comporta como a gente imagina."
      }
    }
    return { tier, ...COPY[tier] }
  }

  _renderPredictReaction(target, r) {
    const wrap = document.createElement("div")
    wrap.className = "rounded-2xl px-3 py-3 mt-3 flex items-start gap-3"
    wrap.style.background = "var(--surface-2)"
    wrap.style.border = "2px solid var(--hairline)"

    const emoji = document.createElement("span")
    emoji.setAttribute("aria-hidden", "true")
    emoji.style.fontSize = "28px"
    emoji.style.lineHeight = "1"
    emoji.textContent = r.emoji
    wrap.appendChild(emoji)

    const col = document.createElement("div")
    col.className = "flex-1 min-w-0"
    const head = document.createElement("div")
    head.className = "font-display text-[14px] font-extrabold leading-tight"
    head.style.color = "var(--text)"
    head.textContent = r.headline
    const det = document.createElement("p")
    det.className = "font-display text-[12px] leading-snug mt-1 m-0"
    det.style.color = "var(--text-muted)"
    det.textContent = r.detail
    col.appendChild(head); col.appendChild(det)
    wrap.appendChild(col)

    target.replaceChildren(wrap)
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
