local function spacer()
    return ui.Span(" ")
end

local function owner()
    local h = cx.active.current.hovered
    if not h or not h.cha.uid or not h.cha.gid then
        return ui.Span("")
    end

    local user = ya.user_name(h.cha.uid) or h.cha.uid
    local group = ya.group_name(h.cha.gid) or h.cha.gid

    return ui.Line(string.format("%s:%s ", user, group))
end

local function mtime()
    local h = cx.active.current.hovered
    if not h then
        return ui.Span("")
    end

    if not h.cha.mtime then
        return ui.Span("")
    end

    return ui.Span(os.date("%Y-%m-%d %H:%M", h.cha.mtime // 1) .. " ")
end

local function perms()
    local h = cx.active.current.hovered
    if not h then
        return ""
    end

    local perm = h.cha:perm()
    if not perm then
        return ""
    end

    local spans = {}
    for i = 1, #perm do
        local c = perm:sub(i, i)
        local style = { fg = "green" }
        if c == "-" or c == "?" then
            style = { fg = "darkgray" }
        elseif c == "r" then
            style = { fg = "yellow" }
        elseif c == "w" then
            style = { fg = "red" }
        elseif c == "x" or c == "s" or c == "S" or c == "t" or c == "T" then
            style = { fg = "cyan" }
        end
        spans[i] = ui.Span(c):style(style)
    end
    return ui.Line(spans)
end

local function freedisk()
    local handle = assert(io.popen('df --human-readable --output=avail "$PWD" | tail -n1 | xargs'))
    local free = handle:read("*a")
    handle:close()
    return ui.Span(free)
end

return {
    setup = function()
        Status:children_remove(1, Status.LEFT) -- mode
        Status:children_remove(2, Status.LEFT) -- size
        Status:children_remove(3, Status.LEFT) -- name
        Status:children_remove(4, Status.RIGHT) -- permissions
        Status:children_remove(5, Status.RIGHT) -- percentage
        Status:children_remove(6, Status.RIGHT) -- position

        Status:children_add(perms, 1, Status.LEFT)
        Status:children_add(spacer, 2, Status.LEFT)
        Status:children_add(owner, 3, Status.LEFT)
        Status:children_add(mtime, 4, Status.LEFT)
        Status:children_add(freedisk, 5, Status.RIGHT)
    end,
}
