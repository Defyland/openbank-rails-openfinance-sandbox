import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { text: String }

  async copy(event) {
    event.preventDefault()

    if (!navigator.clipboard) return

    await navigator.clipboard.writeText(this.textValue)
    this.element.textContent = "Copied"
  }
}
