/*
 * STV MobileReader iOS compatibility: keep authenticated requests on the
 * publisher's chosen https://sangtacviet.com origin.
 * The web app has a built-in mirror selector. Switching between mirrors
 * silently breaks cookie-based account sessions in WKWebView.
 *
 * Never read, store, print, or transmit user credentials/cookie values.
 * No account/login endpoint is modified, bypassed, or impersonated.
 */
(() => {
  "use strict";
  const ORIGIN = "https://sangtacviet.com";
  if (window.location.origin !== ORIGIN) return;

  function install() {
    const net = window.app?.net;
    const manager = net?.networkManagerXHR;
    if (!manager || typeof manager.bestDomain !== "function") return false;
    if (manager.__stvComPinned) return true;

    manager.__stvComPinned = true;

    // Avoid bouncing to a .app/.vip mirror after logging in to the .com site.
    manager.bestDomain = () => ORIGIN;
    if (typeof manager.isDomainAlive === "function") {
      const originalAlive = manager.isDomainAlive.bind(manager);
      manager.isDomainAlive = function(domain) {
        if (String(domain).replace(/\/$/, "") === ORIGIN) return true;
        return originalAlive(domain);
      };
    }
    if (net.networkManager && typeof net.networkManager.bestDomain === "function") {
      net.networkManager.bestDomain = () => ORIGIN;
    }
    if (window.app?.config?.ux) {
      window.app.config.ux.app_domain = ORIGIN;
    }

    // STV's native app uses its original same-origin login and checklogin.
    // Do not wrap XMLHttpRequest or replace app.net.post: those must preserve
    // the first-party browser's Set-Cookie and credential handling.
    return true;
  }

  function retryInstall() {
    if (install()) return true;
    return false;
  }
  if (!retryInstall()) {
    const poll = setInterval(() => {
      if (retryInstall()) clearInterval(poll);
    }, 30);
    setTimeout(() => clearInterval(poll), 30000);
  }
})();
