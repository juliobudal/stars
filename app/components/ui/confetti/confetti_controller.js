import { Controller } from '@hotwired/stimulus'
import confetti from 'canvas-confetti'

export default class extends Controller {
  connect() {
    if (this.element.dataset.confettiOnConnect === 'true') {
      this.fire()
    }
  }

  fire() {
    const duration = 3 * 1000
    const animationEnd = Date.now() + duration
    const defaults = { startVelocity: 30, spread: 360, ticks: 60, zIndex: 0 }

    const randomInRange = (min, max) => {
      return Math.random() * (max - min) + min
    }

    const interval = setInterval(function() {
      const timeLeft = animationEnd - Date.now()

      if (timeLeft <= 0) {
        return clearInterval(interval)
      }

      const particleCount = 50 * (timeLeft / duration)
      // since particles fall down, start a bit higher than random
      confetti({ ...defaults, particleCount, origin: { x: randomInRange(0.1, 0.3), y: Math.random() - 0.2 } })
      confetti({ ...defaults, particleCount, origin: { x: randomInRange(0.7, 0.9), y: Math.random() - 0.2 } })
    }, 250)
  }

  success() {
    const scalar = 2
    const triangle = confetti.shapeFromPath({ path: 'M0 10 L5 0 L10 10z' })

    confetti({
      shapes: [triangle],
      particleCount: 100,
      spread: 70,
      origin: { y: 0.6 },
      colors: ['#58cc02', '#1cb0f6', '#ffc800', '#ff4b4b']
    })
  }

  schoolPride() {
    const end = Date.now() + (3 * 1000)
    const colors = ['#58cc02', '#ffffff']

    ;(function frame() {
      confetti({
        particleCount: 2,
        angle: 60,
        spread: 55,
        origin: { x: 0 },
        colors: colors
      })
      confetti({
        particleCount: 2,
        angle: 120,
        spread: 55,
        origin: { x: 1 },
        colors: colors
      })

      if (Date.now() < end) {
        requestAnimationFrame(frame)
      }
    }())
  }
}
