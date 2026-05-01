// LittleStars PWA Service Worker
// Strategy summary (see .planning/phases/07-pwa/07-RESEARCH.md Q4):
//   HTML navigations    → network-first, fallback /offline.html
//   /vite/assets/*      → cache-first (immutable Vite hashes)
//   /icon*              → cache-first
//   Cross-origin / POST → pass-through (no respondWith)
// Bump CACHE on cache-shape changes (Vite hashes auto-bust their entries).

const CACHE = "littlestars-v1";
const SHELL = ["/offline.html", "/icon-192.png", "/icon-512.png"];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE).then((cache) => cache.addAll(SHELL)).then(() => self.skipWaiting())
  );
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

self.addEventListener("message", (event) => {
  if (event.data && event.data.type === "SKIP_WAITING") {
    self.skipWaiting();
  }
});

self.addEventListener("fetch", (event) => {
  const { request } = event;
  const url = new URL(request.url);

  // Only handle same-origin GETs
  if (request.method !== "GET" || url.origin !== self.location.origin) return;

  // HTML navigations → network-first, fallback to /offline.html
  if (request.mode === "navigate" || (request.headers.get("Accept") || "").includes("text/html")) {
    event.respondWith(
      fetch(request).catch(() => caches.match("/offline.html"))
    );
    return;
  }

  // Cache-first for Vite hashed assets and icons
  if (url.pathname.startsWith("/vite/assets/") || /^\/icon(-\d+)?\.(png|svg)$/.test(url.pathname)) {
    event.respondWith(
      caches.match(request).then((cached) => {
        if (cached) return cached;
        return fetch(request).then((response) => {
          if (response.ok) {
            const copy = response.clone();
            caches.open(CACHE).then((cache) => cache.put(request, copy));
          }
          return response;
        });
      })
    );
    return;
  }

  // Everything else: pass through (browser default)
});
