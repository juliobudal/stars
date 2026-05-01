import '~/init'
import '~/controllers'
import './application.css'

// Import JS and CSS from view_components
import.meta.glob('../../components/**/*.js', { eager: true })
import.meta.glob('../../components/**/*.css', { eager: true })

import "./pwa"
