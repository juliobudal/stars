import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "item"]

  connect() {
    const active = this.tabTargets.find(t => t.classList.contains("active"))
    if (active) this.apply(active.dataset.filterTabsIdParam || active.dataset.key || "all")
  }

  // Called via data-action="click->filter-tabs#show" (FilterChips component uses #show)
  show(event) {
    const key = event.currentTarget.dataset.filterTabsIdParam || event.currentTarget.dataset.key
    if (!key) return
    this.tabTargets.forEach(t => t.classList.toggle("active", t === event.currentTarget))
    this.apply(key)
  }

  apply(key) {
    this.itemTargets.forEach(el => {
      const panels = (el.dataset.panels || "all").split(/\s+/)
      el.hidden = !(key === "all" || panels.includes(key))
    })
  }
}
