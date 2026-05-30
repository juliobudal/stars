import { defineConfig } from 'vite'
import ViteRails from 'vite-plugin-rails'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [
    tailwindcss(),
    ViteRails()
  ],
  server: {
    host: '0.0.0.0',
    port: 3036,
    strictPort: true,
    // The Vite dev server is only reachable from the browser through the Rails
    // (Puma) same-origin proxy at /vite — the direct Docker-mapped port
    // (127.0.0.1:10302) is unreachable, so any asset URL pointing there fails
    // (the icon webfont referenced from CSS url(), and the HMR websocket).
    // Point both at the page origin so they ride the working proxy.
    origin: 'http://localhost:10301',
    cors: true,
    allowedHosts: true,
    hmr: {
      protocol: 'ws',
      host: 'localhost',
      clientPort: 10301
    }
  }
})

// Triggering reload to apply config/vite.json changes
