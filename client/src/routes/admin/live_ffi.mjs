export function setTimeout(ms, callback) {
  globalThis.setTimeout(callback, ms);
}