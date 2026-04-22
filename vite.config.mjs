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
    hmr: {
      host: '127.0.0.1',
      clientPort: 3036
    }
  }
})

// Triggering reload to apply config/vite.json changes
