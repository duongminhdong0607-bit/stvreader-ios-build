/*
 * User-facing timeout and error state for STV MobileReader iOS.
 * No chapter data, authentication headers, or cookies are logged/collected.
 * Never claims successful loading when STV denies a chapter request.
 */
(() => {
  "use strict";
  let activePage = null;
  let pendingSince = 0;
  let lastFailure = "";
  let lastErrorText = "";
  let wrapped = false;

  function wrapTransport() {
    const net = window.app?.net;
    if (!net || typeof net.getCapacitor !== "function") return;
    if (net.getCapacitor.__stvReaderStatus) return;
    const original = net.getCapacitor;
    async function getWithChapterStatus(url) {
      const target = new URL(url, location.href);
      const chapter = (target.hostname === "sangtacviet.com"
        && target.searchParams.get("sajax") === "readchapter");
      try {
        const answer = await original.call(net, url);
        if (chapter) {
          const code = String(answer?.code ?? "");
          lastFailure = (code === "7" || code === "0") ? code : "";
          lastErrorText = (typeof answer?.err === "string" ? answer.err : "").slice(0, 150);
        }
        return answer;
      } catch (error) {
        if (chapter) {
          lastFailure = "network";
          lastErrorText = "";
        }
        throw error;
      }
    }
    getWithChapterStatus.__stvReaderStatus = true;
    net.getCapacitor = getWithChapterStatus;
    wrapped = true;
  }

  function currentReaderPage() {
    const page = window.app?.topPage?.();
    if (!page) return null;
    if (page.querySelector(".chapterdisplay") ||
        (typeof page.className === "string" && page.className.includes("readchapter"))) {
      return page;
    }
    return null;
  }

  function stillLoading(page) {
    const scroller = page?.querySelector(".chapterscroller");
    const chapterText = (scroller?.innerText || "").trim();
    if (chapterText.length > 280 && !/Đang tải nội dung/i.test(chapterText)) return false;
    const visible = (page.innerText || "").trim();
    return /Đang tải nội dung|Đang tải chương|Kết nối tới máy chủ thất bại/i.test(visible)
      || (chapterText.length === 0 && visible.length < 130);
  }

  function presentError() {
    if (document.getElementById("stv-ios-chapter-failure")) return;
    const root = document.createElement("div");
    root.id = "stv-ios-chapter-failure";
    root.setAttribute("role", "alert");
    Object.assign(root.style, {
      position: "fixed", left: "12px", right: "12px", top: "38%",
      zIndex: "2147483000", background: "#faf6e9", color: "#242424",
      border: "1px solid #b7a67d", padding: "18px 14px",
      borderRadius: "16px", boxShadow: "0 5px 20px #0002",
      fontFamily: "-apple-system, BlinkMacSystemFont, sans-serif",
      textAlign: "center", lineHeight: "1.5", fontSize: "15px"
    });
    const title = document.createElement("div");
    title.textContent = "Không tải được nội dung chương";
    title.style.fontWeight = "700";
    title.style.fontSize = "17px";
    const detail = document.createElement("p");
    const reason = lastFailure === "7" ? "Máy chủ STV không cung cấp nội dung cho yêu cầu này (mã 7)." :
      lastFailure === "network" ? "Kết nối tới máy chủ STV không thành công." :
      "Yêu cầu tải chương chưa hoàn tất.";
    detail.textContent = reason + " Bạn có thể đăng nhập trên STV, kiểm tra nguồn/chương hoặc thử tải lại.";
    const actions = document.createElement("div");
    Object.assign(actions.style, {display:"flex",gap:"10px",justifyContent:"center"});
    const retry = document.createElement("button");
    retry.textContent = "Thử tải lại";
    retry.style.cssText = "background:#246ac1;color:#fff;padding:10px 14px;border:0;border-radius:9px;font-size:15px;";
    retry.addEventListener("click", () => {
      root.remove();
      pendingSince = Date.now();
      lastFailure = "";
      try { window.app?.reader?.reloadCurrentChapter?.(true); }
      catch(_err) { /* preserve original reader's error handling */ }
    });
    const dismiss = document.createElement("button");
    dismiss.textContent = "Đóng";
    dismiss.style.cssText = "background:#ddd;color:#222;padding:10px 14px;border:0;border-radius:9px;font-size:15px;";
    dismiss.addEventListener("click", () => {
      root.remove();
      pendingSince = Date.now();
    });
    actions.append(retry,dismiss);
    root.append(title,detail,actions);
    document.body.appendChild(root);
  }

  setInterval(() => {
    wrapTransport();
    const page = currentReaderPage();
    if (!page) {
      activePage = null;
      pendingSince = 0;
      lastFailure = "";
      document.getElementById("stv-ios-chapter-failure")?.remove();
      return;
    }
    if (page !== activePage) {
      activePage = page;
      pendingSince = Date.now();
      lastFailure = "";
    }
    if (!stillLoading(page)) {
      pendingSince = 0;
      document.getElementById("stv-ios-chapter-failure")?.remove();
      return;
    }
    if (!pendingSince) pendingSince = Date.now();
    const delay = lastFailure === "7" ? 4000 : 22000;
    if (Date.now() - pendingSince > delay) presentError();
  }, 1000);
})();
