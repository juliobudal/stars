// tabs_controller.js — LittleStars tabs switcher
// Usage: data-controller="tabs" on a wrapper
//   Tabs: data-action="click->tabs#show" data-tabs-id-param="panel-id"
//   Panels: id="panel-{id}"
//
// Style toggle modes:
//   - CategoryTab uses the `cat-tab--active` modifier class
//   - FilterChip (and any tab with `data-active-style`/`data-inactive-style`)
//     swaps the inline style attribute. Optional `[data-pill-badge]` children
//     follow the same convention so badge contrast stays in sync.

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab"]

  show(event) {
    const targetId = event.params.id

    this.element.querySelectorAll("[id^='panel-']").forEach(panel => {
      const isActive = panel.id === `panel-${targetId}`
      panel.style.display = isActive ? "flex" : "none"
      panel.style.flexDirection = "column"
    })

    this.tabTargets.forEach(tab => {
      const isActive = tab.dataset.tabsIdParam === targetId
      this.applyTabStyle(tab, isActive)
      tab.setAttribute("aria-selected", isActive)
    })
  }

  applyTabStyle(tab, isActive) {
    if (tab.classList.contains("cat-tab")) {
      tab.classList.toggle("cat-tab--active", isActive)
      return
    }

    const activeStyle = tab.dataset.activeStyle
    const inactiveStyle = tab.dataset.inactiveStyle
    if (activeStyle && inactiveStyle) {
      tab.setAttribute("style", isActive ? activeStyle : inactiveStyle)
      tab.querySelectorAll("[data-pill-badge]").forEach(badge => {
        const ba = badge.dataset.activeStyle
        const bi = badge.dataset.inactiveStyle
        if (ba && bi) badge.setAttribute("style", isActive ? ba : bi)
      })
    }
  }
}
