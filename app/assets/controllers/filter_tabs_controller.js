import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "item"]

  connect() {
    const active = this.tabTargets.find(t => t.getAttribute("aria-selected") === "true")
                   || this.tabTargets.find(t => t.classList.contains("active"))
    if (active) {
      active.classList.add("active")
      this.apply(active.dataset.filterTabsIdParam || active.dataset.key || "all")
    }
  }

  // Called via data-action="click->filter-tabs#show" (FilterChips component uses #show)
  show(event) {
    const key = event.currentTarget.dataset.filterTabsIdParam || event.currentTarget.dataset.key
    if (!key) return
    this.tabTargets.forEach(t => {
      const isActive = t === event.currentTarget
      t.classList.toggle("active", isActive)
      t.classList.toggle("bg-white", isActive)
      t.classList.toggle("text-primary", isActive)
      t.classList.toggle("shadow-sm", isActive)
      t.classList.toggle("text-muted-foreground", !isActive)
      t.setAttribute("aria-selected", isActive)
    })
    this.apply(key)
  }

  apply(key) {
    this.itemTargets.forEach(el => {
      const panels = (el.dataset.panels || "all").split(/\s+/)
      el.hidden = !(key === "all" || panels.includes(key))
    })
  }
}
