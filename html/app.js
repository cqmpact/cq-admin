/*
SPDX-License-Identifier: MPL-2.0
Author: cqmpact <https://github.com/cqmpact>

Contributors
| Name    | Profile                     | Notes  |
|-------- |-----------------------------|--------|
| cqmpact | https://github.com/cqmpact  | Author |
|         |                             |        |
*/

const getParentResourceNameSafe = () => {
  if (typeof GetParentResourceName === "function") return GetParentResourceName();
  return "dev-resource";
};

const notifyRoot = document.getElementById("notifyRoot");
const canvas = document.getElementById("imguiCanvas");

const state = {
  visible: false,
  quiet: true,
  freeControl: false,
};

const setVisible = (v) => {
  state.visible = !!v;
  if (canvas) canvas.classList.toggle("hidden", !state.visible);
  setFreeControl(false);
};

const setFreeControl = (v) => {
  state.freeControl = !!v;
  if (canvas) {
    canvas.style.pointerEvents = state.freeControl ? "none" : "auto";
    canvas.style.opacity = state.freeControl ? "0.5" : "1";
  }
};

const resizeCanvas = () => {
  if (!canvas) return;
  const w = Math.max(1, Math.floor(window.innerWidth));
  const h = Math.max(1, Math.floor(window.innerHeight));
  canvas.style.width = `${w}px`;
  canvas.style.height = `${h}px`;
  if (moduleInstance && typeof moduleInstance.setCanvasSize === "function") {
    moduleInstance.setCanvasSize(w, h);
  } else {
    canvas.width = w;
    canvas.height = h;
  }
};

const notify = (message, type = "info", timeout = 2500) => {
  if (!notifyRoot) return;
  const kind = String(type || "info");
  if (state.quiet && kind === "info") return;
  const item = document.createElement("div");
  item.className = `notify ${kind}`;
  item.textContent = message;
  notifyRoot.appendChild(item);
  const t = setTimeout(() => item.remove(), timeout);
  item.addEventListener("click", () => {
    clearTimeout(t);
    item.remove();
  });
};

const postNui = async (callbackName, payload = {}) => {
  const res = getParentResourceNameSafe();
  const url = `https://${res}/${callbackName}`;
  const r = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json; charset=UTF-8" },
    body: JSON.stringify(payload),
  }).catch(() => null);
  if (!r) return null;
  let data = await r.json().catch(async () => "");
  if (data && typeof data === "object") {
    const msg = data.message || data.msg || data.notify;
    const type =
      data.type ||
      data.level ||
      (data.ok === false ? "error" : data.ok === true ? "success" : "info");
    if (msg) notify(String(msg), String(type));
  }
  return data;
};

window.postNui = postNui;

let moduleInstance = null;
const pendingCalls = [];

const callWasm = (fn, ...args) => {
  if (!moduleInstance) {
    pendingCalls.push(() => callWasm(fn, ...args));
    return;
  }
  if (typeof moduleInstance[fn] === "function") {
    moduleInstance[fn](...args);
  }
};

const initImGui = () => {
  if (typeof CQAdminImGui !== "function") return;
  CQAdminImGui({
    canvas,
    locateFile: (path) => path,
  }).then((instance) => {
    moduleInstance = instance;
    resizeCanvas();
    while (pendingCalls.length) pendingCalls.shift()();
  });
};

window.addEventListener("message", (event) => {
  const msg = event.data;
  if (!msg || typeof msg !== "object") return;
  switch (msg.action) {
    case "cq:menu:open": {
      if (msg.data) {
        if (typeof msg.data.quiet === "boolean") state.quiet = msg.data.quiet;
        callWasm("cq_set_data", msg.data);
      }
      setFreeControl(false);
      callWasm("cq_set_free_control", false);
      callWasm("cq_set_visible", true);
      setVisible(true);
      break;
    }
    case "cq:menu:close": {
      setFreeControl(false);
      callWasm("cq_set_free_control", false);
      callWasm("cq_set_visible", false);
      setVisible(false);
      break;
    }
    case "cq:menu:setData": {
      if (msg.data) callWasm("cq_set_data", msg.data);
      break;
    }
    case "cq:menu:notify": {
      const { type = "info", message = "", timeout = 2500 } = msg;
      notify(message, type, timeout);
      break;
    }
    case "cq:menu:hint": {
      const hint =
        typeof msg.text === "string"
          ? msg.text
          : typeof msg.html === "string"
          ? msg.html
          : "";
      callWasm("cq_set_hint", hint);
      break;
    }
    case "cq:menu:setFreeControl": {
      setFreeControl(!!msg.enabled);
      callWasm("cq_set_free_control", !!msg.enabled);
      break;
    }
  }
});

const bootstrap = () => {
  const inFiveM = typeof GetParentResourceName === "function";
  setVisible(!inFiveM);
  resizeCanvas();
  window.addEventListener("resize", resizeCanvas);
  initImGui();
};

bootstrap();
