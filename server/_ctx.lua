--[[
SPDX-License-Identifier: MPL-2.0
Author: cqmpact <https://github.com/cqmpact>

Contributors
| Name    | Profile                     | Notes  |
|-------- |-----------------------------|--------|
| cqmpact | https://github.com/cqmpact  | Author |
|         |                             |        |
]]

local internal = (CQAdmin and CQAdmin._internal) or {}
hasGroup = internal.hasGroup or function() return false end
deny = internal.deny or function() return end
issueGrant = internal.issueGrant or function() return end
notify = internal.notify or function() return end
GROUPS = internal.GROUPS or GROUPS

if CQAdmin and CQAdmin._internal then
    CQAdmin._internal.hasGroup = nil
    CQAdmin._internal.deny = nil
    CQAdmin._internal.issueGrant = nil
    CQAdmin._internal.notify = nil
    CQAdmin._internal.GROUPS = nil
end
