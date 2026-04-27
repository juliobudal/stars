import { Controller } from "@hotwired/stimulus"

const PAGE_SIZE = 60
let manifestPromise = null

function loadManifest() {
  if (window.__hugeiconsManifest) return Promise.resolve(window.__hugeiconsManifest)
  if (manifestPromise) return manifestPromise
  manifestPromise = fetch("/hugeicons-manifest.json", { credentials: "same-origin", cache: "no-cache" })
    .then(r => r.json())
    .then(data => { window.__hugeiconsManifest = data; return data })
  return manifestPromise
}

export default class extends Controller {
  static targets = [
    "hiddenInput", "previewIcon", "modal",
    "searchInput", "tabCurated", "tabCatalog",
    "curatedGrid", "catalogGrid", "loadMoreBtn"
  ]
  static values = {
    context: String,
    modalId: String,
    curated: Array,
    color: String
  }

  connect() {
    this.pendingValue = this.hiddenInputTarget.value || null
    this.activeTab = "curated"
    this.catalogPage = 0
    this.filteredCatalog = []
    this.renderCurated()
  }

  open(event) {
    event.preventDefault()
    if (!this.hasModalTarget) return
    this.modalTarget.classList.remove("hidden")
    this.modalTarget.classList.add("flex")
    this.modalTarget.setAttribute("aria-hidden", "false")
    this.pendingValue = this.hiddenInputTarget.value || null
    this.searchInputTarget.value = ""
    this.activeTab = "curated"
    this.applyTabUI()
    this.renderCurated()
    loadManifest()
  }

  close() {
    if (!this.hasModalTarget) return
    this.modalTarget.classList.add("hidden")
    this.modalTarget.classList.remove("flex")
    this.modalTarget.setAttribute("aria-hidden", "true")
  }

  cancel(event) {
    event.preventDefault()
    this.close()
  }

  confirm(event) {
    event.preventDefault()
    if (!this.pendingValue) { this.close(); return }
    this.hiddenInputTarget.value = this.pendingValue
    this.hiddenInputTarget.dispatchEvent(new Event("change", { bubbles: true }))
    this.updatePreview(this.pendingValue)
    this.close()
  }

  showCurated(event) {
    event?.preventDefault()
    this.activeTab = "curated"
    this.applyTabUI()
    this.renderCurated()
  }

  showCatalog(event) {
    event?.preventDefault()
    this.activeTab = "catalog"
    this.applyTabUI()
    this.catalogPage = 0
    loadManifest().then(manifest => {
      this.filteredCatalog = manifest
      this.renderCatalogPage()
    })
  }

  search() {
    const q = this.searchInputTarget.value.trim().toLowerCase()
    if (q.length < 2) {
      if (this.activeTab === "catalog") {
        loadManifest().then(manifest => {
          this.filteredCatalog = manifest
          this.catalogPage = 0
          this.renderCatalogPage()
        })
      }
      return
    }
    this.activeTab = "catalog"
    this.applyTabUI()
    loadManifest().then(manifest => {
      this.filteredCatalog = manifest.filter(entry => {
        if (entry.name && entry.name.toLowerCase().includes(q)) return true
        if (entry.slug && entry.slug.toLowerCase().includes(q)) return true
        return Array.isArray(entry.tags) && entry.tags.some(t => t.toLowerCase().includes(q))
      })
      this.catalogPage = 0
      this.renderCatalogPage()
    })
  }

  loadMore(event) {
    event?.preventDefault()
    this.catalogPage += 1
    this.renderCatalogPage({ append: true })
  }

  renderCurated() {
    this.curatedGridTarget.classList.remove("hidden")
    this.catalogGridTarget.classList.add("hidden")
    this.loadMoreBtnTarget.classList.add("hidden")
    this.curatedGridTarget.innerHTML = ""
    for (const slug of this.curatedValue) {
      this.curatedGridTarget.appendChild(this.tileEl(slug))
    }
  }

  renderCatalogPage({ append = false } = {}) {
    this.catalogGridTarget.classList.remove("hidden")
    this.curatedGridTarget.classList.add("hidden")
    if (!append) this.catalogGridTarget.innerHTML = ""
    const start = this.catalogPage * PAGE_SIZE
    const end = start + PAGE_SIZE
    const slice = this.filteredCatalog.slice(start, end)
    for (const entry of slice) {
      this.catalogGridTarget.appendChild(this.tileEl(entry.slug))
    }
    const total = this.filteredCatalog.length
    const shown = Math.min(end, total)
    if (shown < total) {
      this.loadMoreBtnTarget.classList.remove("hidden")
      this.loadMoreBtnTarget.textContent = `Carregar mais (${shown} de ${total})`
    } else {
      this.loadMoreBtnTarget.classList.add("hidden")
    }
  }

  tileEl(slug) {
    const btn = document.createElement("button")
    btn.type = "button"
    btn.dataset.slug = slug
    btn.className = this.tileClasses(slug)
    btn.setAttribute("aria-label", slug)
    btn.addEventListener("click", (e) => {
      e.preventDefault()
      this.pendingValue = slug
      this.refreshTileSelection()
    })

    const i = document.createElement("i")
    i.className = `hgi-stroke hgi-${slug}`
    i.style.cssText = "font-size:24px; line-height:1; color: var(--primary); display:inline-flex; align-items:center; justify-content:center; width:24px; height:24px;"
    i.setAttribute("aria-hidden", "true")
    btn.appendChild(i)
    return btn
  }

  tileClasses(slug) {
    const selected = (slug === this.pendingValue)
    return [
      "flex items-center justify-center w-11 h-11 rounded-xl border-2 transition-all bg-white",
      selected ? "border-primary bg-primary-soft" : "border-[rgba(26,42,74,0.1)] hover:border-primary"
    ].join(" ")
  }

  refreshTileSelection() {
    const grids = [this.curatedGridTarget, this.catalogGridTarget]
    for (const grid of grids) {
      for (const el of grid.querySelectorAll("button[data-slug]")) {
        el.className = this.tileClasses(el.dataset.slug)
      }
    }
  }

  updatePreview(slug) {
    const i = this.previewIconTarget.querySelector("i.hgi-stroke, i.hgi-bulk")
    if (!i) return
    i.className = i.className
      .split(" ")
      .filter(c => !c.startsWith("hgi-") || c === "hgi-stroke" || c === "hgi-bulk")
      .concat(`hgi-${slug}`)
      .join(" ")
  }

  applyTabUI() {
    const active = ["border-primary", "text-primary"]
    const idle   = ["border-transparent", "text-muted-foreground", "hover:text-foreground"]
    const setBtn = (el, on) => {
      el.classList.remove(...active, ...idle)
      el.classList.add(...(on ? active : idle))
    }
    setBtn(this.tabCuratedTarget, this.activeTab === "curated")
    setBtn(this.tabCatalogTarget, this.activeTab === "catalog")
  }
}
