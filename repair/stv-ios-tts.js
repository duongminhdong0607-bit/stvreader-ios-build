/* Native iOS TTS compatibility, based on feature surface in STV 1.3.3 APK.
   Do not collect credentials, read cookies, or send text to third-party APIs. */
(() => {
  "use strict";
  if (window.TTS && window.TTS.__stvIOSSynth) return;
  const plugin = () => window.Capacitor?.Plugins?.TextToSpeech;
  const language = (options) => (options && (options.lang || options.language)) || "vi-VN";
  const optionsOf = (input) => typeof input === "string" ? { text: input } : (input || {});
  const fallback = (options) => {
    const text = String(options.text || "");
    if (!text) return Promise.resolve();
    if (!("speechSynthesis" in window)) {
      return Promise.reject(new Error("iOS speech synthesis unavailable"));
    }
    window.speechSynthesis.cancel();
    return new Promise((resolve, reject) => {
      const utterance = new SpeechSynthesisUtterance(text);
      utterance.lang = language(options);
      utterance.rate = Number(options.rate || 1);
      utterance.onend = () => resolve();
      utterance.onerror = (event) => reject(new Error(event.error || "Speech failed"));
      window.speechSynthesis.speak(utterance);
    });
  };
  const tts = {
    __stvIOSSynth: true,
    speak(input) {
      const options = optionsOf(input);
      const p = plugin();
      if (p && typeof p.speak === "function") {
        return Promise.resolve(p.speak({
          text: String(options.text || ""),
          lang: language(options),
          rate: Number(options.rate || 1),
          pitch: Number(options.pitch || 1),
          volume: Number(options.volume || 1)
        }));
      }
      return fallback(options);
    },
    stop() {
      const p = plugin();
      if (window.speechSynthesis) window.speechSynthesis.cancel();
      return (p && typeof p.stop === "function") ? Promise.resolve(p.stop()) : Promise.resolve();
    },
    checkLanguage() {
      const p = plugin();
      return p?.getSupportedLanguages?.().then(result => result?.languages || ["vi-VN"])
        || Promise.resolve(["vi-VN"]);
    },
    getVoices() {
      const p = plugin();
      return p?.getSupportedVoices?.().then(result => result?.voices || [])
        || Promise.resolve((window.speechSynthesis?.getVoices?.() || []).map(v => ({
          name:v.name, lang:v.lang, voiceURI:v.voiceURI
        })));
    },
    getEngines() { return Promise.resolve([{name:"iOS System Speech", packageName:"ios"}]); },
    setEngine() { return Promise.resolve(); },
    updateMediaSession() { return Promise.resolve(); },
    stopMediaSession() { return Promise.resolve(); },
    openInstallTts() { return Promise.resolve(); },
    speakToFile() { return Promise.reject(new Error("Exporting TTS audio is not supported by this iOS rebuild")); }
  };
  try {
    Object.defineProperty(window, "TTS", {
      configurable: true, enumerable: true, get() { return tts; },
      set(value) { if (value && value.__stvIOSSynth) return; }
    });
  } catch (error) {
    window.TTS = tts;
  }
})();
