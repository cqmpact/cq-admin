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

const postNui = async (callbackName, payload = {}) => {
  const res = getParentResourceNameSafe();
  const url = `https://${res}/${callbackName}`;
  const r = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json; charset=UTF-8" },
    body: JSON.stringify(payload),
  }).catch(() => null);
  if (!r) return null;
  let data = await r.json().catch(async () => await r.text());
  if (data && typeof data === 'object') {
    const msg = data.message || data.msg || data.notify;
    const type = data.type || data.level || (data.ok === false ? 'error' : (data.ok === true ? 'success' : 'info'));
    if (msg) notify(String(msg), String(type));
  }
  return data;
};

const state = {
  visible: false,
  pinned: false,
  freeControl: false,
  data: { title: "Menu", effects: [], globalGroups: [], callbacks: {} },
  search: "",
  activeToTop: false,
  collapsed: new Set(),
  selectedEffectId: null,
  values: {},
  quiet: true,
};

const root = document.getElementById("root");
const windowEl = document.getElementById("window");
const menuTitle = document.getElementById("menuTitle");
const searchInput = document.getElementById("searchInput");
const effectList = document.getElementById("effectList");
const detailTitle = document.getElementById("detailTitle");
const detailPanel = document.getElementById("detailPanel");
const hintText = document.getElementById("hintText");
const emptyStateEl = document.getElementById("emptyState");
const notifyRoot = document.getElementById("notifyRoot");

const initDefaultsFromData = (data) => {
  const values = { ...state.values };
  const visit = (node) => {
    if (!node) return;
    if (Array.isArray(node)) return node.forEach(visit);
    if (node.type === "group") return visit(node.children);
    if (node.key != null && values[node.key] === undefined) {
      values[node.key] = node.default ?? null;
    }
  };
  visit(data.globalGroups);
  for (const fx of data.effects || []) visit(fx.groups);
  state.values = values;
};

const setVisible = (v) => {
  state.visible = v;
  root.classList.toggle("hidden", !v);
  if (v) setTimeout(() => searchInput?.focus(), 0);
};

const setFreeControl = (v) => {
  state.freeControl = !!v;
  windowEl.classList.toggle("free-control", state.freeControl);
  const btn = document.getElementById("btnMouse");
  if (btn) btn.setAttribute("aria-pressed", state.freeControl ? "true" : "false");
  if (state.freeControl) {
    hintText.textContent = "Free control enabled — press F10 to refocus";
  } else {
    hintText.textContent = state.pinned ? "Pinned (Esc disabled)" : "Esc to close";
  }
};

const setData = (newData) => {
  state.data = newData;
  if (!state.selectedEffectId && (newData.effects?.length ?? 0) > 0) {
    state.selectedEffectId = newData.effects[0].id;
  }
  initDefaultsFromData(newData);
  render();
};

const filterEffects = (effects) => {
  const q = (state.search || "").trim().toLowerCase();
  let list = effects || [];
  if (q) {
    list = list.filter((e) => {
      const s = `${e.label ?? ""} ${e.sub ?? ""}`.toLowerCase();
      return s.includes(q);
    });
  }
  if (state.activeToTop) {
    list = [...list].sort((a, b) => Number(!!b.enabled) - Number(!!a.enabled));
  }
  return list;
};

const renderEffectList = () => {
  effectList.innerHTML = "";
  const effects = filterEffects(state.data.effects || []);
  for (const fx of effects) {
    const row = document.createElement("div");
    row.className =
      "effect-row" + (fx.id === state.selectedEffectId ? " selected" : "");
    row.setAttribute("role", "listitem");
    const name = document.createElement("div");
    name.className = "effect-name";
    const title = document.createElement("div");
    title.className = "effect-title";
    title.textContent = fx.label ?? "(unnamed)";
    const sub = document.createElement("div");
    sub.className = "effect-sub";
    sub.textContent = fx.sub ?? "";
    name.appendChild(title);
    name.appendChild(sub);
    row.appendChild(name);
    row.addEventListener("click", () => {
      state.selectedEffectId = fx.id;
      postNui(state.data.callbacks?.selectEffect || "selectEffect", { id: fx.id });
      renderEffectList();
      renderRightPanel();
    });
    effectList.appendChild(row);
  }
};

const isGroupCollapsed = (groupId) => state.collapsed.has(groupId);

const toggleGroup = (groupId) => {
  if (state.collapsed.has(groupId)) state.collapsed.delete(groupId);
  else state.collapsed.add(groupId);
};

const createControl = (control) => {
  const row = document.createElement("div");
  row.className = "control";
  const label = document.createElement("div");
  label.className = "control-label";
  label.textContent = control.label ?? "";
  const right = document.createElement("div");
  right.className = "control-right";
  const cb = control.callback;
  const fire = (payload, cbName) => {
    const target = cbName || cb;
    if (target) postNui(target, payload);
  };
  switch (control.type) {
    case "button": {
      const btn = document.createElement("button");
      btn.className = "ui-btn";
      btn.type = "button";
      btn.textContent = control.buttonLabel ?? "Run";
      btn.addEventListener("click", () => {
        const payload = { ...(control.meta || {}), ...(control.payload || {}) };
        if (control.stateKeys && Array.isArray(control.stateKeys)) {
          for (const key of control.stateKeys) {
            if (state.values[key] !== undefined) {
              payload[key] = state.values[key];
            }
          }
        }
        fire(payload);
      });
      right.appendChild(btn);
      break;
    }
    case "toggle": {
      const box = document.createElement("div");
      box.className = "ui-check" + (state.values[control.key] ? " on" : "");
      box.addEventListener("click", () => {
        const next = !state.values[control.key];
        state.values[control.key] = next;
        box.classList.toggle("on", next);
        fire({ key: control.key, value: next, ...(control.meta || {}) });
      });
      right.appendChild(box);
      break;
    }
    case "slider": {
      const range = document.createElement("input");
      range.className = "ui-range";
      range.type = "range";
      range.min = String(control.min ?? 0);
      range.max = String(control.max ?? 1);
      range.step = String(control.step ?? 0.01);
      const key = control.key;
      const cur = state.values[key];
      range.value = cur != null ? String(cur) : String(control.default ?? 0);
      const num = document.createElement("input");
      num.className = "ui-num";
      num.type = "number";
      num.step = String(control.step ?? 0.01);
      num.min = String(control.min ?? 0);
      num.max = String(control.max ?? 1);
      num.value = range.value;
      const push = (v) => {
        const clamped = Math.min(
          Number(control.max ?? v),
          Math.max(Number(control.min ?? v), Number(v))
        );
        state.values[key] = clamped;
        range.value = String(clamped);
        num.value = String(clamped);
        fire({ key, value: clamped, ...(control.meta || {}) });
      };
      range.addEventListener("input", () => push(range.value));
      num.addEventListener("change", () => push(num.value));
      right.appendChild(range);
      right.appendChild(num);
      break;
    }
    case "select":
    case "dropdown": {
      const sel = document.createElement("select");
      sel.className = "ui-select";
      const key = control.key;
      for (const opt of control.options || []) {
        const o = document.createElement("option");
        o.value = String(opt);
        o.textContent = String(opt);
        sel.appendChild(o);
      }
      const cur = state.values[key];
      sel.value = cur != null ? String(cur) : String(control.default ?? "");
      sel.addEventListener("change", () => {
        state.values[key] = sel.value;
        fire({ key, value: sel.value, ...(control.meta || {}) });
      });
      right.appendChild(sel);
      break;
    }
    case "inputButton": {
      const input = document.createElement("input");
      input.className = "ui-text";
      input.type = "text";
      input.placeholder = control.placeholder ?? "";
      input.autocomplete = "off";
      const btn = document.createElement("button");
      btn.className = "ui-btn";
      btn.type = "button";
      btn.textContent = control.buttonLabel ?? "Go";
      const payloadKey = control.payloadKey || "value";
      const go = () => {
        const v = input.value ?? "";
        fire({ [payloadKey]: v, ...(control.meta || {}) });
      };
      btn.addEventListener("click", go);
      input.addEventListener("keydown", (e) => {
        if (e.key === "Enter") go();
      });
      if (control.inlineToggle && typeof control.inlineToggle === 'object') {
        const it = control.inlineToggle;
        const wrap = document.createElement('label');
        wrap.className = 'inline-toggle';
        const checkbox = document.createElement('input');
        checkbox.type = 'checkbox';
        checkbox.className = 'ui-toggle';
        const key = it.key;
        if (key != null && state.values[key] == null) {
          state.values[key] = it.default ?? false;
        }
        const cur = key != null ? !!state.values[key] : !!it.default;
        checkbox.checked = cur;
        const span = document.createElement('span');
        span.textContent = String(it.label ?? '');
        wrap.appendChild(checkbox);
        wrap.appendChild(span);
        checkbox.addEventListener('change', () => {
          const enabled = !!checkbox.checked;
          if (key != null) state.values[key] = enabled;
          if (it.callback) {
            fire({ key, enabled, value: enabled, ...(it.meta || {}) }, it.callback);
          }
        });
        right.appendChild(wrap);
      }
      right.appendChild(input);
      right.appendChild(btn);
      break;
    }
    case "textarea": {
      const textarea = document.createElement("textarea");
      textarea.className = "ui-textarea";
      textarea.rows = control.rows || 4;
      textarea.placeholder = control.placeholder || "";
      textarea.value = state.values[control.key] || control.default || "";
      textarea.addEventListener("change", () => {
        state.values[control.key] = textarea.value;
        fire({ key: control.key, value: textarea.value, ...(control.meta || {}) });
      });
      right.appendChild(textarea);
      break;
    }
    case "number": {
      const input = document.createElement("input");
      input.className = "ui-num";
      input.type = "number";
      input.min = String(control.min ?? 0);
      input.max = String(control.max ?? 999999);
      input.step = String(control.step ?? 1);
      const key = control.key;
      const cur = state.values[key];
      input.value = cur != null ? String(cur) : String(control.default ?? 0);
      input.addEventListener("change", () => {
        const val = parseFloat(input.value) || 0;
        state.values[key] = val;
        fire({ key, value: val, ...(control.meta || {}) });
      });
      right.appendChild(input);
      break;
    }
    case "colorPicker": {
      const wrapper = document.createElement("div");
      wrapper.className = "color-picker-wrapper";
      const key = control.key;
      const defaultColor = control.default || { r: 255, g: 255, b: 255 };
      if (!state.values[key]) {
        state.values[key] = defaultColor;
      }
      const preview = document.createElement("div");
      preview.className = "color-preview";
      const updatePreview = () => {
        const c = state.values[key] || defaultColor;
        preview.style.backgroundColor = `rgb(${c.r}, ${c.g}, ${c.b})`;
      };
      updatePreview();
      let popup = null;
      let closeHandler = null;
      let escHandler = null;
      let resizeHandler = null;
      let scrollHandler = null;
      const scrollContainer = () => preview.closest('.ui-detail-scroll');
      const positionPopup = () => {
        if (!popup) return;
        const rect = preview.getBoundingClientRect();
        // Ensure measured size is available
        const pw = popup.offsetWidth;
        const ph = popup.offsetHeight;
        const margin = 6;
        let left = rect.left;
        let top = rect.bottom + margin;
        const vw = window.innerWidth;
        const vh = window.innerHeight;
        if (left + pw > vw - 8) left = Math.max(8, vw - pw - 8);
        if (left < 8) left = 8;
        if (top + ph > vh - 8) top = Math.max(8, rect.top - ph - margin);
        if (top < 8) top = 8;
        popup.style.left = `${left}px`;
        popup.style.top = `${top}px`;
      };
      const closePopup = () => {
        if (popup) {
          popup.remove();
          popup = null;
        }
        if (closeHandler) {
          document.removeEventListener("click", closeHandler);
          closeHandler = null;
        }
        if (escHandler) {
          document.removeEventListener('keydown', escHandler);
          escHandler = null;
        }
        if (resizeHandler) {
          window.removeEventListener('resize', resizeHandler);
          resizeHandler = null;
        }
        if (scrollHandler) {
          const sc = scrollContainer();
          if (sc) sc.removeEventListener('scroll', scrollHandler, { passive: true });
          scrollHandler = null;
        }
      };
      preview.addEventListener("click", (e) => {
        e.stopPropagation();
        if (popup) {
          closePopup();
          return;
        }
        popup = createColorPickerPopup(state.values[key] || defaultColor, (newColor) => {
          state.values[key] = newColor;
          updatePreview();
          fire({ key, value: newColor, ...(control.meta || {}) });
        }, closePopup);
        // Mount to body as a portal to avoid clipping by .ui-window overflow
        if (popup) {
          popup.style.position = 'fixed';
          popup.style.visibility = 'hidden';
          document.body.appendChild(popup);
          // Position after mount so sizes are known
          requestAnimationFrame(() => {
            if (!popup) return;
            positionPopup();
            popup.style.visibility = 'visible';
          });
        }
        closeHandler = (ev) => {
          if (!popup) return;
          // Close when click is outside both the trigger wrapper and the popup itself
          if (!(wrapper.contains(ev.target) || popup.contains(ev.target))) {
            closePopup();
          }
        };
        escHandler = (ev) => {
          if (ev.key === 'Escape') closePopup();
        };
        resizeHandler = () => positionPopup();
        scrollHandler = () => positionPopup();
        setTimeout(() => {
          if (!popup) return;
          document.addEventListener("click", closeHandler);
          document.addEventListener('keydown', escHandler);
          window.addEventListener('resize', resizeHandler);
          const sc = scrollContainer();
          if (sc) sc.addEventListener('scroll', scrollHandler, { passive: true });
        }, 0);
      });
      wrapper.appendChild(preview);
      right.appendChild(wrapper);
      break;
    }
    default: {
      const txt = document.createElement("div");
      txt.style.color = "rgba(235,238,244,0.6)";
      txt.textContent = `(unsupported control type: ${control.type})`;
      right.appendChild(txt);
      break;
    }
  }
  row.appendChild(label);
  row.appendChild(right);
  return row;
};

const createGroup = (group) => {
  const wrap = document.createElement("section");
  wrap.className = "group";
  const header = document.createElement("div");
  header.className = "group-header";
  const left = document.createElement("div");
  left.className = "left";
  const caret = document.createElement("span");
  caret.className = "group-caret";
  caret.textContent = isGroupCollapsed(group.id) ? "▸" : "▾";
  const title = document.createElement("div");
  title.className = "group-title";
  title.textContent = group.label ?? "";
  left.appendChild(caret);
  left.appendChild(title);
  header.appendChild(left);
  header.addEventListener("click", () => {
    toggleGroup(group.id);
    renderRightPanel();
  });
  wrap.appendChild(header);
  if (!isGroupCollapsed(group.id)) {
    const body = document.createElement("div");
    body.className = "group-body";
    const children = group.children || [];
    for (const c of children) {
      if (c.type === "group") body.appendChild(createGroup(c));
      else body.appendChild(createControl(c));
    }
    wrap.appendChild(body);
  }
  return wrap;
};

const renderRightPanel = () => {
  menuTitle.textContent = state.data.title ?? "Menu";
  const selected = (state.data.effects || []).find((e) => e.id === state.selectedEffectId);
  detailTitle.textContent = selected ? selected.label : "Details";
  detailPanel.innerHTML = "";
  for (const g of state.data.globalGroups || []) {
    detailPanel.appendChild(createGroup(g));
  }
  if (selected?.groups?.length) {
    for (const g of selected.groups) {
      if (g.type === "group") detailPanel.appendChild(createGroup(g));
    }
  } else {
    const empty = document.createElement("div");
    empty.style.color = "rgba(235,238,244,0.6)";
    empty.textContent = "No details available.";
    detailPanel.appendChild(empty);
  }
};

const render = () => {
  const hasAny = ((state.data.effects?.length || 0) + (state.data.globalGroups?.length || 0)) > 0;
  if (emptyStateEl) emptyStateEl.classList.toggle("hidden", hasAny);
  renderEffectList();
  renderRightPanel();
};

searchInput.addEventListener("input", () => {
  state.search = searchInput.value;
  renderEffectList();
});

document.getElementById("btnActiveToTop").addEventListener("click", () => {
  state.activeToTop = !state.activeToTop;
  document.getElementById("btnActiveToTop").classList.toggle("ui-btn-toggle", state.activeToTop);
  renderEffectList();
});

document.getElementById("btnCollapseAll").addEventListener("click", () => {
  const collectGroups = (arr, out) => {
    for (const x of arr || []) {
      if (x?.type === "group") {
        out.push(x.id);
        collectGroups(x.children, out);
      }
    }
  };
  const ids = [];
  collectGroups(state.data.globalGroups, ids);
  const selected = (state.data.effects || []).find((e) => e.id === state.selectedEffectId);
  collectGroups(selected?.groups || [], ids);
  const allCollapsed = ids.length > 0 && ids.every((id) => state.collapsed.has(id));
  if (allCollapsed) ids.forEach((id) => state.collapsed.delete(id));
  else ids.forEach((id) => state.collapsed.add(id));
  renderRightPanel();
});

document.getElementById("btnReload").addEventListener("click", () => {
  postNui(state.data.callbacks?.reload || "reload", {});
});

document.getElementById("btnPin").addEventListener("click", () => {
  state.pinned = !state.pinned;
  if (!state.freeControl) {
    hintText.textContent = state.pinned ? "Pinned (Esc disabled)" : "Esc to close";
  }
});

document.getElementById("btnMouse").addEventListener("click", () => {
  setFreeControl(!state.freeControl);
  postNui("cq-admin:cb:toggleFreeControl", { enabled: state.freeControl });
});

window.addEventListener("keydown", (e) => {
  if (!state.visible) return;
  if (e.key === "Escape" && !state.pinned) {
    postNui(state.data.callbacks?.close || "closeMenu", {});
    setVisible(false);
  }
});

window.addEventListener("message", (event) => {
  const msg = event.data;
  if (!msg || typeof msg !== "object") return;
  switch (msg.action) {
    case "cq:menu:open": {
      if (msg.data) {
        // Inherit quiet flag from client payload (defaults to true)
        if (typeof msg.data.quiet === "boolean") state.quiet = msg.data.quiet;
        setData(msg.data);
      }
      setFreeControl(false);
      setVisible(true);
      break;
    }
    case "cq:menu:close": {
      setFreeControl(false);
      setVisible(false);
      break;
    }
    case "cq:menu:setData": {
      if (msg.data) setData(msg.data);
      break;
    }
    case "cq:menu:notify": {
      const { type = "info", message = "", timeout = 2500 } = msg;
      notify(message, type, timeout);
      break;
    }
    case "cq:menu:hint": {
      if (typeof msg.html === "string") {
        hintText.innerHTML = msg.html;
      } else if (typeof msg.text === "string") {
        hintText.textContent = msg.text;
      }
      break;
    }
    case "cq:menu:setFreeControl": {
      setFreeControl(!!msg.enabled);
      break;
    }
  }
});

const bootstrap = () => {
  const inFiveM = typeof GetParentResourceName === "function";
  setVisible(!inFiveM);
  render();
};

bootstrap();

const notify = (message, type = "info", timeout = 2500) => {
  if (!notifyRoot) return;
  const kind = String(type || 'info');
  // Respect quiet mode: suppress informational toasts when enabled
  if (state.quiet && kind === 'info') return;
  const item = document.createElement("div");
  item.className = `notify ${kind}`;
  item.textContent = message;
  notifyRoot.appendChild(item);
  const t = setTimeout(() => item.remove(), timeout);
  item.addEventListener("click", () => { clearTimeout(t); item.remove(); });
};

const createColorPickerPopup = (initialColor, onChange, onClose) => {
  const popup = document.createElement("div");
  popup.className = "color-picker-popup";
  const container = document.createElement("div");
  container.className = "color-wheel-container";
  const canvas = document.createElement("canvas");
  canvas.className = "color-wheel-canvas";
  canvas.width = 200;
  canvas.height = 200;
  const cursor = document.createElement("div");
  cursor.className = "color-wheel-cursor";
  const ctx = canvas.getContext("2d");
  const centerX = 100;
  const centerY = 100;
  const radius = 100;
  for (let angle = 0; angle < 360; angle++) {
    const startAngle = (angle - 90) * Math.PI / 180;
    const endAngle = (angle - 89) * Math.PI / 180;
    ctx.beginPath();
    ctx.moveTo(centerX, centerY);
    ctx.arc(centerX, centerY, radius, startAngle, endAngle);
    ctx.closePath();
    const gradient = ctx.createRadialGradient(centerX, centerY, 0, centerX, centerY, radius);
    gradient.addColorStop(0, 'white');
    gradient.addColorStop(1, `hsl(${angle}, 100%, 50%)`);
    ctx.fillStyle = gradient;
    ctx.fill();
  }
  let currentColor = { ...initialColor };
  const updateCursorPosition = (r, g, b) => {
    r = r / 255;
    g = g / 255;
    b = b / 255;
    const max = Math.max(r, g, b);
    const min = Math.min(r, g, b);
    const d = max - min;
    let h = 0, s = 0;
    s = max === 0 ? 0 : d / max;
    if (d !== 0) {
      if (max === r) h = ((g - b) / d + (g < b ? 6 : 0)) / 6;
      else if (max === g) h = ((b - r) / d + 2) / 6;
      else h = ((r - g) / d + 4) / 6;
    }
    const angle = h * 2 * Math.PI - Math.PI / 2;
    const distance = s * radius;
    const x = centerX + distance * Math.cos(angle);
    const y = centerY + distance * Math.sin(angle);
    cursor.style.left = x + "px";
    cursor.style.top = y + "px";
  };
  updateCursorPosition(currentColor.r, currentColor.g, currentColor.b);
  const handleColorSelect = (e) => {
    const rect = canvas.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;
    const dx = x - centerX;
    const dy = y - centerY;
    const distance = Math.sqrt(dx * dx + dy * dy);
    if (distance > radius) return;
    let angle = Math.atan2(dy, dx);
    if (angle < 0) angle += 2 * Math.PI;
    const hue = (angle * 180 / Math.PI + 90) % 360;
    const saturation = Math.min(distance / radius, 1);
    const value = 1.0;
    const c = value * saturation;
    const x2 = c * (1 - Math.abs(((hue / 60) % 2) - 1));
    const m = value - c;
    let r, g, b;
    if (hue < 60) { r = c; g = x2; b = 0; }
    else if (hue < 120) { r = x2; g = c; b = 0; }
    else if (hue < 180) { r = 0; g = c; b = x2; }
    else if (hue < 240) { r = 0; g = x2; b = c; }
    else if (hue < 300) { r = x2; g = 0; b = c; }
    else { r = c; g = 0; b = x2; }
    currentColor = {
      r: Math.round((r + m) * 255),
      g: Math.round((g + m) * 255),
      b: Math.round((b + m) * 255)
    };
    rInput.value = currentColor.r;
    gInput.value = currentColor.g;
    bInput.value = currentColor.b;
    cursor.style.left = x + "px";
    cursor.style.top = y + "px";
    onChange(currentColor);
  };
  canvas.addEventListener("mousedown", (e) => {
    handleColorSelect(e);
    const onMove = (e2) => handleColorSelect(e2);
    const onUp = () => {
      document.removeEventListener("mousemove", onMove);
      document.removeEventListener("mouseup", onUp);
    };
    document.addEventListener("mousemove", onMove);
    document.addEventListener("mouseup", onUp);
  });
  container.appendChild(canvas);
  container.appendChild(cursor);
  popup.appendChild(container);
  const inputs = document.createElement("div");
  inputs.className = "color-inputs";
  const createInput = (label, value, onChange) => {
    const group = document.createElement("div");
    group.className = "color-input-group";
    const labelEl = document.createElement("div");
    labelEl.className = "color-input-label";
    labelEl.textContent = label;
    const input = document.createElement("input");
    input.className = "color-input-value";
    input.type = "number";
    input.min = "0";
    input.max = "255";
    input.value = value;
    input.addEventListener("input", () => {
      const val = Math.max(0, Math.min(255, parseInt(input.value) || 0));
      input.value = val;
      onChange(val);
    });
    group.appendChild(labelEl);
    group.appendChild(input);
    return { group, input };
  };
  const rGroup = createInput("R", currentColor.r, (v) => {
    currentColor.r = v;
    updateCursorPosition(currentColor.r, currentColor.g, currentColor.b);
    onChange(currentColor);
  });
  const gGroup = createInput("G", currentColor.g, (v) => {
    currentColor.g = v;
    updateCursorPosition(currentColor.r, currentColor.g, currentColor.b);
    onChange(currentColor);
  });
  const bGroup = createInput("B", currentColor.b, (v) => {
    currentColor.b = v;
    updateCursorPosition(currentColor.r, currentColor.g, currentColor.b);
    onChange(currentColor);
  });
  const rInput = rGroup.input;
  const gInput = gGroup.input;
  const bInput = bGroup.input;
  inputs.appendChild(rGroup.group);
  inputs.appendChild(gGroup.group);
  inputs.appendChild(bGroup.group);
  popup.appendChild(inputs);
  const actions = document.createElement("div");
  actions.className = "color-picker-actions";
  const closeBtn = document.createElement("button");
  closeBtn.className = "ui-btn";
  closeBtn.textContent = "Close";
  closeBtn.addEventListener("click", (e) => {
    e.stopPropagation();
    onClose();
  });
  actions.appendChild(closeBtn);
  popup.appendChild(actions);
  return popup;
};

(() => {
  const titlebar = document.querySelector(".ui-titlebar");
  if (!titlebar || !windowEl) return;
  let dragging = false;
  let startX = 0, startY = 0, startLeft = 0, startTop = 0;
  const onMove = (e) => {
    if (!dragging) return;
    const dx = e.clientX - startX;
    const dy = e.clientY - startY;
    let left = startLeft + dx;
    let top = startTop + dy;
    const vw = window.innerWidth;
    const vh = window.innerHeight;
    const rect = windowEl.getBoundingClientRect();
    const w = rect.width;
    const h = rect.height;
    left = Math.min(vw - w, Math.max(0, left));
    top = Math.min(vh - h, Math.max(0, top));
    windowEl.style.left = left + "px";
    windowEl.style.top = top + "px";
  };

  const onUp = () => {
    if (!dragging) return;
    dragging = false;
    document.removeEventListener("mousemove", onMove);
    document.removeEventListener("mouseup", onUp);
  };

  titlebar.addEventListener("mousedown", (e) => {
    if (e.target.closest(".ui-titlebar-actions")) return;
    dragging = true;
    startX = e.clientX;
    startY = e.clientY;
    const rect = windowEl.getBoundingClientRect();
    startLeft = rect.left;
    startTop = rect.top;
    document.addEventListener("mousemove", onMove);
    document.addEventListener("mouseup", onUp);
  });
})();
