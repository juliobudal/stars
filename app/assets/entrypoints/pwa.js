// PWA service worker registration + update detection.
// SW lifecycle background: web.dev/articles/service-worker-lifecycle

if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("/service-worker", { scope: "/" })
      .then((registration) => {
        console.info("[pwa] sw registered, scope:", registration.scope);

        registration.addEventListener("updatefound", () => {
          const installing = registration.installing;
          if (!installing) return;

          installing.addEventListener("statechange", () => {
            if (installing.state === "installed" && navigator.serviceWorker.controller) {
              // A new SW has installed and is waiting; an old one still controls the page.
              window.dispatchEvent(
                new CustomEvent("pwa:update-available", { detail: { registration } })
              );
            }
          });
        });
      })
      .catch((err) => {
        console.warn("[pwa] sw registration failed:", err);
      });
  });
}

// Optional: when the controller changes (after user-accepted reload), reload page once.
let refreshing = false;
if ("serviceWorker" in navigator) {
  navigator.serviceWorker.addEventListener("controllerchange", () => {
    if (refreshing) return;
    refreshing = true;
    location.reload();
  });
}
