// tabs_controller.js — LittleStars tabs switcher
// Usage: data-controller="tabs" on a wrapper
//   Tabs: data-action="click->tabs#show" data-tabs-target-param="panel-id"
//   Panels: id="panel-{id}"

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  show(event) {
    const targetId = event.currentTarget.dataset.tabsTargetParam

    // Toggle panels
    this.element.querySelectorAll("[id^='panel-']").forEach(panel => {
      panel.style.display = panel.id === `panel-${targetId}` ? "flex" : "none"
      panel.style.flexDirection = "column"
    })

    // Toggle tab active state
    this.element.querySelectorAll(".tab").forEach(tab => {
      const isActive = tab.dataset.tabsTargetParam === targetId
      tab.classList.toggle("active", isActive)
    })
  }
}
