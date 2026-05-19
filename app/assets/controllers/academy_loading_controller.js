import { Controller } from "@hotwired/stimulus"

// Full-viewport loading overlay for the Academy.
//
// Two entry points:
// 1. `show` / `hide` — lens form submission (mid-mission "advance"). Driven
//    by `turbo:submit-start` / `turbo:submit-end` on the lens form.
// 2. `showLesson` — click on a lesson link, before Turbo navigates to
//    `missions#show` (which runs `Academy::Missions::Begin` + an LLM call
//    that can take 5–30s on a cold start).
//
// The overlay lives in the kid layout so a single instance covers every
// page. Stimulus action descriptors find this controller on the <body>.
export default class extends Controller {
  static targets = ["overlay", "message"]
  static values = {
    messages: { type: Array, default: [
      "O Guia está pensando…",
      "Lendo o que você revelou…",
      "Costurando a próxima lente…",
      "Escolhendo as perguntas certas…",
      "Quase lá…"
    ]},
    lessonMessages: { type: Array, default: [
      "O Guia está observando suas estrelas…",
      "Lendo o caminho que você já trilhou…",
      "Escolhendo a primeira lente desta aula…",
      "Preparando perguntas só suas…",
      "Conectando ideias e descobertas…",
      "Acendendo o segredo desta aula…"
    ]},
    rotateMs: { type: Number, default: 2800 }
  }

  connect() {
    this._timer = null
    this._idx = 0
    this._activeMessages = this.messagesValue
    this._reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches

    document.documentElement.style.overflow = ""
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.add("hidden")
      this.overlayTarget.setAttribute("aria-hidden", "true")
    }

    this._forceHide = this._forceHide.bind(this)
    document.addEventListener("turbo:before-cache", this._forceHide)
    document.addEventListener("turbo:before-render", this._forceHide)
    document.addEventListener("turbo:load", this._forceHide)
  }

  disconnect() {
    this._stopRotation()
    document.documentElement.style.overflow = ""
    document.removeEventListener("turbo:before-cache", this._forceHide)
    document.removeEventListener("turbo:before-render", this._forceHide)
    document.removeEventListener("turbo:load", this._forceHide)
  }

  _forceHide() {
    document.documentElement.style.overflow = ""
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.add("hidden")
      this.overlayTarget.setAttribute("aria-hidden", "true")
    }
    this._stopRotation()
    this._stopFailsafe()
  }

  // Triggered by the lens form's turbo:submit-start.
  show() {
    this._activeMessages = this.messagesValue
    this._open()
  }

  // Triggered by click on a lesson link. We let the click propagate so
  // Turbo still handles navigation — the overlay just paints first.
  showLesson(event) {
    // Skip locked / placeholder links (href="#").
    const link = event?.currentTarget
    if (link && link.getAttribute("href") === "#") return
    if (link && link.classList.contains("pointer-events-none")) return

    this._activeMessages = this.lessonMessagesValue
    this._open()
  }

  hide() {
    this._forceHide()
  }

  _open() {
    if (!this.hasOverlayTarget) return
    this._idx = 0
    this._renderMessage()
    this.overlayTarget.classList.remove("hidden")
    this.overlayTarget.setAttribute("aria-hidden", "false")
    document.documentElement.style.overflow = "hidden"
    this._startRotation()

    // Safety net: never trap the kid behind the overlay if the server
    // times out. Set just above the LLM client read_timeout (180s).
    this._stopFailsafe()
    this._failsafe = setTimeout(() => this._forceHide(), 200_000)
  }

  _stopFailsafe() {
    if (this._failsafe) {
      clearTimeout(this._failsafe)
      this._failsafe = null
    }
  }

  _renderMessage() {
    if (!this.hasMessageTarget) return
    const msgs = this._activeMessages
    if (!msgs || msgs.length === 0) return
    this.messageTarget.textContent = msgs[this._idx % msgs.length]
  }

  _startRotation() {
    if (this._reducedMotion) return
    this._stopRotation()
    this._timer = setInterval(() => {
      this._idx += 1
      this._renderMessage()
    }, this.rotateMsValue)
  }

  _stopRotation() {
    if (this._timer) {
      clearInterval(this._timer)
      this._timer = null
    }
  }
}
