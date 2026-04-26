// tabs_controller.js — LittleStars tabs switcher
// Usage: data-controller="tabs" on a wrapper
//   Tabs: data-action="click->tabs#show" data-tabs-target-param="panel-id"
//   Panels: id="panel-{id}"

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab"]

  show(event) {
    const targetId = event.params.id

    // Toggle panels
    this.element.querySelectorAll("[id^='panel-']").forEach(panel => {
      panel.style.display = panel.id === `panel-${targetId}` ? "flex" : "none"
      panel.style.flexDirection = "column"
    })

    // Toggle tab active state. CategoryTabs use `cat-tab--active`;
    // FilterChips toggle inline Tailwind utilities.
    this.tabTargets.forEach(tab => {
      const isActive = tab.dataset.tabsIdParam === targetId
      if (tab.classList.contains("cat-tab")) {
        tab.classList.toggle("cat-tab--active", isActive)
      } else {
        tab.classList.toggle("bg-white", isActive)
        tab.classList.toggle("text-primary", isActive)
        tab.classList.toggle("shadow-sm", isActive)
        tab.classList.toggle("text-muted-foreground", !isActive)
      }
      tab.setAttribute("aria-selected", isActive)
    })
  }
}
