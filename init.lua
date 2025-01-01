local function linesbackward(filename)
    local file = assert(io.open(filename))
    local chunk_size = 4*1024
    local iterator = function() return "" end
    local tail = ""
    local chunk_index = math.ceil(file:seek"end" / chunk_size)
    return
    function()
        while true do
            local lineEOL, line = iterator()
            if lineEOL ~= "" then
                if line ~= nil then
                    return line:reverse()
                end
            end
            repeat
                chunk_index = chunk_index - 1
                if chunk_index < 0 then
                    file:close()
                    iterator = function()
                        error('No more lines in file "'..filename..'"', 3)
                    end
                    return
                end
                file:seek("set", chunk_index * chunk_size)
                local chunk = file:read(chunk_size)
                local pattern = "^(.-"..(chunk_index > 0 and "\n" or "")..")(.*)"
                local new_tail, lines = chunk:match(pattern)
                iterator = lines and (lines..tail):reverse():gmatch"(\n?\r?([^\n]*))"
                tail = new_tail or chunk..tail
            until iterator
        end
    end
end

local function get_last_line(filepath)
    local fileptr = assert(io.open(filepath, "a+"))
    local eof = fileptr:seek("end")
    for i = 2, eof do
        fileptr:seek("set", eof - i)
        if i == eof then break end
        if fileptr:read(1) == '\n' then break end
    end
    local lastLine = fileptr:read("*a"):gsub("\n", "")
    fileptr:close()
    return lastLine
end

local function escape_special_chars(str)
    return str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%0")
end

local function save_last_hovered(hovered, cachepath)
    local cachefileptr = assert(io.open(cachepath, "r"))
    local content = cachefileptr:read("*a")
    cachefileptr:close()
    content = content:gsub(escape_special_chars(hovered) .. "\n", '')
    io.open(cachepath, "w"):close()
    cachefileptr = assert(io.open(cachepath, "w"))
    cachefileptr:write(content, "")
    cachefileptr:close()
    cachefileptr = assert(io.open(cachepath, "a"))
    cachefileptr:write(hovered, "\n")
    cachefileptr:close()
end

local function get_last_hovered_for_cwd(cachepath)
    local cwd = cx.active.current.cwd
    for line in linesbackward(cachepath) do
        local position = string.find(line, escape_special_chars(tostring(cwd)) .. "/[^/]*$")
        if position ~= nil then
            return line
        end
    end
end

local function setup()
    local cachedir = os.getenv("HOME") .. "/.cache/yazi-hover-history"
    os.execute("mkdir -p " .. cachedir)
    local cachepath = cachedir .. "/history.txt"
    local last_hovered = get_last_line(cachepath)
    ps.sub("hover", function()
        local hovered = tostring(cx.active.current.hovered.url)
        -- avoid continuously writing the cachpath to the cachefile
        if hovered ~= cachepath then
            save_last_hovered(hovered, cachepath)
        end
    end)
    ps.sub("cd", function ()
        local hovered_cwd = get_last_hovered_for_cwd(cachepath)
        if hovered_cwd ~= nil then
            ya.manager_emit("hidden", { "show" })
            ya.manager_emit("reveal", { hovered_cwd })
        end
    end)
    ya.manager_emit("cd", { last_hovered:match("(.*/)") })
end

return { setup = setup }
