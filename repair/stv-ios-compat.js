/* STV iOS compatibility shim: guard undefined CSS selectors. No account data is read. */
(() => {
  "use strict";
  // STV 1.3.3 uses nativeclick.trigger() for Android/iOS haptic feedback.
  // The proprietary bridge is absent from this rebuilt iOS IPA.
  // A safe no-op must not block navigation into a selected book.
  if (!window.nativeclick || typeof window.nativeclick.trigger !== "function") {
    window.nativeclick = { trigger() { return undefined; } };
  }
  // Original Android app downloads cover art via Capacitor.Plugins.Http.
  // The iOS rebuild has no such plugin; use a regular image request instead.
  // This affects cover artwork only; it does not touch account/network APIs.
  function installImageFallback() {
    const images = window.app && window.app.images;
    if (!images || typeof images.downloadAndAssign !== "function") return false;
    if (images.downloadAndAssign.__stvIOSCompat) return true;
    const original = images.downloadAndAssign;
    function compatibleDownloadAndAssign(url, image, headers = {}) {
      if (window.Capacitor?.Plugins?.Http?.get) {
        return original.call(this, url, image, headers);
      }
      if (!image || !url) return Promise.resolve();
      return new Promise(resolve => {
        let finished = false;
        const finish = () => {
          if (finished) return;
          finished = true;
          resolve();
        };
        image.addEventListener("load", finish, {once:true});
        image.addEventListener("error", finish, {once:true});
        image.src = url;
        setTimeout(finish, 5000);
      });
    }
    compatibleDownloadAndAssign.__stvIOSCompat = true;
    images.downloadAndAssign = compatibleDownloadAndAssign;
    return true;
  }
  if (!installImageFallback()) {
    const imagePoll = setInterval(() => {
      if (installImageFallback()) clearInterval(imagePoll);
    }, 20);
    setTimeout(() => clearInterval(imagePoll), 30000);
  }

  function install() {
    const style = window.ui && window.ui.style;
    if (!style || typeof style.create !== "function") return false;
    if (style.create.__stvIOSCompat) return true;
    const original = style.create;
    function patchedCreate(...args) {
      const sheet = original.apply(this, args);
      if (sheet && typeof sheet.update === "function" && typeof sheet.set === "function") {
        const originalUpdate = sheet.update;
        sheet.update = function(selector, values) {
          if (!this.collection || !this.collection[selector]) {
            this.set(selector, {});
          }
          return originalUpdate.call(this, selector, values);
        };
      }
      return sheet;
    }
    patchedCreate.__stvIOSCompat = true;
    style.create = patchedCreate;
    return true;
  }
  document.addEventListener("load", (event) => {
    const script = event.target;
    if (script && script.tagName === "SCRIPT" && (script.src || "").includes("/stv.ui.js")) {
      install();
    }
  }, true);
  if (!install()) {
    const poll = setInterval(() => { if (install()) clearInterval(poll); }, 1);
    setTimeout(() => clearInterval(poll), 30000);
  }
})();
