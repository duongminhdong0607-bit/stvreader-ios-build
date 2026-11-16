/* Original MobileReader 1.3.3 chapter API through native HTTP on iOS.
   Use only official /index.php?sajax=readchapter on sangtacviet.com;
   preserve first-party authentication and server access decisions. */
(() => {
  'use strict';
  function install() {
    const net = window.app?.net;
    if (!net || !window.Capacitor?.Plugins?.Http ||
        typeof net.get !== 'function' ||
        typeof net.getCapacitor !== 'function') return false;
    if (net.get.__stvIOSChapterTransport) return true;
    const original = net.get;
    const patched = async function(url, ...args) {
      try {
        const parsed = new URL(url, window.location.href);
        if (parsed.origin === 'https://sangtacviet.com' &&
            (parsed.pathname === '/' || parsed.pathname === '/index.php') &&
            parsed.searchParams.get('sajax') === 'readchapter') {
          try {
            return await net.getCapacitor(parsed.href);
          } catch (_nativeFailure) { /* Fall back to STV's original XHR. */ }
        }
      } catch (_invalidURL) { /* Let the original function handle it. */ }
      return original.call(net, url, ...args);
    };
    patched.__stvIOSChapterTransport = true;
    net.get = patched;
    return true;
  }
  if (!install()) {
    const poll = setInterval(() => { if (install()) clearInterval(poll); }, 5);
    setTimeout(() => clearInterval(poll), 30000);
  }
})();
