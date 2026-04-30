import { Controller } from '@hotwired/stimulus'

// After-redeem hook fired by kid/rewards/redeem.turbo_stream.erb.
// Appends a data-controller="redeem" element to <body>; on connect
// the controller closes any open redeem modal, restores body scroll,
// and bumps the balance count-up target so count_up_controller animates
// to the new value. Self-removes once done so re-renders re-trigger.
//
// Values:
//   balance       — new profile balance (integer)
//   balanceTarget — id of the count-up element to update (e.g.
//                   "profile_points_42")
export default class extends Controller {
  static values = {
    balance: Number,
    balanceTarget: String
  }

  connect() {
    document.querySelectorAll('.modal-overlay').forEach((overlay) => {
      overlay.style.display = 'none'
    })
    document.body.style.overflow = 'auto'

    // ui_modal_controller#open marks all body children inert/aria-hidden while
    // a dialog is open. After redeem the modal is hidden/removed without going
    // through that controller's close path, so we restore the page state here
    // — otherwise the rest of the screen stays click-blocked.
    Array.from(document.body.children).forEach((el) => {
      el.removeAttribute('inert')
      el.removeAttribute('aria-hidden')
    })

    if (this.hasBalanceTargetValue) {
      const el = document.getElementById(this.balanceTargetValue)
      if (el) {
        el.setAttribute('data-count-up-current-value', String(this.balanceValue))
      }
    }

    this.element.remove()
  }
}
