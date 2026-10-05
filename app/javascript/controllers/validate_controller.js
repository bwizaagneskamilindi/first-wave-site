import { Controller } from "@hotwired/stimulus"

// Friendly, instant feedback. The server still re-checks everything.
export default class extends Controller {
  static targets = ["field"]

  connect() { this.element.noValidate = true }

  check(event) { this.validate(event.target) }

  // After an error is showing, re-check while typing so it disappears as soon as it's fixed.
  clear(event) {
    if (event.target.getAttribute("aria-invalid") === "true") this.validate(event.target)
  }

  submit(event) {
    let firstBad = null
    this.fieldTargets.forEach((field) => {
      if (!this.validate(field) && !firstBad) firstBad = field
    })
    if (firstBad) {
      event.preventDefault()
      firstBad.focus()
    }
  }

  validate(field) {
    const value = field.value.trim()
    const rules = (field.dataset.rules || "").split(" ")
    let message = ""

    if (rules.includes("required") && value === "") {
      message = field.dataset.requiredMessage
    } else if (value !== "" && rules.includes("phone") && !this.validPhone(value)) {
      message = field.dataset.phoneMessage
    } else if (value !== "" && rules.includes("email") && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)) {
      message = field.dataset.emailMessage
    }

    const errorBox = this.element.querySelector(`#${field.id}-error`)
    if (errorBox) errorBox.textContent = message
    field.setAttribute("aria-invalid", message ? "true" : "false")
    return message === ""
  }

  validPhone(value) {
    let digits = value.replace(/\D/g, "").replace(/^00/, "")
    if (!digits.startsWith("250")) digits = "250" + digits.replace(/^0/, "")
    return /^2507[2389]\d{7}$/.test(digits)
  }
}