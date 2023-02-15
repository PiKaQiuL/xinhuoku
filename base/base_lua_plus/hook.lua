local string_find = string.find

function string.find(...)
    local start_pos, end_pos = string_find(...)
    string.find_end_pos = end_pos
    return start_pos, end_pos
end

function string.find_end()
    return string.find_end_pos
end