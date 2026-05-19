import { Controller } from "@hotwired/stimulus"

/**
 * Pokédex evolution flash — Academy v4.
 *
 * Reacts to `academy:concept-evolved` window events emitted via Turbo Stream
 * broadcasts when Academy::Pokedex::Advance raises a concept's level.
 * Briefly highlights the chip and plays a short sound (WebAudio, no extra
 * dependency). Honors `prefers-reduced-motion`.
 */
export default class extends Controller {
  static values = {
    soundEnabled: { type: Boolean, default: true }
  }

  flash(event) {
    const { conceptSlug, level } = event.detail || {}
    if (!conceptSlug) return

    const chip = this.element.querySelector(`[data-concept-slug="${conceptSlug}"]`)
    if (!chip) return

    // Update visual state inline so the animation lands on the new level.
    chip.dataset.level = level
    chip.classList.remove(
      "pokedex-chip--silhouette",
      "pokedex-chip--spotted",
      "pokedex-chip--recognized",
      "pokedex-chip--mastered"
    )
    chip.classList.add(this.#stateClass(level))
    chip.classList.add("pokedex-chip--evolving-now")

    const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    if (!reduceMotion) {
      this.#scrollIntoSight(chip)
      this.#playEvolutionSound(level)
    }

    setTimeout(() => chip.classList.remove("pokedex-chip--evolving-now"), 3000)
  }

  #stateClass(level) {
    if (level >= 3) return "pokedex-chip--mastered"
    if (level === 2) return "pokedex-chip--recognized"
    if (level === 1) return "pokedex-chip--spotted"
    return "pokedex-chip--silhouette"
  }

  #scrollIntoSight(node) {
    const rect = node.getBoundingClientRect()
    const inView = rect.top >= 0 && rect.bottom <= window.innerHeight
    if (!inView) node.scrollIntoView({ behavior: "smooth", block: "center" })
  }

  // Tiny chime via WebAudio — no external sample needed.
  #playEvolutionSound(level) {
    if (!this.soundEnabledValue) return
    if (typeof window.AudioContext === "undefined") return

    const ctx = new (window.AudioContext || window.webkitAudioContext)()
    const now = ctx.currentTime
    const tones = level >= 3 ? [660, 880, 1100] : [550, 740]
    const gain = ctx.createGain()
    gain.connect(ctx.destination)
    gain.gain.setValueAtTime(0.0001, now)
    gain.gain.exponentialRampToValueAtTime(0.06, now + 0.04)
    gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.6)

    tones.forEach((freq, idx) => {
      const osc = ctx.createOscillator()
      osc.type = "sine"
      osc.frequency.setValueAtTime(freq, now + idx * 0.12)
      osc.connect(gain)
      osc.start(now + idx * 0.12)
      osc.stop(now + idx * 0.12 + 0.18)
    })
  }
}
