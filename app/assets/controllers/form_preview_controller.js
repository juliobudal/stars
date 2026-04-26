import { Controller } from "@hotwired/stimulus"

// Updates a live preview pane as form fields change.
// Wire fields with data-form-preview-field="<name>" — e.g. "name", "color", "icon".
// Wire preview slots with data-form-preview-target="<slot>"
//   - text slots: data-form-preview-target="name" → textContent gets the value
//   - swatch slots: data-form-preview-swatch="true" → background var(--c-{value})
//   - icon slots: data-form-preview-icon="true" → swap hgi-{value} class
//   - palette host: data-form-preview-palette="true" → data-palette attr swapped
export default class extends Controller {
  static targets = ["root"]

  connect() {
    this.element.addEventListener("input", this.handle)
    this.element.addEventListener("change", this.handle)
    this.refreshAll()
  }

  disconnect() {
    this.element.removeEventListener("input", this.handle)
    this.element.removeEventListener("change", this.handle)
  }

  handle = (event) => {
    const field = event.target.closest("[data-form-preview-field]")
    if (!field) return
    this.applyField(field.dataset.formPreviewField, this.fieldValue(field))
  }

  fieldValue(field) {
    if (field.type === "radio") {
      const checked = this.element.querySelector(`[data-form-preview-field="${field.dataset.formPreviewField}"]:checked`)
      return checked ? checked.value : ""
    }
    return field.value
  }

  refreshAll() {
    const seen = new Set()
    this.element.querySelectorAll("[data-form-preview-field]").forEach((f) => {
      const name = f.dataset.formPreviewField
      if (seen.has(name)) return
      seen.add(name)
      this.applyField(name, this.fieldValue(f))
    })
  }

  applyField(name, value) {
    const targets = this.element.querySelectorAll(`[data-form-preview-target="${name}"]`)
    targets.forEach((node) => {
      if (node.dataset.formPreviewIcon === "true") {
        const i = node.querySelector("i") || node
        i.className = i.className
          .split(" ")
          .filter((c) => !c.startsWith("hgi-") || c === "hgi-stroke" || c === "hgi-bulk")
          .concat(value ? `hgi-${value}` : "")
          .filter(Boolean)
          .join(" ")
      } else if (node.dataset.formPreviewSwatch === "true") {
        node.style.background = value ? `var(--c-${value})` : ""
      } else if (node.dataset.formPreviewPalette === "true") {
        if (value) node.dataset.palette = value
        else delete node.dataset.palette
      } else {
        node.textContent = value || node.dataset.formPreviewFallback || ""
      }
    })
  }
}
