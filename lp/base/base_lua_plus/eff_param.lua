--- lua_plus ---
function base.eff_param_origin_point(eff_param:eff_param)point
    ---@ui ~1~的原始施法点
    ---@belong eff_param
    ---@description 效果节点的原始施法点
    ---@applicable value
    ---@name1 效果节点
    ---@arg1 效果节点
    if eff_param_check(eff_param) then
        return eff_param:origin():get_point()
    end
    return nil
end
 ---@keyword 施法 点
function base.eff_param_get_link(eff_param:eff_param)effect_id
    ---@ui ~1~的Id
    ---@belong eff_param
    ---@description 效果节点的Id
    ---@applicable value
    ---@name1 效果节点
    ---@arg1 效果节点
    if eff_param_check(eff_param) then
        return eff_param.link
    end
    return nil
end
 ---@keyword 施法 点
function base.unit_execute_effect_on_unit(unit:unit, target:unit, link:effect_id)
    ---@ui 令~1~对~2~执行效果~3~
    ---@belong eff_param
    ---@description 执行效果(对单位)
    ---@applicable action
    ---@name1 单位
    ---@name2 目标单位
    ---@arg1 base.get_last_created_unit()
    ---@arg2 e.unit
    if unit_check(unit) then
        unit:execute_on(target, link)
    end
end
 ---@keyword 执行 单位
function base.unit_execute_effect_on_point(unit:unit, target:point, link:effect_id)
    ---@ui 令~1~对~2~执行效果~3~
    ---@belong eff_param
    ---@description 执行效果(对点)
    ---@applicable action
    ---@name1 单位
    ---@name2 目标点
    ---@arg1 e.unit
    if unit_check(unit) then
        unit:execute_on(target, link)
    end
end
 ---@keyword 执行 点
function base.eff_param_missle_detach(eff_param:eff_param)
    ---@ui 解绑~1~的弹道
    ---@belong eff_param
    ---@description 解绑效果节点的弹道
    ---@applicable action
    ---@name1 效果节点
    ---@arg1 效果节点
    if eff_param_check(eff_param) then
        eff_param:missile_detach()
    end
end
 ---@keyword 解绑 弹道
function base.eff_param_missle_get(eff_param:eff_param)unit
    ---@ui ~1~挂载的弹道单位
    ---@belong eff_param
    ---@description 效果节点挂载的弹道单位
    ---@applicable value
    ---@arg1 效果节点
    if eff_param_check(eff_param) then
        return eff_param.missile
    end
end
 ---@keyword 弹道
function base.eff_param_missle_range(eff_param:eff_param)number
    ---@ui ~1~挂载的弹道的射程
    ---@belong eff_param
    ---@description 效果节点挂载的弹道的射程
    ---@applicable value
    ---@arg1 效果节点
    if eff_param_check(eff_param) then
        if not(eff_param.missile_data) then
            return 0
        end
        return or(eff_param.missile_data.missile_range, 0)
    end
end
 ---@keyword 弹道
function base.eff_param_set_damage_modifiers(eff_param:eff_param, unit:unit)
    ---@ui 设置~1~的施法加成属性来源为~2~
    ---@belong eff_param
    ---@description 设置效果节点的施法加成属性来源
    ---@applicable action
    ---@arg1 效果节点
    if eff_param_check(eff_param) then
        eff_param:set_damage_modifiers(unit, true)
    end
end
 ---@keyword 设置 加成
function base.eff_param_source_item(eff_param:eff_param)item
    ---@ui ~1~的引发物品
    ---@belong eff_param
    ---@description 效果节点的引发物品
    ---@applicable value
    ---@arg1 效果节点
    if and(eff_param_check(eff_param), eff_param.shared, eff_param.shared.item, eff_param.shared.item.unit) then
        return eff_param.shared.item
    end
    return nil
end
 ---@keyword 物品
function base.eff_param_responsing_param(eff_param:eff_param)eff_param
    ---@ui ~1~的引发响应的效果节点
    ---@belong eff_param
    ---@description 效果节点的引发响应的效果节点
    ---@applicable value
    ---@arg1 效果节点
    if and(eff_param_check(eff_param), eff_param.respond_args, eff_param.respond_args.eff_param) then
        return eff_param.respond_args.eff_param
    end
    return nil
end
 ---@keyword 物品
function base.eff_param_responsing_skill(eff_param:eff_param)skill
    ---@ui ~1~的引发响应的技能
    ---@belong eff_param
    ---@description 效果节点的引发响应的技能
    ---@applicable value
    ---@arg1 效果节点
    if and(eff_param_check(eff_param), eff_param.respond_args, eff_param.respond_args.skill) then
        return eff_param.respond_args.skill
    end
    return nil
end
 ---@keyword 物品
function base.eff_param_responsing_damage(eff_param:eff_param)damage
    ---@ui ~1~的引发响应的伤害实例
    ---@belong eff_param
    ---@description 效果节点的引发响应的伤害实例
    ---@applicable value
    ---@arg1 效果节点
    if and(eff_param_check(eff_param), eff_param.respond_args, eff_param.respond_args.damage) then
        return eff_param.respond_args.damage
    end
    return nil
end
 ---@keyword 物品
function base.eff_param_caster(eff_param:eff_param)unit
    ---@ui ~1~的施法者
    ---@belong eff_param
    ---@description 效果节点的施法者
    ---@applicable value
    ---@arg1 效果节点
    if eff_param_check(eff_param) then
        return eff_param:caster():get_unit()
    end
    return nil
end
 ---@keyword 施法者
function base.eff_param_main_target_point(eff_param:eff_param)point
    ---@ui ~1~的效果树主目标（点）
    ---@belong eff_param
    ---@description 效果节点的效果树主目标（点）
    ---@applicable value
    ---@arg1 效果节点
    if eff_param_check(eff_param) then
        local scene:unknown = eff_param:get_scene()
        return eff_param:main_target():copy_to_scene_point(scene)
    end
    return nil
end

 ---@keyword 主目标
function base.eff_param_main_target_unit(eff_param:eff_param)unit
    ---@ui ~1~的效果树主目标（单位）
    ---@belong eff_param
    ---@description 效果节点的效果树主目标（单位）
    ---@applicable value
    ---@arg1 效果节点
    if eff_param_check(eff_param) then
        return eff_param:main_target():get_unit()
    end
    return nil
end
 ---@keyword 主目标
function base.eff_param_target_point(eff_param:eff_param)point
    ---@ui ~1~的目标点
    ---@belong eff_param
    ---@description 效果节点的目标点
    ---@applicable value
    ---@arg1 效果节点
    if eff_param_check(eff_param) then
        local scene:unknown = eff_param:get_scene()
        return eff_param.target:get_point():copy_to_scene_point(scene)
    end
    return nil
end

 ---@keyword 目标 点
function base.eff_param_target_unit(eff_param:eff_param)unit
    ---@ui ~1~的目标单位
    ---@belong eff_param
    ---@description 效果节点的目标单位
    ---@applicable value
    ---@arg1 效果节点
    if eff_param_check(eff_param) then
        return eff_param.target:get_unit()
    end
    return nil
end
 ---@keyword 目标 单位
function base.eff_param_has_target(eff_param:eff_param)boolean
    ---@ui ~1~拥有目标单位
    ---@belong eff_param
    ---@description 效果节点是否拥有目标单位
    ---@applicable value
    ---@arg1 效果节点
    if eff_param_check(eff_param) then
        return (eff_param.target:get_unit() == nil)
    end
    return false
end
 ---@keyword 目标 单位
function base.eff_param_get_root(eff_param:eff_param)eff_param
    ---@ui ~1~的根节点
    ---@belong eff_param
    ---@description 效果节点的效果树根节点
    ---@applicable value
    ---@arg1 效果节点
    if eff_param_check(eff_param) then
        return eff_param:root()
    end
    return nil
end
 ---@keyword 根节点
function base.eff_param_get_parent(eff_param:eff_param)eff_param
    ---@ui ~1~的父节点
    ---@belong eff_param
    ---@description 效果节点的效果树父节点
    ---@applicable value
    ---@arg1 效果节点
    if eff_param_check(eff_param) then
        return eff_param.parent
    end
    return nil
end
 ---@keyword 父节点
function base.eff_param_get_by_name(eff_param:eff_param, effect_id_name:effect_id)eff_param
    ---@ui ~1~的类型为~2~的祖先节点
    ---@belong eff_param
    ---@description 效果节点的指定类型祖先节点
    ---@applicable value
    ---@arg1 祖先效果id
    ---@arg2 效果节点
    if eff_param_check(eff_param) then
        return eff_param:search(effect_id_name)
    end
    return nil
end
 ---@keyword 祖先节点
function base.eff_param_get_level(eff_param:eff_param)number
    ---@ui ~1~的技能等级快照
    ---@belong eff_param
    ---@description 效果节点的技能等级快照
    ---@applicable value
    ---@arg1 效果节点
    if eff_param_check(eff_param) then
        return eff_param:get_level()
    end
    return nil
end
 ---@keyword 等级
function base.eff_param_get_skill(eff_param:eff_param)skill
    ---@ui ~1~的引发技能
    ---@belong eff_param
    ---@description 效果节点的引发技能
    ---@applicable value
    ---@arg1 效果节点
    if eff_param_check(eff_param) then
        return eff_param:skill()
    end
    return nil
end
 ---@keyword 引发 技能
function base.eff_param_get_var_unit(eff_param:eff_param, key:string)unit
    ---@ui ~1~单位变量~2~
    ---@belong eff_param
    ---@description 效果节点保存的单位变量
    ---@applicable value
    ---@arg1 "A"
    ---@arg2 效果节点
    if eff_param_check(eff_param) then
        return eff_param:var_unit(key)
    end
end
 ---@keyword 变量 单位
function base.eff_param_get_var_point(eff_param:eff_param, key:string)point
    ---@ui ~1~点变量~2~
    ---@belong eff_param
    ---@description 效果节点保存的点变量
    ---@applicable value
    ---@arg1 "A"
    ---@arg2 效果节点
    if eff_param_check(eff_param) then
        return eff_param:var_point(key)
    end
end
 ---@keyword 变量 点
function base.eff_param_set_var_unit(eff_param:eff_param, key:string, value:unit)
    ---@ui 设置~1~及其子孙节点的单位变量~2~值为~3~
    ---@belong eff_param
    ---@description 设置效果节点的单位变量
    ---@applicable action
    ---@arg1 "A"
    ---@arg2 效果节点
    if and(eff_param_check(eff_param), unit_check(value)) then
        return eff_param:set_var_unit(key, value)
    end
end
 ---@keyword 变量 单位
function base.eff_param_set_var_point(eff_param:eff_param, key:string, value:point)
    ---@ui 设置~1~及其子孙节点的点变量~2~值为~3~
    ---@belong eff_param
    ---@description 设置效果节点的点变量
    ---@applicable action
    ---@arg1 "A"
    ---@arg2 效果节点
    if and(eff_param_check(eff_param), point_check(value)) then
        return eff_param:set_var_point(key, value)
    end
end
 ---@keyword 变量 点
function base.eff_param_get_userdata(eff_param:eff_param, key:string)number
    ---@ui ~1~的效果树自定义值~2~
    ---@belong eff_param
    ---@description 效果节点的效果树自定义值
    ---@applicable value
    ---@arg1 效果节点
    if eff_param_check(eff_param) then
        return eff_param:user_data()[key]
    end
end
 ---@keyword 自定义值 树
function base.eff_param_get_cache(eff_param:eff_param)table
    ---@ui ~1~的数据表
    ---@belong eff_param
    ---@description 效果节点的类型数据
    ---@applicable value
    ---@arg1 效果节点
    if eff_param_check(eff_param) then
        return eff_param.cache
    end
end
 ---@keyword 效果 表
function base.eff_param_get_node_in_module(eff_param:eff_param, name:string)table
    ---@ui 获取~1~同模块下的~2~数据表
    ---@belong eff_param
    ---@description 效果节点的兄弟数据
    ---@applicable value
    ---@arg1 ''
    ---@arg2 效果节点
    if eff_param_check(eff_param) then
        return eff_param:get_node_in_module(name)
    end
end
 ---@keyword 兄弟 表
-- function base.eff_param_missle(eff_param:eff_param) unit
--     ---@ui ~1~的投射物单位
--     if eff_param ~= nil then
--         return eff_param.missle
--     end
-- end

-- function base.eff_param_link(eff_param:eff_param) string
--     ---@ui ~1~的参数表
--     if eff_param ~= nil then
--         return eff_param.link
--     end
-- end

-- function base.eff_param_missle_range(eff_param:eff_param) number
--     ---@ui ~1~的弹道范围
--     if eff_param ~= nil then
--         return eff_param.missle_range
--     end
-- end

local e_cmd:unknown = base.eff.e_cmd

function base.validator_unit_filter(eff_param:eff_param, unit:效果节点单位位置, filters:string)验证器代码
    ---@ui ~1~的目标~2~符合过滤~3~
    ---@belong eff_param
    ---@description 单位过滤
    ---@applicable value
    ---@selectable false
    ---@arg1 '敌方;自身,无敌'
    ---@arg2 效果节点单位位置["Target"]
    ---@arg3 ref_param
    if eff_param_check(eff_param) then
        local target:unknown = eff_param:get_site_target(unit):get_unit()
        if not(unit) then
            return e_cmd.MustTargetUnit
        end
        local target_filter:unknown = base.target_filters:new(filters)
        return target_filter:validate(eff_param:caster(), target)
    end
    return e_cmd.Error
end
 ---@keyword 过滤
function base.validator_unit_filter_new(eff_param:eff_param, unit:效果节点单位位置, filters:target_filter)验证器代码
    ---@ui ~1~的目标~2~符合过滤~3~
    ---@belong eff_param
    ---@description 单位过滤
    ---@applicable value
    ---@arg1 base.target_filters:new(target_filter_string_root["敌方;自身,无敌"])
    ---@arg2 效果节点单位位置["Target"]
    ---@arg3 ref_param
    if eff_param_check(eff_param) then
        local target:unknown = eff_param:get_site_target(unit):get_unit()
        if not(unit) then
            return e_cmd.MustTargetUnit
        end
        return filters:validate(eff_param:caster(), target)
    end
    return e_cmd.Error
end
 ---@keyword 过滤
function base.validator_condition(condition:boolean)验证器代码
    ---@ui 验证器满足条件~1~
    ---@belong eff_param
    ---@description 满足触发器条件
    ---@applicable value
    if condition then
        return e_cmd.OK
    end
    return e_cmd.Error
end
 ---@keyword 满足 条件
function base.validator_and(code1:验证器代码, code2:验证器代码)验证器代码
    ---@ui ~1~与~2~
    ---@belong eff_param
    ---@description 验证器“与”操作
    ---@applicable value
    if and(code1 == e_cmd.OK, code2 == e_cmd.OK) then
        return e_cmd.OK
    elseif code1 == e_cmd.OK then
        return code2
    end
    return code1
end
 ---@keyword 与
function base.validator_or(code1:验证器代码, code2:验证器代码)验证器代码
    ---@ui ~1~或~2~
    ---@belong eff_param
    ---@description 验证器“或”操作
    ---@applicable value
    if or(code1 == e_cmd.OK, code2 == e_cmd.OK) then
        return e_cmd.OK
    end
    return code1
end
 ---@keyword 或
function base.validator_not(code1:验证器代码)验证器代码
    ---@ui 非~1~
    ---@belong eff_param
    ---@description 验证器“非”操作
    ---@applicable value
    if code1 ~= e_cmd.OK then
        return e_cmd.OK
    end
    return e_cmd.Error
end



 ---@keyword 非
function base.validator_unit_has_buff(eff_param:eff_param, unit:效果节点单位位置, buff_id_name:buff_id)验证器代码
    ---@ui ~1~的目标~2~拥有Buff~3~
    ---@belong eff_param
    ---@description 效果节点的目标单位是否拥有Buff
    ---@applicable value
    ---@arg1 效果节点单位位置["节点目标"]
    ---@arg2 ref_param
    if eff_param_check(eff_param) then
        ---@type Unit Description
        local target:unknown = eff_param:get_site_target(unit):get_unit()
        if not(unit) then
            return e_cmd.MustTargetUnit
        end
        if target:has_buff(buff_id_name) then
            return e_cmd.OK
        else
            return e_cmd.CannotTargetThat
        end
    end
    return e_cmd.Error
end ---@keyword 单位 Buff