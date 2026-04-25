import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["form"];

  confirm(event) {
    event.preventDefault();
    if (window.confirm("Sair desta conta?")) {
      this.formTarget.requestSubmit();
    }
  }
}
