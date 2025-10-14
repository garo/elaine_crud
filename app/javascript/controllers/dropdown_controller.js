import { Controller } from "@hotwired/stimulus"

// Dropdown controller for export menu
export default class extends Controller {
  static targets = ["menu"]

  toggle(event) {
    event.stopPropagation()
    this.menuTarget.classList.toggle("hidden")
  }

  hide(event) {
    if (event && this.element.contains(event.target)) {
      return
    }
    this.menuTarget.classList.add("hidden")
  }
}
