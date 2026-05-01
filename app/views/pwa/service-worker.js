// PWA Service Worker — see Plan 07-03 for full cache strategy implementation.
// This stub exists so the /service-worker route resolves with 200 instead of 404.
self.addEventListener("install",  () => self.skipWaiting());
self.addEventListener("activate", () => self.clients.claim());
self.addEventListener("fetch",    () => {});
