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
    hmr: { host: 'localhost' }
  }
})
