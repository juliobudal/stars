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

    if (this.hasBalanceTargetValue) {
      const el = document.getElementById(this.balanceTargetValue)
      if (el) {
        el.setAttribute('data-count-up-current-value', String(this.balanceValue))
      }
    }

    this.element.remove()
  }
}
