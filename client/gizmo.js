/*
SPDX-License-Identifier: MPL-2.0
Author: cqmpact <https://github.com/cqmpact>

Contributors
| Name    | Profile                     | Notes  |
|-------- |-----------------------------|--------|
| cqmpact | https://github.com/cqmpact  | Author |
|         |                             |        |
*/

const wait = (ms) => new Promise((r) => setTimeout(r, ms));

const _len3 = (x, y, z) => Math.sqrt(x * x + y * y + z * z) || 0;
const _norm3 = (x, y, z) => {
  const l = _len3(x, y, z);
  if (l <= 1e-6) return [0, 0, 0];
  return [x / l, y / l, z / l];
};
const _dot3 = (ax, ay, az, bx, by, bz) => ax * bx + ay * by + az * bz;
const _sub3 = (ax, ay, az, bx, by, bz) => [ax - bx, ay - by, az - bz];
const _cross3 = (ax, ay, az, bx, by, bz) => [
  ay * bz - az * by,
  az * bx - ax * bz,
  ax * by - ay * bx,
];

const sanitizeNoScale = (mat) => {
  if (!(mat instanceof Float32Array) || mat.length !== 16) return mat;
  let rx = mat[0], ry = mat[1], rz = mat[2];
  let fx = mat[4], fy = mat[5], fz = mat[6];
  let ux = mat[8], uy = mat[9], uz = mat[10];
  [fx, fy, fz] = _norm3(fx, fy, fz);
  const projUonF = _dot3(ux, uy, uz, fx, fy, fz);
  [ux, uy, uz] = _sub3(ux, uy, uz, fx * projUonF, fy * projUonF, fz * projUonF);
  [ux, uy, uz] = _norm3(ux, uy, uz);
  [rx, ry, rz] = _cross3(fx, fy, fz, ux, uy, uz);
  [rx, ry, rz] = _norm3(rx, ry, rz);
  [ux, uy, uz] = _cross3(rx, ry, rz, fx, fy, fz);
  [ux, uy, uz] = _norm3(ux, uy, uz);
  mat[0] = rx; mat[1] = ry; mat[2] = rz;
  mat[4] = fx; mat[5] = fy; mat[6] = fz;
  mat[8] = ux; mat[9] = uy; mat[10] = uz;
  mat[3] = 0; mat[7] = 0; mat[11] = 0; mat[15] = 1;
  return mat;
};

const loadModel = async (modelName) => {
  const hash = typeof modelName === 'number' ? modelName : GetHashKey(String(modelName));
  if (!IsModelInCdimage(hash)) return null;
  RequestModel(hash);
  for (let i = 0; i < 500; i++) {
    if (HasModelLoaded(hash)) return hash;
    await wait(10);
  }
  return HasModelLoaded(hash) ? hash : null;
};

const makeEntityMatrix = (entity) => {
  const [f, r, u, a] = GetEntityMatrix(entity);
  return new Float32Array([
    r[0], r[1], r[2], 0,
    f[0], f[1], f[2], 0,
    u[0], u[1], u[2], 0,
    a[0], a[1], a[2], 1,
  ]);
};

const applyEntityMatrix = (entity, mat) => {
  SetEntityMatrix(
    entity,
    mat[4], mat[5], mat[6],
    mat[0], mat[1], mat[2],
    mat[8], mat[9], mat[10],
    mat[12], mat[13], mat[14]
  );
};

const highlight = (entity, enabled) => {
  if (!DoesEntityExist(entity)) return;
  SetEntityDrawOutline(entity, !!enabled);
};

const getForwardPlacement = (origin, fwd, dist) => [origin[0] + fwd[0] * dist, origin[1] + fwd[1] * dist, origin[2] + fwd[2] * dist];

const GizmoState = {
  active: false,
  ghost: 0,
  model: null,
  mat: null,
  tickHandle: null,
  framesNoChange: 0,
};

const stopTick = () => {
  if (!GizmoState.tickHandle) return;
  if (typeof clearTick === 'function') clearTick(GizmoState.tickHandle);
  GizmoState.tickHandle = null;
};

const resetState = () => {
  if (GizmoState.ghost && DoesEntityExist(GizmoState.ghost)) {
    SetEntityDrawOutline(GizmoState.ghost, false);
    DeleteEntity(GizmoState.ghost);
  }
  GizmoState.active = false;
  GizmoState.ghost = 0;
  GizmoState.model = null;
  GizmoState.mat = null;
};

let lastDebugEnt = 0;
let gizmoToggle = false;

const startGizmoForModel = async (modelName) => {
  if (GizmoState.active) return finalizePlacement();

  const hash = await loadModel(modelName);
  if (!hash) {
    if (typeof SendNuiMessage === 'function') {
      SendNuiMessage(JSON.stringify({ action: 'cq:menu:notify', type: 'error', message: `Model not found: ${modelName}` }));
    }
    return;
  }

  const ped = PlayerPedId();
  const [px, py, pz] = GetEntityCoords(ped, true);
  const [fx, fy, fz] = GetEntityForwardVector(ped);
  let [x, y, z] = getForwardPlacement([px, py, pz], [fx, fy, fz], 2.0);
  z += 0.2;
  RequestCollisionAtCoord(x, y, z);
  let ghost = 0;
  for (let attempt = 0; attempt < 3 && (!ghost || ghost === 0); attempt++) {
    if (attempt === 0) ghost = CreateObjectNoOffset(hash, x, y, z, false, false, true);
    else if (attempt === 1) ghost = CreateObjectNoOffset(hash, x, y, z, true, true, false);
    else ghost = CreateObject(hash, x, y, z, true, true, false);
    if (!ghost || ghost === 0) await wait(10);
  }
  if (!ghost || ghost === 0) {
    if (typeof SendNuiMessage === 'function') {
      SendNuiMessage(JSON.stringify({ action: 'cq:menu:notify', type: 'error', message: `Failed to create ghost for ${modelName}` }));
    }
    return;
  }

  SetEntityAsMissionEntity(ghost, true, true);
  SetEntityCollision(ghost, false, false);
  FreezeEntityPosition(ghost, true);
  SetEntityAlpha(ghost, 180, false);
  PlaceObjectOnGroundProperly(ghost);

  GizmoState.active = true;
  GizmoState.ghost = ghost;
  GizmoState.model = modelName;
  GizmoState.mat = makeEntityMatrix(ghost);
  GizmoState.framesNoChange = 0;
  highlight(ghost, true);
  lastDebugEnt = ghost;
  gizmoToggle = true;
  emit('cq-admin:ib:show', [
    { control: '~INPUT_FRONTEND_ACCEPT~', label: 'Confirm' },
    { control: '~INPUT_FRONTEND_CANCEL~', label: 'Cancel' },
    { control: '~INPUT_ATTACK~', label: 'Drag manipulate' },
    { control: '~INPUT_MP_TEXT_CHAT_ALL~', label: 'Translate mode' },
    { control: '~INPUT_CREATOR_LS~', label: 'Rotate mode' },
  ]);
  if (typeof SendNuiMessage === 'function') {
    SendNuiMessage(JSON.stringify({ action: 'cq:menu:close' }));
  }
  if (typeof SetNuiFocus === 'function') SetNuiFocus(false, false);
  const DISABLES = [
    1, 2,
    24, 25, 257, 140, 141, 142,
    37, 14, 15,
    30, 31, 32, 33, 21, 22, 44, 45,
    199, 200,
    245, 250,
  ];

  EnterCursorMode();
  SetMouseCursorStyle(4);

  GizmoState.tickHandle = setTick(() => {
      if (!GizmoState.active) return;
      SetInputExclusive(0, 239);
      SetInputExclusive(0, 240);
      for (const code of DISABLES) {
        DisableControlAction(0, code, true);
      }
      InvalidateIdleCam();
      InvalidateVehicleIdleCam();

      const wasRReleased = IsDisabledControlJustReleased(0, 25) || IsControlJustReleased(0, 25);
      if (wasRReleased) {
        gizmoToggle = !gizmoToggle;
      }
      const wasLReleased = IsDisabledControlJustReleased(0, 24) || IsControlJustReleased(0, 24);
      if (wasLReleased && lastDebugEnt) {
        highlight(lastDebugEnt, false);
      }
      const ent = DoesEntityExist(GizmoState.ghost) ? GizmoState.ghost : lastDebugEnt;
      if (!ent || !DoesEntityExist(ent)) return;
      let buf = GizmoState.mat;
      if (!(buf instanceof Float32Array) || buf.length !== 16) {
        buf = makeEntityMatrix(ent);
      }

      const changed = DrawGizmo(buf, 'AdminPropGizmo');
      if (changed) {
        const clean = sanitizeNoScale(buf);
        GizmoState.mat = clean;
        applyEntityMatrix(ent, clean);
        GizmoState.framesNoChange = 0;
      } else {
        GizmoState.framesNoChange++;
        if (GizmoState.framesNoChange > 120) {
          GizmoState.mat = makeEntityMatrix(ent);
          GizmoState.framesNoChange = 0;
        }
      }
      highlight(ent, true);
      if (IsDisabledControlJustPressed(0, 191) || IsControlJustPressed(0, 191)) {
        finalizePlacement();
      }
      if (IsDisabledControlJustPressed(0, 202) || IsControlJustPressed(0, 202) || IsDisabledControlJustPressed(0, 200) || IsControlJustPressed(0, 200)) {
        cancelPlacement();
      }
  });
};

const VState = {
  active: false,
  ghost: 0,
  model: null,
  tickHandle: null,
};

const vReset = () => {
  if (VState.ghost && DoesEntityExist(VState.ghost)) {
    SetEntityDrawOutline(VState.ghost, false);
    DeleteEntity(VState.ghost);
  }
  VState.active = false;
  VState.ghost = 0;
  VState.model = null;
  if (VState.tickHandle) { if (typeof clearTick === 'function') clearTick(VState.tickHandle); VState.tickHandle = null; }
};

const startVehicleGizmoForModel = async (modelName) => {
  if (VState.active) return finalizeVehiclePlacement();
  const hash = await loadModel(modelName);
  if (!hash) {
    if (typeof SendNuiMessage === 'function') {
      SendNuiMessage(JSON.stringify({ action: 'cq:menu:notify', type: 'error', message: `Vehicle not found: ${modelName}` }));
    }
    return;
  }

  const ped = PlayerPedId();
  const [px, py, pz] = GetEntityCoords(ped, true);
  const [fx, fy, fz] = GetEntityForwardVector(ped);
  let [x, y, z] = getForwardPlacement([px, py, pz], [fx, fy, fz], 3.0);
  z += 0.3;
  RequestCollisionAtCoord(x, y, z);

  let veh = CreateVehicle(hash, x, y, z, GetEntityHeading(ped) || 0.0, false, false);
  if (!veh || veh === 0) {
    if (typeof SendNuiMessage === 'function') {
      SendNuiMessage(JSON.stringify({ action: 'cq:menu:notify', type: 'error', message: `Failed to create ghost vehicle: ${modelName}` }));
    }
    return;
  }
  SetEntityAsMissionEntity(veh, true, true);
  SetEntityCollision(veh, false, false);
  SetEntityInvincible(veh, true);
  SetEntityProofs(veh, true, true, true, true, true, true, true, true, true);
  SetEntityAlpha(veh, 160, false);
  SetVehicleDoorsLocked(veh, 4);
  SetVehicleUndriveable(veh, true);
  SetVehRadioStation(veh, 'OFF');
  SetVehicleOnGroundProperly(veh);
  FreezeEntityPosition(veh, true);

  VState.active = true;
  VState.ghost = veh;
  VState.model = modelName;
  highlight(veh, true);
  if (typeof SendNuiMessage === 'function') {
    SendNuiMessage(JSON.stringify({ action: 'cq:menu:close' }));
  }
  if (typeof SetNuiFocus === 'function') SetNuiFocus(false, false);
  EnterCursorMode();
  SetMouseCursorStyle(4);

  const DISABLES = [1,2,24,25,257,140,141,142,37,14,15,30,31,32,33,21,22,44,45,199,200,245,250];
  const gizmoStart = GetEntityCoords(PlayerPedId(), true);
  const originX = gizmoStart[0], originY = gizmoStart[1], originZ = gizmoStart[2];
  const MAX_DIST = 30.0;

  const _clampToMaxDistance = (clean) => {
    let tx = clean[12] || 0.0, ty = clean[13] || 0.0, tz = clean[14] || 0.0;
    const dx = tx - originX, dy = ty - originY, dz = tz - originZ;
    const dist = Math.sqrt(dx*dx + dy*dy + dz*dz);
    if (dist > MAX_DIST) {
      const s = MAX_DIST / (dist || 1.0);
      tx = originX + dx * s;
      ty = originY + dy * s;
      tz = originZ + dz * s;
      clean[12] = tx; clean[13] = ty; clean[14] = tz;
    }
    return clean;
  };

  VState.tickHandle = setTick(() => {
      if (!VState.active) return;
      SetInputExclusive(0, 239); SetInputExclusive(0, 240);
      for (const code of DISABLES) DisableControlAction(0, code, true);
      InvalidateIdleCam(); InvalidateVehicleIdleCam();

      const ent = VState.ghost;
      if (!ent || !DoesEntityExist(ent)) return;
      let buf = makeEntityMatrix(ent);
      const changed = DrawGizmo(buf, 'AdminVehicleGizmo');
      if (changed) {
        let clean = sanitizeNoScale(buf);
        clean = _clampToMaxDistance(clean);
        FreezeEntityPosition(ent, false);
        applyEntityMatrix(ent, clean);
        { const cx = clean[12] || 0.0, cy = clean[13] || 0.0, cz = clean[14] || 0.0; RequestCollisionAtCoord(cx, cy, cz); }
        SetVehicleOnGroundProperly(ent);
        FreezeEntityPosition(ent, true);
      }
      highlight(ent, true);

      if (IsDisabledControlJustPressed(0, 191) || IsControlJustPressed(0, 191)) finalizeVehiclePlacement();
      if (IsDisabledControlJustPressed(0, 202) || IsControlJustPressed(0, 202) || IsDisabledControlJustPressed(0, 200) || IsControlJustPressed(0, 200)) cancelVehiclePlacement();
  });
  emit('cq-admin:ib:show', [
    { control: '~INPUT_FRONTEND_ACCEPT~', label: 'Confirm' },
    { control: '~INPUT_FRONTEND_CANCEL~', label: 'Cancel' },
    { control: '~INPUT_ATTACK~', label: 'Drag manipulate' },
    { control: '~INPUT_MP_TEXT_CHAT_ALL~', label: 'Translate mode' },
    { control: '~INPUT_CREATOR_LS~', label: 'Rotate mode' },
  ]);
};

const finalizeVehiclePlacement = () => {
  if (!VState.active || !DoesEntityExist(VState.ghost)) { vReset(); return; }
  const ent = VState.ghost;
  const model = VState.model;
  const [x, y, z] = GetEntityCoords(ent, true);
  const heading = GetEntityHeading(ent) || 0.0;
  highlight(ent, false);
  DeleteEntity(ent);
  LeaveCursorMode();
  vReset();
  emit('cq-admin:ib:hide');
  emitNet('cq-admin:sv:spawnVehicleAt', model, x, y, z, heading);
  if (typeof SendNuiMessage === 'function') {
    SendNuiMessage(JSON.stringify({ action: 'cq:menu:open' }));
  }
  if (typeof SetNuiFocus === 'function') SetNuiFocus(true, true);
};

const cancelVehiclePlacement = () => {
  if (VState.ghost && DoesEntityExist(VState.ghost)) { highlight(VState.ghost, false); DeleteEntity(VState.ghost); }
  LeaveCursorMode();
  vReset();
  emit('cq-admin:ib:hide');
  if (typeof SendNuiMessage === 'function') {
    SendNuiMessage(JSON.stringify({ action: 'cq:menu:open' }));
  }
  if (typeof SetNuiFocus === 'function') SetNuiFocus(true, true);
};

const finalizePlacement = () => {
  if (!GizmoState.active || !DoesEntityExist(GizmoState.ghost)) { resetState(); return; }

  const ent = GizmoState.ghost;
  const model = GizmoState.model;
  const [x, y, z] = GetEntityCoords(ent, true);
  const heading = GetEntityHeading(ent) || 0.0;
  highlight(ent, false);
  DeleteEntity(ent);
  LeaveCursorMode();
  emitNet('cq-admin:sv:spawnObjectAt', model, x, y, z, heading);
  GizmoState.active = false;
  GizmoState.ghost = 0;
  GizmoState.model = null;
  GizmoState.mat = null;
  stopTick();
  emit('cq-admin:ib:hide');
  if (typeof SendNuiMessage === 'function') {
    SendNuiMessage(JSON.stringify({ action: 'cq:menu:open' }));
  }
  if (typeof SetNuiFocus === 'function') SetNuiFocus(true, true);
};

const cancelPlacement = () => {
  if (GizmoState.ghost && DoesEntityExist(GizmoState.ghost)) {
    highlight(GizmoState.ghost, false);
    DeleteEntity(GizmoState.ghost);
  }
  GizmoState.active = false;
  GizmoState.ghost = 0;
  GizmoState.model = null;
  GizmoState.mat = null;
  LeaveCursorMode();
  stopTick();
  emit('cq-admin:ib:hide');
  if (typeof SendNuiMessage === 'function') {
    SendNuiMessage(JSON.stringify({ action: 'cq:menu:open' }));
  }
  if (typeof SetNuiFocus === 'function') SetNuiFocus(true, true);
};

const __grants = new Map();
const __grantAdd = (reqId, action, ttlMs = 15000) => {
  if (!reqId || !action) return;
  __grants.set(reqId, { exp: GetGameTimer() + ttlMs, action });
};
const __grantConsume = (reqId, action) => {
  if (!reqId || !action) return false;
  const entry = __grants.get(reqId);
  if (!entry) return false;
  __grants.delete(reqId);
  if (entry.action !== action) return false;
  return entry.exp >= GetGameTimer();
};

onNet('cq-admin:cl:grant', (reqId, action, _otp) => {
  if (typeof reqId === 'string' && reqId.length > 0 && typeof action === 'string' && action.length > 0) {
    __grantAdd(reqId, action, 15000);
  }
});

onNet('cq-admin:cl:spawnObject', (reqId, model) => {
  if (!__grantConsume(reqId, 'spawnObject')) return;
  if (typeof model === 'string' && model.length > 0) startGizmoForModel(model);
});

onNet('cq-admin:cl:spawnVehicleGizmo', (reqId, model) => {
  if (!__grantConsume(reqId, 'spawnVehicleGizmo')) return;
  if (typeof model === 'string' && model.length > 0) startVehicleGizmoForModel(model);
});

onNet('cq-admin:cl:spawnObjectAt', async (reqId, model, x, y, z, heading) => {
  if (!__grantConsume(reqId, 'spawnObjectAt')) return;
  const hash = await loadModel(model);
  if (!hash) return;
  const obj = CreateObjectNoOffset(hash, x || 0.0, y || 0.0, z || 0.0, true, true, false);
  if (obj) {
    SetEntityHeading(obj, heading || 0.0);
    PlaceObjectOnGroundProperly(obj);
  }
});

onNet('cq-admin:cl:spawnVehicleAt', async (reqId, model, x, y, z, heading) => {
  if (!__grantConsume(reqId, 'spawnVehicleAt')) return;
  const hash = await loadModel(model);
  if (!hash) return;
  const veh = CreateVehicle(hash, x || 0.0, y || 0.0, z || 0.0, heading || 0.0, true, false);
  if (veh) {
    SetEntityAsMissionEntity(veh, true, true);
    SetVehicleOnGroundProperly(veh);
    SetEntityCollision(veh, true, true);
    SetEntityInvincible(veh, false);
    SetVehicleUndriveable(veh, false);
  }
});

exports('startGizmoForModel', startGizmoForModel);
exports('finalizePlacement', finalizePlacement);
exports('cancelPlacement', cancelPlacement);

RegisterNuiCallbackType('cq-admin:cb:spawnObject');
on('__cfx_nui:cq-admin:cb:spawnObject', async(data, cb) => {
  const model = (data && (data.model ?? data.payload ?? data.value)) || '';
  if (typeof model === 'string' && model.length > 0) {
    emitNet('cq-admin:sv:spawnObject', model);
    cb && cb({ ok: true });
  } else {
    cb && cb({ ok: false, message: 'Invalid model' });
  }
});

RegisterNuiCallbackType('cq-admin:cb:spawnVehicleGizmo');
on('__cfx_nui:cq-admin:cb:spawnVehicleGizmo', async(data, cb) => {
  const model = (data && (data.model ?? data.payload ?? data.value)) || '';
  if (typeof model === 'string' && model.length > 0) {
    emitNet('cq-admin:sv:spawnVehicleGizmo', model);
    cb && cb({ ok: true });
  } else {
    cb && cb({ ok: false, message: 'Invalid model' });
  }
});

on('onResourceStop', (resName) => {
  if (typeof GetCurrentResourceName === 'function' && resName !== GetCurrentResourceName()) return;
  emit('cq-admin:ib:hide');
  cancelPlacement();
  cancelVehiclePlacement();
});

RegisterNuiCallbackType('cq-admin:cb:spawnObject:confirm');
on('__cfx_nui:cq-admin:cb:spawnObject:confirm', (_data, cb) => {
  finalizePlacement();
  cb && cb({ ok: true });
});

RegisterNuiCallbackType('cq-admin:cb:spawnObject:cancel');
on('__cfx_nui:cq-admin:cb:spawnObject:cancel', (_data, cb) => {
  cancelPlacement();
  cb && cb({ ok: true });
});
