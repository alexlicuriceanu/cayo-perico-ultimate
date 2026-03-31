-- get the keys of a table.
-- @param t The table to get the keys from.
-- @return keys A sorted table containing the keys of the input table.
function get_keys(t)
    local keys = {}

    for key, _ in pairs(t) do
        table.insert(keys, key)
    end

    table.sort(keys)
    return keys
end