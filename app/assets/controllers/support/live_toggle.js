// Shared helpers for the live-save toggle controllers (assignment_matrix,
// child_assign). Not a Stimulus controller (filename doesn't end in
// *_controller.js), so it's not auto-registered — just imported.

export function csrfToken() {
  return document.querySelector('meta[name="csrf-token"]')?.content || ""
}

// PATCH a urlencoded body and apply the returned turbo-stream. Returns the
// Response so callers can branch on res.ok. Throws on network failure.
export async function patchTurbo(url, body) {
  const res = await fetch(url, {
    method: "PATCH",
    headers: {
      Accept: "text/vnd.turbo-stream.html",
      "Content-Type": "application/x-www-form-urlencoded",
      "X-CSRF-Token": csrfToken()
    },
    body: body.toString()
  })
  const text = await res.text()
  if (text) window.Turbo.renderStreamMessage(text)
  return res
}

// Show a transient toast on the given target element.
export function flashToast(target, message, ms = 2800) {
  if (!target) return
  target.textContent = message
  target.hidden = false
  clearTimeout(target._dismiss)
  target._dismiss = setTimeout(() => { target.hidden = true }, ms)
}
