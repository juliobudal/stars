import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "item"]

  connect() {
    const active = this.tabTargets.find(t => t.getAttribute("aria-selected") === "true")
                   || this.tabTargets.find(t => t.classList.contains("active"))
                   || this.tabTargets[0]
    if (active) {
      const key = active.dataset.filterTabsIdParam || active.dataset.key || "all"
      this.activate(active, key)
    }
  }

  // Called via data-action="click->filter-tabs#show"
  show(event) {
    const button = event.currentTarget
    const key = button.dataset.filterTabsIdParam || button.dataset.key
    if (!key) return
    this.activate(button, key)
  }

  activate(activeBtn, key) {
    this.tabTargets.forEach(t => {
      const isActive = t === activeBtn
      t.classList.toggle("active", isActive)
      t.setAttribute("aria-selected", isActive ? "true" : "false")

      if (t.classList.contains("cat-tab")) {
        t.classList.toggle("cat-tab--active", isActive)
      }

      const styleAttr = isActive ? t.dataset.activeStyle : t.dataset.inactiveStyle
      if (styleAttr) t.setAttribute("style", styleAttr)

      const badge = t.querySelector("[data-pill-badge]")
      if (badge) {
        const badgeStyle = isActive ? badge.dataset.activeStyle : badge.dataset.inactiveStyle
        if (badgeStyle) badge.setAttribute("style", badgeStyle)
      }
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
