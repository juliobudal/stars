import '@hotwired/turbo-rails'
import * as Turbo from '@hotwired/turbo'

Turbo.config.drive.progressBarDelay = 150

// Subtle whole-page loading state for Turbo Drive page visits. After a short
// delay (so instant/cached navigations never flicker) we dim #main-content via
// the `.is-navigating` class on <html>; the swap clears it. Styled in base.css.
const NAV_DIM_DELAY = 250
let navDimTimer = null

function clearNavDim () {
  if (navDimTimer) {
    clearTimeout(navDimTimer)
    navDimTimer = null
  }
  document.documentElement.classList.remove('is-navigating')
}

document.addEventListener('turbo:visit', () => {
  navDimTimer = setTimeout(() => {
    document.documentElement.classList.add('is-navigating')
  }, NAV_DIM_DELAY)
})
document.addEventListener('turbo:before-render', clearNavDim)
document.addEventListener('turbo:load', clearNavDim)
document.addEventListener('turbo:render', clearNavDim)

// If a frame is missing, it's likely because the server redirected to a new location
document.addEventListener('turbo:frame-missing', event => {
  if (event.detail.response.redirected) {
    event.preventDefault()
    event.detail.visit(event.detail.response)
  }
})

function confirmMethod (message) {
  const dialog = document.getElementById('turbo-confirm')
  dialog.querySelector('p').textContent = message
  dialog.showModal()

  return new Promise((resolve) => {
    dialog.addEventListener('close', () => {
      resolve(dialog.returnValue === 'confirm')
    }, { once: true })

    dialog.addEventListener('click', (event) => {
      if (event.target.nodeName === 'DIALOG') {
        dialog.returnValue = 'cancel'
        dialog.close()
      }
    })
  })
}

Turbo.config.forms.confirm = confirmMethod
