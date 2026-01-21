--[[
SPDX-License-Identifier: MPL-2.0
Author: cqmpact <https://github.com/cqmpact>

Contributors
| Name    | Profile                     | Notes  |
|-------- |-----------------------------|--------|
| cqmpact | https://github.com/cqmpact  | Author |
|         |                             |        |
]]

RegisterNetEvent('cq-admin:sv:debugToggle', function(kind, enabled, radius)
    local src = source
    local group = GROUPS.debugToggle
    if not hasGroup(src, group) then return deny(src, 'debugToggle:'..tostring(kind), group) end
    issueGrant(src, 'debugToggle', 'cq-admin:cl:debugToggle', tostring(kind or ''), enabled and true or false, tonumber(radius) or 50.0)
end)

