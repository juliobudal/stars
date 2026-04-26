// fx_controller.js — single FX dispatcher for the kid app
// Mounted on <body data-controller="fx">. Observes the DOM for nodes
// carrying data-fx-event and dispatches to the matching handler.
//
// Contract:
//   data-fx-event="<name>"           required
//   data-fx-tier="big|small"         optional (celebrate)
//   data-fx-payload="{...JSON}"      optional
//   data-fx-dismiss-after="<ms>"     optional auto-dismiss
//
// Re-fire guard: data-fx-fired="true" set after first run.

import { Controller } from "@hotwired/stimulus"
import { animate } from "motion"
import confetti from "canvas-confetti"

export default class extends Controller {
  connect() {
    this.reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this._lastBurstAt = 0
    this._queue = []
    this._processing = false

    // Process nodes already in DOM
    this.scan(this.element)

    // Watch for new nodes
    this.observer = new MutationObserver((mutations) => {
      for (const m of mutations) {
        for (const node of m.addedNodes) {
          if (node.nodeType !== 1) continue
          this.scan(node)
        }
      }
    })
    this.observer.observe(this.element, { childList: true, subtree: true })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  scan(root) {
    const nodes = []
    if (root.matches?.("[data-fx-event]")) nodes.push(root)
    nodes.push(...(root.querySelectorAll?.("[data-fx-event]") || []))
    for (const node of nodes) {
      if (node.dataset.fxFired === "true") continue
      this.enqueue(node)
    }
  }

  enqueue(node) {
    this._queue.push(node)
    if (!this._processing) this.drain()
  }

  async drain() {
    this._processing = true
    while (this._queue.length) {
      const node = this._queue.shift()
      await this.dispatch(node)
      // 200ms gap between sequenced FX
      await new Promise((r) => setTimeout(r, 200))
    }
    this._processing = false
  }

  async dispatch(node) {
    node.dataset.fxFired = "true"
    if (this.reducedMotion) node.dataset.fxFiredReduced = "true"

    const event = node.dataset.fxEvent
    const tier = node.dataset.fxTier || "small"
    const payload = this.parsePayload(node.dataset.fxPayload)
    const dismissAfter = parseInt(node.dataset.fxDismissAfter || "0", 10)

    switch (event) {
      case "celebrate":
        await this.celebrate(node, tier, payload)
        break
      case "shake":
        this.shake(node)
        break
      case "pop-in":
        this.popIn(node)
        break
      case "toast":
        // Toast self-renders via CSS; only handle auto-dismiss
        break
      default:
        break
    }

    if (dismissAfter > 0) {
      setTimeout(() => this.dismiss(node), dismissAfter)
    }
  }

  async celebrate(node, tier, payload) {
    if (tier === "big") {
      this.confettiBurst(payload)
      // The overlay may BE this node (when celebration variant used standalone)
      // or a descendant (when wrapped by _celebration partial).
      const overlay = node.classList.contains("modal-overlay")
        ? node
        : node.querySelector(".modal-overlay")
      if (overlay) overlay.style.display = "flex"
    } else if (!this.reducedMotion) {
      // small tier: pulse the node
      node.classList.add("anim-pulse-once")
    }
  }

  confettiBurst(payload) {
    if (this.reducedMotion) return
    const now = Date.now()
    if (now - this._lastBurstAt < 500) return
    this._lastBurstAt = now

    const colors = payload?.palette === "gold"
      ? ["#ffc41a", "#ffd96a", "#ffeaa0"]
      : ["#ffc41a", "#ff8a5c", "#ff5a8a", "#3ed49e", "#38b6ff", "#9b7aff"]

    confetti({
      particleCount: 80,
      spread: 90,
      origin: { y: 0.4 },
      colors,
      disableForReducedMotion: true,
    })
  }

  // Action shortcut: data-action="click->fx#confettiBurstAction"
  confettiBurstAction(_event) {
    this.confettiBurst({})
  }

  shake(node) {
    if (this.reducedMotion) return
    node.classList.remove("anim-shake")
    void node.offsetWidth // force reflow so animation re-runs
    node.classList.add("anim-shake")
  }

  popIn(node) {
    if (this.reducedMotion) return
    animate(node, { opacity: [0, 1], transform: ["scale(0.94)", "scale(1)"] }, { duration: 0.38, easing: [0.34, 1.56, 0.64, 1] })
  }

  dismiss(node) {
    const overlay = node.classList?.contains?.("modal-overlay")
      ? node
      : node.querySelector?.(".modal-overlay")
    if (overlay) overlay.style.display = "none"
    if (this.reducedMotion) {
      node.remove()
      return
    }
    animate(node, { opacity: [1, 0] }, { duration: 0.2 }).finished.then(() => node.remove())
  }

  parsePayload(raw) {
    if (!raw) return {}
    try { return JSON.parse(raw) } catch { return {} }
  }
}
