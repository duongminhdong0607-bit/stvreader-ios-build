/* STV iOS compatibility shim: guard undefined CSS selectors. No account data is read. */
(() => {
  "use strict";
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
