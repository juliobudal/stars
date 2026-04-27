import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["dots", "input", "form", "overlay", "card"];

  connect() {
    this.value = "";
    this.render();
    this._onKey = (e) => { if (e.key === "Escape") this.close(); };
    document.addEventListener("keydown", this._onKey);
  }

  disconnect() {
    document.removeEventListener("keydown", this._onKey);
  }

  close() {
    const frame = this.element.closest("turbo-frame");
    if (frame) {
      frame.removeAttribute("src");
      frame.innerHTML = "";
    } else {
      this.element.remove();
    }
  }

  closeOnOverlay(event) {
    if (event.target === this.element) this.close();
  }

  press(event) {
    if (this.value.length >= 4) return;
    this.value += event.currentTarget.dataset.digit;
    this.render();
    if (this.value.length === 4) this.submit();
  }

  backspace() {
    this.value = this.value.slice(0, -1);
    this.render();
  }

  clear() {
    this.value = "";
    this.render();
  }

  submit() {
    this.inputTarget.value = this.value;
    this.formTarget.requestSubmit();
  }

  render() {
    const dots = this.dotsTarget.querySelectorAll(".pin-dot");
    dots.forEach((dot, i) => dot.classList.toggle("filled", i < this.value.length));
    this.inputTarget.value = this.value;
  }
}
