local e_cmd = base.eff.e_cmd

local function check_target_filter(target_filter)
    return (type(target_filter) == 'table' and type(target_filter.validate) == 'function')
end

function base.target_filter_validate(过滤, 过滤单位, 基准单位)
    ---name1 过滤
    ---name2 基准单位
    ---name3 过滤单位
    if check_target_filter(过滤) then
        local base_unit = (基准单位 or 过滤单位)
        return 过滤:validate(过滤单位, base_unit) == e_cmd.OK
    else
        return false
    end
end

function base.unit_group_filter_group(单位组, 过滤, 基准单位)
    ---name1 过滤单位组
    ---name2 过滤
    ---name3 基准的单位
    if check_target_filter(过滤) then
        local units = {}
        if 基准单位 then
            for k, _ in pairs(单位组:get_items_map()) do
                if 过滤:validate(基准单位, k) == e_cmd.OK then
                    units[# units + 1] = k
                end
            end
        else
            for k, _ in pairs(单位组:get_items_map()) do
                if 过滤:validate(k, k) == e_cmd.OK then
                    units[# units + 1] = k
                end
            end
        end
        return base.单位组(units)
    else
        return base.单位组{}
    end
end