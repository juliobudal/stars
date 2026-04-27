import { Controller } from "@hotwired/stimulus"

// Repaints option labels in a group (radio or checkbox) based on the input's
// checked state. Each label is a target carrying selected/unselected style
// payloads as data attributes.
//
// Markup:
//   <div data-controller="selectable-group">
//     <label data-selectable-group-target="option"
//            data-selected-style="background: ..."
//            data-unselected-style="background: ...">
//       <input type="radio" class="sr-only">
//       ...
//     </label>
//   </div>
//
// Optional per-option overrides:
//   data-selected-text-style / data-unselected-text-style applied to any
//   descendant matching [data-selectable-text]
export default class extends Controller {
  static targets = ["option"]

  connect() {
    this.handler = () => this.repaint()
    this.element.addEventListener("change", this.handler)
    this.repaint()
  }

  disconnect() {
    this.element.removeEventListener("change", this.handler)
  }

  repaint() {
    this.optionTargets.forEach((label) => {
      const input = label.querySelector("input[type=radio], input[type=checkbox]")
      if (!input) return
      const checked = input.checked
      const style = checked ? label.dataset.selectedStyle : label.dataset.unselectedStyle
      if (style != null) label.setAttribute("style", style)

      const textKey = checked ? "selectedTextStyle" : "unselectedTextStyle"
      const textStyle = label.dataset[textKey]
      if (textStyle != null) {
        label.querySelectorAll("[data-selectable-text]").forEach((el) => {
          el.setAttribute("style", textStyle)
        })
      }

      const checkMark = label.querySelector("[data-selectable-check]")
      if (checkMark) {
        checkMark.style.display = checked ? "" : "none"
      }
      const checkBg = label.querySelector("[data-selectable-check-bg]")
      if (checkBg) {
        const bgStyle = checked ? checkBg.dataset.selectedStyle : checkBg.dataset.unselectedStyle
        if (bgStyle != null) checkBg.setAttribute("style", bgStyle)
      }
    })
  }
}
