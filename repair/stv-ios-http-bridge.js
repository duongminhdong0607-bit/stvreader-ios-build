/*
 * STV MobileReader iOS bridge for the original Android Http plugin.
 * Uses Capacitor v7's native CapacitorHttp. No credentials or identifiers
 * are generated; STV's original JS builds the request headers.
 */
(() => {
  'use strict';
  const SERVER = 'sangtacviet.com';
  function install() {
    const cap = window.Capacitor;
    const plugins = cap && cap.Plugins;
    if (!plugins) return false;
    if (plugins.Http) return true;
    const builtIn = plugins.CapacitorHttp;
    const callNative = (method, options) => {
      if (builtIn && typeof builtIn[method] === 'function') {
        return builtIn[method](options);
      }
      if (typeof cap.nativePromise === 'function') {
        return cap.nativePromise('CapacitorHttp', method, options);
      }
      return Promise.reject(new Error('CapacitorHttp not available'));
    };
    if (!builtIn && typeof cap.nativePromise !== 'function') return false;

    async function request(options) {
      const target = new URL(options?.url || '', window.location.href);
      if (target.protocol !== 'https:' || target.hostname !== SERVER) {
        throw new Error('Native HTTP only supports sangtacviet.com');
      }
      const method = (options.method || 'GET').toUpperCase();
      const args = {
        ...options,
        url: target.href,
        headers: {...(options.headers || {})},
        method,
        connectTimeout: Number(options.timeout || 10000),
        readTimeout: Number(options.timeout || 10000)
      };
      const response = await callNative('request', args);
      if (!response || typeof response.status !== 'number') {
        throw new Error('Invalid native HTTP response');
      }
      return {
        ...response,
        data: typeof response.data === 'string'
          ? response.data
          : JSON.stringify(response.data ?? '')
      };
    }
    plugins.Http = {
      __stvIOSBridge: true,
      get(options) { return request({ ...options, method:'GET' }); },
      post(options) { return request({ ...options, method:'POST' }); },
      request
    };
    return true;
  }
  if (!install()) {
    const poll = setInterval(() => { if (install()) clearInterval(poll); }, 1);
    setTimeout(() => clearInterval(poll), 30000);
  }
})();
