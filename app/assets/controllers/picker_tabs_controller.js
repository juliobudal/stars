import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]
  static values  = { flash: Boolean }

  connect() {
    const initial = this.flashValue ? "parents" : (this.activeTab() || "kids")
    this.activate(initial)
  }

  switch(event) {
    event.preventDefault()
    const tab = event.currentTarget.dataset.tab
    if (tab) this.activate(tab)
  }

  activate(tab) {
    this.tabTargets.forEach(btn => {
      const match = btn.dataset.tab === tab
      btn.classList.toggle("bg-primary", match)
      btn.classList.toggle("text-white", match)
      btn.classList.toggle("shadow-btn-primary", match)
      btn.classList.toggle("text-muted-foreground", !match)
      btn.setAttribute("aria-selected", match ? "true" : "false")
      btn.dataset.active = match ? "true" : "false"
    })
    this.panelTargets.forEach(p => {
      p.toggleAttribute("hidden", p.dataset.tab !== tab)
    })
  }

  activeTab() {
    const active = this.tabTargets.find(b => b.dataset.active === "true")
    return active?.dataset.tab
  }
}
