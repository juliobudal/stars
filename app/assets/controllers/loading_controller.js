import { Controller } from "@hotwired/stimulus"

// Global form-submit loading state.
//
// Attached to <body data-controller="loading">. Listens for Turbo's
// submit-start / submit-end events bubbling up from any form on the page
// and toggles `.is-submitting` on the submitter button so it shows a
// spinner. Skips opt-out forms (`data-loading="off"`).
//
// Turbo also disables the submitter natively, but for stream-only
// responses the visual feedback can be invisible — this controller fills
// that gap with a unified spinner.
export default class extends Controller {
  connect() {
    this.onStart = this.onStart.bind(this)
    this.onEnd = this.onEnd.bind(this)
    document.addEventListener("turbo:submit-start", this.onStart)
    document.addEventListener("turbo:submit-end", this.onEnd)
    document.addEventListener("turbo:before-fetch-request", this.onStart)
    document.addEventListener("turbo:before-fetch-response", this.onEnd)
  }

  disconnect() {
    document.removeEventListener("turbo:submit-start", this.onStart)
    document.removeEventListener("turbo:submit-end", this.onEnd)
    document.removeEventListener("turbo:before-fetch-request", this.onStart)
    document.removeEventListener("turbo:before-fetch-response", this.onEnd)
  }

  onStart(event) {
    const form = event.target && event.target.tagName === "FORM" ? event.target : null
    if (!form) return
    if (form.dataset.loading === "off") return
    const submitter = (event.detail && event.detail.formSubmission && event.detail.formSubmission.submitter)
                      || form.querySelector('button[type="submit"], input[type="submit"]')
    if (submitter) {
      submitter.classList.add("is-submitting")
      submitter.setAttribute("aria-busy", "true")
    }
  }

  onEnd(event) {
    const form = event.target && event.target.tagName === "FORM" ? event.target : null
    if (!form) return
    form.querySelectorAll(".is-submitting").forEach((el) => {
      el.classList.remove("is-submitting")
      el.removeAttribute("aria-busy")
    })
  }
}
