local base=base
local log=log
local caches={ dict = {}, has_inited = false}

---@class Mover
---@field remove fun()

---@class Target Unit|Point
---@field get_point fun(self:Target):Point
---@field get_unit fun(self:Target):Unit
---@field get_snapshot fun(self:Target):Snapshot
---@field get_name fun(self:Target):string
---@field get_owner fun(self:Target):Player
---@field get_facing fun(self:Target):integer
---@field get_team_id fun(self:Target):integer
---@field get_attackable_radius fun(self:Target):number
---@field is_ally fun(self:Target, target:Unit|Player):boolean
---@field is_visible_to fun(self:Target, target:Player):boolean
---@field has_restriction fun(self:Target, restriction:string):boolean
---@field has_label fun(self:Target, label:string):boolean
---@field polar_to fun(self:Target, offset:table)
---@field get_scene_name fun(self:Target):string?
---@field follow fun(self:Target, mover_table:table)
---@field type string

---@class LocExpress
---@field Effect string
---@field Value string
---@field LocalVar string

---@class PlayerExpress
---@field TargetLocation LocExpress
---@field Value string

---@class AngleExpress
---@field LocalOffset number
---@field Location LocExpress
---@field OtherLocation LocExpress
---@field Method string

base.eff={}

local eff=base.eff

base.eff.e_cmd = {
    Unknown = -1,
    OK = 0,
    NotSupported = 1,
    Error = 2,
    MustTargetUnit = 3,
    NotEnoughTarget = 4,
    NotEnoughRoomToPlace = 5,
    InvalidUnitType = 6,
    InvalidPlayer = 7,
    NothingToExecute = 8,
    MustTargetCertainUnit = 9,
    CannotTargetCertainUnit = 10,
    TargetIsOutOfRange = 11,
    TargetIsTooClose = 12,
    NoIntermediateUnit = 13,
    AlreadyExecuted = 14,
    CannotTargetThat = 15,
    NotEnoughCharges = 16,
    NotEnoughResource = 17,
    CannotPlaceThere = 18,
    InvalidItemType = 19,
    InvalidRange = 20,
}

base.eff.e_cmd_str = {
    '不支持',
    '错误',
    '必须以单位为目标',
    '目标数量不足',
    '放置空间不足',
    '无效的单位Id',
    '无效的玩家',
    '没有可供执行的对象',
    '必须以特定种类的单位为目标',
    '无法以特定种类的单位为目标',
    '目标超出射程',
    '目标太近了',
    '缺少中间单位',
    '效果已经执行过了',
    '无法以那个为目标',
    '使用次数不足',
    '资源不足',
    '无法在那里建造',
}

base.eff.e_site={
    default = 'Default',
    caster = 'Caster',
    launch = 'Launch',
    target = 'Target',
    missile = 'Missile',
    source = 'Source',
    origin = 'Origin',
    main_target = 'MainTarget',
    inter_unit = 'IntermediateUnit',
    local_var_unit = 'UnitLocalVar',
    local_var_point = 'PointLocalVar',
}

base.eff.e_sub_name = {
    start = '开始',
    activated = '已启动',
    stop = '结束',
    missile_impact = '弹道命中单位',
    teleport_start = '瞬移开始',
    teleport_finish = '瞬移完成',
}

base.eff.e_target_type={
    point='Point',
    unit='Unit',
    any = 'Any',
}

base.eff.e_stage={
    unknown=-1,
    idle=0,
    start=1,
    channel=2,
    shot=3,
    finish=4,
}

local e_cmd=eff.e_cmd
--local e_site=eff.e_site
local e_target_type=eff.e_target_type
local e_sub_name = eff.e_sub_name


function eff.init_cache(in_cache)
    if caches.has_inited or not in_cache or not in_cache.dict or not next(in_cache.dict) then
        return
    end
    caches = in_cache
    caches.has_inited = true
end

function eff.merge_cache(in_cache)
    for key, value in pairs(in_cache.dict) do
        caches.dict[key] = value
    end
    for key, value in pairs(in_cache) do
        if (key ~= 'dict') then
            caches[key] = value
        end
    end
end

function eff.has_cache_init()
    return caches and caches.has_inited
end

---comment
---@param node_type string
function eff.caches(node_type)
    return caches[node_type]
end

---comment
---@param link string
---@return table
function eff.cache(link)
    if link and #link > 0 and (not caches.dict or not next(caches.dict)) then
        log.error('游戏地图数据为空，请确保数据已经载入')
    end
    return caches.dict[link]
end

function eff.get_node_type(node_type)
    if node_type and node_type.NodeTypeLink then
        return node_type.NodeTypeLink
    end
end

function eff.cache_as(link, node_type)
    if link and #link > 0 and (not caches.dict or not next(caches.dict)) then
        log.error('游戏地图数据为空，请确保数据已经载入')
    end
    local ret = caches.dict[link]
    if eff.get_node_type(ret) == node_type then
        return ret
    end
end

function eff.original_data()
    return caches
end

---comment
---@param link string
---@return table
function eff.get_namespace(link)
    return string.match(link, '^($$.+)%.([^%.]+)$')
end

---comment
---@param link string
---@param name string
---@return table
function eff.find_sibling(link, name)
    local target_link = eff.get_namespace(link)..'.'..name
    return eff.cache(target_link)
end

---comment
---@param ref_param EffectParam
---@param do_cache boolean
---@return CmdResult
---@return string?
function eff.validate(ref_param, do_cache)
    local cache=ref_param.cache
    if (not cache) then
        return e_cmd.NotSupported
    end
    local target
    if cache.TargetLocation and cache.TargetType then
        target = ref_param:parse_loc(cache.TargetLocation,cache.TargetType)
    else
        target = ref_param:main_target()
    end

    if(not target)then
        log.error('目标配置错误，请确认节点的目标配置是正确的。（比如效果目标原本是一个点，但却目标类型却设置成了单位就会出错）')
        return e_cmd.Error
    end
    local class_validator =eff[cache.NodeType].validate
    if(class_validator)then
        local result, info = class_validator(ref_param, do_cache)
        if result~=e_cmd.OK then
            return result, info
        end
    end
    return eff.execute_validators(cache.Validators, ref_param)
end

function eff.execute_validators(validators, ref_param, ...)
    if not validators then
        return e_cmd.OK
    end

    return validators(ref_param, ...)
end

---comment
---@param ref_param EffectParam
---@return CmdResult
function eff.execute(ref_param)
    --特殊处理，缓存搜索结果
    local cache = ref_param.cache
    if (not cache) or (not eff[cache.NodeType]) then
        log.error('不存在节点类型'.. (cache and cache.NodeType or cache or 'nil'))
        return e_cmd.NotSupported
    end

    ref_param:calc_target()

    local result, info = eff.validate(ref_param, true)
    ref_param.result = result
    if ref_param.result ~= e_cmd.OK then
        ref_param:logfail(result, info)
        return ref_param.result
    end
    if cache.Chance then
        local chance = cache.Chance(ref_param)
        if chance < 1 then
            if math.random() > chance then
                return e_cmd.OK
            end
        end
    end
    --[[ To do: 行为拦截
    if cache.CanBeBlocked then
        ref_param:post_event('拦截测试')
        if(ref_param.nullified) then
            return e_cmd.OK
        end
    end ]]
    ref_param:post_event(e_sub_name.start)
    if ref_param.result~=e_cmd.OK then
        ref_param:logfail(ref_param.result)
        return ref_param.result
    end

    eff[cache.NodeType].execute(ref_param)
    local target_unit = ref_param.target:get_unit()
    local caster_unit = ref_param:caster():get_unit()
    if caster_unit and target_unit and cache.ResponseFlags and (cache.ResponseFlags.Acquire or cache.ResponseFlags.Flee) then
        target_unit:on_provoke(caster_unit, cache.ResponseFlags)
    end

    --将actor创建时机后延，使其能获取到效果节点创建的内容，如单位和弹道。

    local store = eff[cache.NodeType].persist
    if store then
        ref_param.actors =  ref_param.actors or {}
    end
    local force_no_sync = not store
    if cache.ActorArray then
        for _, value in ipairs(cache.ActorArray) do
            local actor = ref_param:create_actor(value, nil, force_no_sync)
            if actor and store then
                table.insert(ref_param.actors, actor)
            end
        end
    end
    ref_param:post_event(e_sub_name.activated)
    if log.log_eff_success then
        log.info(ref_param:debuginfo().." 执行成功");
    end
    if not eff[cache.NodeType].persist or ref_param.stopped then
        ref_param:stop()
    end
    return e_cmd.OK
end

---comment
---@param n number
local function is_int(n)
    return math.floor(n) == n
end

---comment
---@param base_value number
---@param delta number
local function rnd_damage(base_value, delta)
    if is_int(base_value) and is_int(delta) then
        return base.math.random(base_value, base_value + delta)
    else
        return base.math.random() * delta + base_value
    end
end

---------------------------------
-- EffectDamage
---------------------------------

eff.EffectDamage={ }

---comment
---@param ref_param EffectParam
---@return integer
function eff.EffectDamage.validate(ref_param)
    if(ref_param.cache.TargetType~=e_target_type.unit)then
        return e_cmd.MustTargetUnit
    end
    return e_cmd.OK
end

---comment
---@param ref_param EffectParam
---@param params table?
function eff.EffectDamage.execute(ref_param, params)
    local cache=ref_param.cache
    local amount = cache.Amount(ref_param)
    if cache.Random and cache.Random ~= 0 then
        amount = rnd_damage(amount, cache.Random)
    end

    local data = {
        source = ref_param:caster(),
        damage = amount,
        target = ref_param.target,
        damage_type = cache.DamageType,
        ref_param = ref_param,
    }

    if params then
        for key, value in pairs(params) do
            if not data[key] then
                data[key]=value
            end
        end
    end
    base.game:add_damage(data)
end

---------------------------------
-- EffectLaunchMissile
---------------------------------

eff.EffectLaunchMissile={ persist = true }

function eff.EffectLaunchMissile.validate(ref_param)
    local cache=ref_param.cache
    if cache.Method == 'Exist' then
        local bullet = ref_param:parse_loc(cache.WhichUnit, e_target_type.unit)
        if not bullet then
            return e_cmd.MustTargetUnit, '选择了发射特定单位，却没有正确地配置被发射的单位'
        end
    end
    local launch_site=ref_param:parse_loc(cache.LaunchLocation)
    if not launch_site then
        return e_cmd.error, '弹道发射位置配置错误，无法定位发射位置'
    end

    return e_cmd.OK
end

---comment
---@param ref_param EffectParam
function eff.EffectLaunchMissile.execute(ref_param)
    local cache=ref_param.cache
    local caster = ref_param:caster()
    local player = caster and caster:get_owner() or ref_param:creator_player();
    local scene = ref_param:get_scene()
    local launch_site=ref_param:parse_loc(cache.LaunchLocation)
    if not launch_site then
        return
    end
    ref_param.launch_unit = launch_site:get_unit()

    if(cache.LaunchTargetType==e_target_type.point) then
        launch_site=launch_site:get_point()
        local offset_angle=ref_param:parse_angle(cache.LaunchOffset.Angle)
        if(offset_angle and cache.LaunchOffset.Distance ~= 0)then
            launch_site=launch_site:polar_to({offset_angle, cache.LaunchOffset.Distance})
            --如果有了绝对偏移，就不认为是单位发射的弹道
            --取消这一设计
            --ref_param.launch_unit = nil
        end
    end
    local facing =   launch_site:get_point():angle_to(ref_param.target:get_point())
                    or ref_param.source:get_facing()
                    or 0
    ---@type Unit? Description
    local bullet
    if cache.Method == 'New' and base.table.unit[cache.MissileType] then
        bullet = player:create_unit(cache.MissileType , launch_site:get_point() , facing, nil, scene)
    elseif cache.Method == 'Exist' then
        local b_target = ref_param:parse_loc(cache.WhichUnit, e_target_type.unit)
        bullet = b_target and b_target:get_unit()
        if bullet then
            bullet:blink(launch_site:get_point())
        end
    end

    if not bullet then
        ref_param:stop()
        return
    end

    ref_param:set_launch(launch_site)
    ref_param.missile_data = ref_param.missile_data or {}
    ref_param.missile = bullet
    ref_param.inter_unit = bullet

    ---@type Mover Description
    local mover
    ref_param.missile_data.missile_range = ref_param.target:get_point():distance(launch_site:get_point())
    local hit_type = cache.DoImpactUnit and '全部' or nil

    local scale = cache.MissileScaling and cache.MissileScaling(ref_param)
    if scale then
        bullet:set_scale(scale, cache.Link)
    end
    if ref_param.target.type == 'unit' then
        ref_param.missile_data.missile_range = ref_param.missile_data.missile_range * 2
        mover = base.game:mover_target
        {
            source = ref_param.source,
            start = launch_site:get_point(),
            mover = bullet,
            target = ref_param.target,
            speed = cache.Speed(ref_param) * ref_param.shared.attribute['急速'],
            parabola_height =cache.ParabolaApex(ref_param),
            hit_area = cache.ImpactSearchRange(ref_param),
            height = cache.temp_height,
            force_height = cache.temp_height,
            hit_type = hit_type,
            block = cache.StaticBlock,
            pathing_bit_required={},
            pathing_bit_prevent=cache.Prevent,
            hit_target = true,
            add_impact_area = cache.ImpactFinalTargetRadius,
            passive = not cache.TurnToDirection,
            tangent_direction = cache.TurnToVelocity,
            stick_to_ground = cache.StickToGround,
        }
    else
        local apex = cache.ParabolaApex(ref_param)
        local landing = nil
        if apex~= 0 then
            landing = cache.ParabolaLandingHeight
        end
        mover = base.game:mover_line
        {
            source = ref_param.source,
            angle = facing,
            start = launch_site:get_point(),
            mover = bullet,
            distance = ref_param.missile_data.missile_range,
            speed = cache.Speed(ref_param) * ref_param.shared.attribute['急速'],
            hit_area = cache.ImpactSearchRange(ref_param),
            parabola_height = apex,
            target_height = landing,
            height = cache.temp_height,
            force_height = cache.temp_height,
            hit_type = hit_type,
            block = cache.StaticBlock,
            pathing_bit_required = {},
            pathing_bit_prevent = cache.Prevent,
            passive = not cache.TurnToDirection,
            tangent_direction = cache.TurnToVelocity,
            stick_to_ground = cache.StickToGround,
        }
    end

    ref_param.missile_data.impacted_count=0

    if not mover then
        ref_param:stop()
        return
    end

    ref_param.missile_data.mover = mover

    ---@type TargetFilters Description
    local target_filter=base.target_filters:new(cache.ImpactSearchFilter)

    function mover:on_hit(new_target)
        if cache.DoImpactUnit == false then
            return
        end
        if cache.ImpactEffect and target_filter:validate(ref_param:caster(), new_target) == e_cmd.OK then
            ref_param.it_target = new_target
            ref_param:post_new_target(new_target)
            if(ref_param:is_missile_detached()) then
                ref_param:stop()
                return
            end
            if cache.UnitLocalVar and #cache.UnitLocalVar > 0 then
                ref_param:set_var_unit(cache.UnitLocalVar, new_target)
            end
            -- 从父实例创建
            local child_param=ref_param:create_child()
            child_param:init(ref_param.source,new_target)
            child_param:set_cache(cache.ImpactEffect)
            if(child_param.cache)then
                eff.execute(child_param)
                local point = bullet:get_point()
                if base.table.unit[cache.temp_impact_model] then
                    point:create_effect(cache.temp_impact_model)
                end
                if cache.ImpactActors then
                    for _, value in ipairs(cache.ImpactActors) do
                        local actor = ref_param:create_actor(value, point, true)
                        if actor then
                            actor:set_position_from(bullet)
                        end
                    end
                end
            end
            ref_param.missile_data.impacted_count = ref_param.missile_data.impacted_count + 1
            local impact_max = cache.ImpactMaxCount(ref_param)
            if(impact_max > 0)then
                if(impact_max <= ref_param.missile_data.impacted_count)then
                    self:remove()
                    ref_param:stop()
                end
            end
        end
    end

    function mover:on_remove()
        if cache.FinalEffect then
            ref_param:execute_child_on(cache.FinalEffect)
        end
        if(ref_param:is_missile_detached()) then
            return
        end
        if cache.Method == 'New' and ref_param.missile_data.mover == self then
            bullet:remove()
        else
            bullet:clear_scale(cache)
        end
    end

    function mover.on_finish(_)
        local point = bullet:get_point()
        if cache.FinishEffect then
            ref_param:execute_child_on(cache.FinishEffect)
        end
        if cache.FinishActors then
            for _, value in ipairs(cache.FinishActors) do
                local actor = ref_param:create_actor(value,point, true)
                if actor then
                    actor:set_position_from(bullet)
                end
            end
        end
    end
end

---------------------------------
-- EffectAddBuff
---------------------------------

eff.EffectAddBuff={}

---comment
---@param ref_param EffectParam
---@return CmdResult
---@return string?
function eff.EffectAddBuff.validate(ref_param)
    local cache = ref_param.cache
    if ref_param.cache.TargetType ~= e_target_type.unit then
        return e_cmd.MustTargetUnit, '添加Buff的目标必须是单位'
    end

    local buff_table = base.eff.cache(cache.BuffLink)
    if not buff_table then
        return e_cmd.error, '无效的Buff ID'
    end

    return e_cmd.OK
end

---comment
---@param ref_param EffectParam
---@param params table
function eff.EffectAddBuff.execute(ref_param, params)
    local cache=ref_param.cache

    local buff_data = eff.cache(cache.BuffLink)

    --TODO: accumulator
    if cache.Count <=0 then
        return
    end

    local period = buff_data.Period(ref_param)
    if period > 0 then
        if buff_data.BuffFlags.UseHaste then
            period = period / ref_param.shared.attribute['急速']
        end
    else
        period = nil
    end

    local count_method
    if buff_data.CountMethod == 'PerCaster' then
        count_method = 0
    elseif buff_data.CountMethod == 'PerLink' then
        count_method = 1
    end

    local allow_multi
    if buff_data.BuffFlags.AllowMultiInstance then
        allow_multi = 1
    else
        allow_multi = 0
    end

    ---@type number?
    local duration = buff_data.Duration(ref_param)
    if duration < 0 then
        duration = nil
    end

    if cache.Duration then
        local dur_override = cache.Duration(ref_param)
        if dur_override and dur_override > 0 then
            duration = dur_override
        end
    end

    local stack = cache.Count

    if stack and buff_data.StackMax then
        local stack_max = buff_data.StackMax(ref_param)
        if stack_max > 0 then
            stack = math.min(stack, stack_max)
        end
    end

    local target_unit = ref_param.target:get_unit()
    if not target_unit then
        return
    end

    if
        buff_data.BuffFlags
        and buff_data.BuffFlags.SingleInstancePerCaster
        and (not ref_param:item())
        and (not buff_data.BuffFlags.Channeling)
    then
        local caster = ref_param:caster()
        for buff in target_unit:each_buff(cache.BuffLink) do
            if buff.stack_param and buff.stack_param:caster() == caster then
                buff.time = params and params.time or duration
                if caster and caster:get_unit() then
                    caster:get_unit():on_response("ResponseBuff", base.response.e_location.Attacker, ref_param, buff)
                end
                target_unit:on_response("ResponseBuff", base.response.e_location.Defender, ref_param, buff)
                if buff.time then
                    buff:set_remaining(buff.time)
                end
                if stack then
                    buff:add_stack_(stack)
                end
                buff.stack_param:execute_child_on(buff_data.RefreshEffect)
                return
            end
        end
    end

    local data={
        stack = stack,
        stack_param = ref_param,
        skill = ref_param:skill(),
        time = duration,
        link = cache.BuffLink,
        cache = buff_data,
        pulse = period,
        cover_global = count_method,
        cover_max = buff_data.InstanceMax,
        cover_type = allow_multi,
        keep = buff_data.BuffFlags.Permanent,
    }

    if params then
        for key, value in pairs(params) do
            if not data[key] then
                data[key]=value
            end
        end
    end

    ref_param.buff_data = ref_param.buff_data or {}

    local caster = ref_param:caster()
    if caster and caster:get_unit() then
        caster:get_unit():on_response("ResponseBuff", base.response.e_location.Attacker, ref_param, data)
    end
    target_unit:on_response("ResponseBuff", base.response.e_location.Defender, ref_param, data)

    if data.prevent then
        return
    end
    ref_param.buff_data.buff = target_unit:add_buff(buff_data.Link)(data)
end


---------------------------------
-- EffectRemoveBuff
---------------------------------

eff.EffectRemoveBuff={}

---comment
---@param ref_param EffectParam
---@return CmdResult
---@return string?
function eff.EffectRemoveBuff.validate(ref_param)
    if(ref_param.cache.TargetType ~= e_target_type.unit)then
        return e_cmd.MustTargetUnit, '移除Buff的目标必须是单位'
    end

    return e_cmd.OK
end

---comment
---@param ref_param EffectParam
function eff.EffectRemoveBuff.execute(ref_param)
    local cache = ref_param.cache
    ---@type integer
    local count = cache.Count
    if count == 0 then
        return
    end

    local category_filter
    if cache.BuffCategories and #cache.BuffCategories > 0 then
        ---@type TargetFilters
        category_filter = base.target_filters:new(cache.BuffCategories)
    end

    ---@type Buff[]
    local buffs = {}
    for buff in ref_param.target:get_unit():each_buff(cache.BuffLink) do
        if category_filter == nil or buff:filter_categories(category_filter) then
            table.insert(buffs, buff)
        end
    end

    if count < 0 then
        for _, buff in ipairs(buffs) do
            buff:remove()
        end
    else
        for _, buff in ipairs(buffs) do
            local stack = buff.stack
            local removed = math.min(count, stack)
            local remaining_stack = stack - removed
            buff:set_stack_(remaining_stack)
            count = count - removed
            if count <=  0 then
                break
            end
        end
    end

end
---------------
-- EffectCreateUnit
---------------

eff.EffectCreateUnit={}

---comment
---@param ref_param EffectParam
---@return CmdResult
---@return string?
function eff.EffectCreateUnit.validate(ref_param)
    local cache=ref_param.cache
    local unit_type
    if(cache.UnitPicker=='UnitLink')then
        unit_type=ref_param:level_data(cache.SpawnUnitTypePerLevel, '')
    else
        unit_type=ref_param:parse_loc(cache.SpawnTypeUnit,e_target_type.unit)
    end
    if (not unit_type) or (unit_type.type ~= 'unit' and not base.table.unit[unit_type]) then
        log.error('未正确指定单位Id：'..ref_param:debuginfo())
        return e_cmd.InvalidUnitType, '未正确指定单位Id'
    end
    local player=ref_param:parse_player(cache.SpawnOwner)
    if(player==nil or player.type~='player')then
        log.error('未正确指定单位所属玩家'..ref_param:debuginfo())
        return e_cmd.InvalidPlayer, '未正确指定单位所属玩家'
    end
    if(cache.SpawnCount<=0)then
        log.error('创建数量小于1'..ref_param:debuginfo())
        return e_cmd.NotSupported, '创建数量小于1'
    end
    return e_cmd.OK
end

---comment
---@param ref_param EffectParam
function eff.EffectCreateUnit.execute(ref_param)
    local cache=ref_param.cache
    ---@type string
    local unit_type
    if(cache.UnitPicker=='UnitLink')then
        unit_type=ref_param:level_data(cache.SpawnUnitTypePerLevel, '') --[[@as string]]---
    else
        unit_type=ref_param:parse_loc(cache.SpawnTypeUnit,e_target_type.unit) --[[@as string]]---
    end
    if(unit_type==nil or unit_type=='')then
        return
    end
    local player=ref_param:parse_player(cache.SpawnOwner)
    if(player==nil or player.type~='player')then
        return
    end
    local scene = ref_param:get_scene()
    if not scene then
        return
    end
    local facing=ref_param:parse_angle(cache.Facing)
    if(facing==nil)then
        --'未正确指定单位朝向：'..ref_param:debuginfo()
        facing=0
    end
    local point=ref_param.target:get_point()
    if(cache.SpawnOffset.Distance~=0)then
        local offset_angle=ref_param:parse_angle(cache.SpawnOffset.Angle)

        if(offset_angle)then
            point=point:polar_to({offset_angle, cache.SpawnOffset.Distance})
        end
    end

    for _ = 1, cache.SpawnCount, 1 do
        local unit

        if cache.UnitPicker == 'Location' and cache.CreateUnitFlags and cache.CreateUnitFlags.Illusion then
            unit = player:create_illusion(point, facing, unit_type, nil, scene)
            unit._parent_param = ref_param
        else
            unit = player:create_unit(unit_type, point, facing, function (in_unit)
                in_unit._parent_param = ref_param
        end, scene)
            if unit ~= nil and cache.CreateUnitFlags and cache.CreateUnitFlags.Illusion then
                local illusion = player:create_illusion(point, facing, unit, nil, scene)
                unit:remove()
                unit = illusion
                unit._parent_param = ref_param
            end
        end
        if not unit then
            log.error('单位创建失败：'..ref_param:debuginfo())
        else
            if cache.CreateUnitFlags and cache.CreateUnitFlags.DefaultAI then
                local link = unit:get_name()
                local unit_cache = base.eff.cache(link)
                local ai_link = 'default_ai'
                if unit_cache and unit_cache.DefaultAI and #unit_cache.DefaultAI > 0 then
                    ai_link = unit_cache.DefaultAI
                end

                local creator =  unit:creator():get_unit()
                unit:add_ai(ai_link){
                    master = creator,
                    stay_time = unit_cache.stay_time,
                    distance_random = unit_cache.distance_random,
                    follow_random = unit_cache.follow_random,
                }
            end
            if cache.SpawnEffect and #cache.SpawnEffect > 0 then
                if cache.UnitLocalVar and #cache.UnitLocalVar > 0 then
                    ref_param:set_var_unit(cache.UnitLocalVar, unit)
                end
                ref_param:execute_child_on(cache.SpawnEffect,unit)
                ref_param.inter_unit = unit
            end
        end
    end
end

---------------------------------
-- EffectRepeat
---------------------------------

--[[ eff.EffectRepeat = { persist = true }

function eff.EffectRepeat.execute(ref_param)
    local cache = ref_param.cache
    -- local count = cache.Count(ref_param)
    -- todo 这个节点有必要吗？
end ]]

---------------------------------
-- EffectPersistLoop
---------------------------------

eff.EffectPersistLoop={ persist = true }

---comment
---@param ref_param EffectParam
function eff.EffectPersistLoop.execute(ref_param)
    local cache=ref_param.cache
    local count=cache.PeriodicCount(ref_param)
    local period = cache.Period(ref_param)
    local periodic_offset=nil
    local periodic_distance = cache.temp_PeriodicDistance(ref_param)
    local angle_start = ref_param:parse_angle(cache.temp_PeriodicVectorStart) or 0

    if periodic_distance > 0 then
        periodic_offset={}
        periodic_offset.distance = periodic_distance or 0
        periodic_offset.angle = cache.temp_PeriodicAngle or 0
        periodic_offset.angle_start = angle_start or 0
    end

    local loop_data={
        init_link=cache.InitialEffect,
        expire_link=cache.ExpireEffect,
        final_link=cache.FinalEffect,
        child_link = cache.PeriodicEffect,
        period = period,
        count = count,
        periodic_offset=periodic_offset,
        loop_flags=cache.PersistFlags
    }
    if cache.ActorArray and #cache.ActorArray then
        ref_param.radius = cache.Radius(ref_param)
    end
    ref_param:loop(loop_data)
end

---------------
-- EffectRandomPointInCircle
---------------

eff.EffectRandomPointInCircle={}

---comment
---@param ref_param EffectParam
---@return integer
function eff.EffectRandomPointInCircle.validate(ref_param)
    local cache=ref_param.cache
    local count=cache.Count
    if(count<=0)then
        return e_cmd.NotEnoughTarget
    end

    if(cache.Radius<0)then
        return e_cmd.NotEnoughRoomToPlace
    end

    if(cache.Effect==nil or cache.Effect=='')then
        return e_cmd.NothingToExecute
    end

    return e_cmd.OK
end

---comment
---@param ref_param EffectParam
function eff.EffectRandomPointInCircle.execute(ref_param)
    local cache=ref_param.cache
    local count = cache.Count
    local center = ref_param.target:get_point()
    local radius = cache.Radius
    local it_length = radius
    ---@type boolean Description
    local circumference = cache.RandomPointInCircleFlags.RestrictToCircumference
    ref_param.radius = radius
    for _ = 1, count, 1 do
        local it_facing = math.random() * 360
        if(not circumference)then
            it_length = math.sqrt(math.random()) * radius
        end
        local it_point = center:polar_to({it_facing, it_length})
        if cache.PointLocalVar and #cache.PointLocalVar > 0 then
            ref_param:set_var_point(cache.PointLocalVar, it_point)
        end
        ref_param:execute_child_on(cache.Effect, it_point)
    end
end

---------------
-- EffectSearch
---------------

eff.EffectSearch={}


---只搜索，不限制个数，如果不需要排序则不进行验证
---@param ref_param EffectParam
---@param validate_only boolean
---@return Unit[]
function eff.EffectSearch.search(ref_param, validate_only)
    local cache = ref_param.cache
    ---@type Point Description
    local point = ref_param.target:get_point()
    ---@type Unit[] Description
    local group = {}
    ---@type Unit[] Description
    local group_out = {}
    local extra_radius = 0
    local angle = ref_param:parse_angle(cache.Angle)
    if cache.SearchFlags.ExtendByUnitRadius then
        extra_radius = ref_param.target:get_attackable_radius()
    end
    if cache.SearchFlags.OffsetByUnitRadiusAndAngle then
        point = point:polar_to({ angle or 0, ref_param.target:get_attackable_radius() })
    end
    if cache.SearchOffset.Distance~=0 then
        local offset_angle=ref_param:parse_angle(cache.SearchOffset.Angle)
        if(offset_angle)then
            point=point:polar_to({offset_angle, cache.SearchOffset.Distance})
        end
    end

    local caster = ref_param:caster()
    local scene = ref_param:get_scene()
    if not scene then
        return {}
    end
    local radius
    if cache.Method == 'Circle' then
        radius = cache.Radius(ref_param) + extra_radius
        group = point:get_point():group_range(radius, 'place_holder', scene, true)
    elseif cache.Method == 'Arc' then
        radius = cache.Radius(ref_param) + extra_radius
        group = point:get_point():group_sector(radius, angle, cache.Arc, scene, true)
    elseif cache.Method == 'Line' then
        if cache.ActorArray and #cache.ActorArray then
            radius = cache.Radius(ref_param) + extra_radius
        end
        group = point:get_point():group_line(cache.Width + (extra_radius * 2), cache.Height, angle, scene, true)
    end

    local skip_sort = cache.TargetSorts == nil or #cache.TargetSorts == 0
    local needed_count = cache.MaxCount
    local validate_child = cache.SearchFlags.ValidateChildrens
    local child_link = cache.SearchEffect
    --是否把搜索彻底完成
    if(validate_only)then
        needed_count = cache.MinCount
    end
    ---@type TargetFilters Description
    local target_filter = base.target_filters:new(cache.SearchFilter)
    if (skip_sort or validate_only) then
        --不需要重新排序，或者只需要进行验证的情况，找到指定个数就行
        local validate_param = ref_param:create_child()
        local count = 0
        for _, it_unit in ipairs(group) do
            if(needed_count>=0 and count>=needed_count)then
                break
            end
            --先过滤
            if target_filter:validate(caster,it_unit)==e_cmd.OK then
                --再验证
                validate_param:set_target(it_unit)
                if eff.execute_validators(cache.SearchValidators, validate_param) == e_cmd.OK then
                    --再验证子效果
                    if(validate_child)then
                        local child_param=ref_param:create_child()
                        child_param:init(ref_param.source,it_unit)
                        child_param:set_cache(child_link)
                        if eff.validate(child_param,false) == e_cmd.OK then
                            table.insert(group_out,it_unit)
                            count = count +1
                        end
                    else
                        table.insert(group_out,it_unit)
                        count = count +1
                    end
                end
            end
        end
    else
        --需要全部验证的情况
        --全部验证并重新排序
        local validate_param = ref_param:create_child()
        for _, it_unit in ipairs(group) do
            --先过滤
            if target_filter:validate(caster,it_unit) == e_cmd.OK then
                --再验证
                validate_param:set_target(it_unit)
                if eff.execute_validators(cache.SearchValidators, validate_param) == e_cmd.OK then
                    --再验证子效果
                    if(validate_child)then
                        local child_param=ref_param:create_child()
                        child_param:init(ref_param.source,it_unit)
                        child_param:set_cache(child_link)
                        if eff.validate(child_param,false)  == e_cmd.OK then
                            table.insert(group_out,it_unit)
                        end
                    else
                        table.insert(group_out,it_unit)
                    end
                end
            end
        end

        if cache.TargetSorts and #cache.TargetSorts > 0 then
            ref_param:unit_sorts(group_out, cache.TargetSorts)
        end
        if cache.MaxCount >= 0 and #group_out > cache.MaxCount then
            --使ipairs无法遍历到maxcount之后
            group_out[cache.MaxCount + 1] = nil
        end
    end
    group_out.facing = angle
    group_out.radius = radius
    return group_out
end

---comment
---@param ref_param EffectParam
---@param do_cache boolean
---@return integer
function eff.EffectSearch.validate(ref_param, do_cache)
    local cache=ref_param.cache
    local min_count = cache.MinCount
    local max_count = cache.MaxCount

    if(cache.SearchEffect==nil or cache.SearchEffect=='')then
        return e_cmd.NothingToExecute
    end

    if(max_count ==0)then
        return e_cmd.NotEnoughTarget, '最大个数为0！'
    end

    if(min_count >= 0 and max_count >=0 and min_count>max_count)then
        return e_cmd.NotEnoughTarget, '最小个数大于最大个数'
    end

    local check_angle = cache.Method ~= 'Circle' ---TODO: or (cache.ActorArray and #cache.ActorArray > 0)

    if(min_count>0)then
        local group
        if ref_param.search_data and ref_param.search_data.found then
            group = ref_param.search_data.found
        else
            group = eff.EffectSearch.search(ref_param, not do_cache)
        end
        if(#group<min_count)then
            local errorText
            if cache.MinCountError.ErrorText and #cache.MinCountError.ErrorText > 0 then
                errorText = cache.MinCountError.ErrorText
            end
            return cache.MinCountError.Result, errorText
        end
        if(do_cache)then
            ref_param.search_data = { found = group}
        end
        if check_angle and not group.facing then
            return e_cmd.error, '搜索朝向设置错误，是否错误地对点使用了单位的朝向？'
        end
    elseif check_angle then
        local angle = ref_param:parse_angle(cache.Angle)
        if not angle then
            return e_cmd.error, '搜索朝向设置错误，是否错误地对点使用了单位的朝向？'
        end
    end
    return e_cmd.OK
end

---comment
---@param ref_param EffectParam
function eff.EffectSearch.execute(ref_param)
    local cache = ref_param.cache
    local child_link = cache.SearchEffect
    local group
    if ref_param.search_data and ref_param.search_data.found then
        group = ref_param.search_data.found
    else
        group = eff.EffectSearch.search(ref_param, false)
        ref_param.search_data = { found = group}
    end
    local save = cache.UnitLocalVar and #cache.UnitLocalVar > 0
    ref_param.facing = group.facing
    ref_param.radius = group.radius
    for _, it_unit in ipairs(group) do
        if save then
            ref_param:set_var_unit(cache.UnitLocalVar, it_unit)
        end
        ref_param.it_target = it_unit
        ref_param:execute_child_on(child_link,it_unit)
    end
end

---------------
-- EffectSwitch
---------------

eff.EffectSwitch = {}

---comment
---@return integer
function eff.EffectSwitch.validate(_)
    return e_cmd.OK
end

---comment
---@param ref_param EffectParam
function eff.EffectSwitch.execute(ref_param)
    local cache = ref_param.cache
    local check_children = cache.SwitchFlags.ValidateChildrens
    if cache.CaseArray then
        for _, case in ipairs(cache.CaseArray) do
            if eff.execute_validators(case.Validator, ref_param) == e_cmd.OK then
                if case.Effect and #case.Effect then
                    local result = ref_param:execute_child_on(case.Effect)
                    if not check_children or result ~= e_cmd.OK then
                       return
                    end
                else
                    return
                end
            end
        end
    end
    ref_param:execute_child_on(cache.CaseDefault)
end

---------------
-- EffectSet
---------------

eff.EffectSet={}

---comment
---@param ref_param EffectParam
---@return integer
function eff.EffectSet.validate(ref_param)
    local cache=ref_param.cache
    local min_count = cache.MinCount
    local max_count = cache.MaxCount

    if(min_count >= 0 and max_count >=0 and min_count>max_count)then
        return e_cmd.NotEnoughTarget, '最小个数大于最大个数'
    end

    if max_count<0 and cache.SetFlags.WithReplacement then
        return e_cmd.NotEnoughTarget, '指定了放回抽取却没有指定最大次数'
    end

    return e_cmd.OK
end

---comment
---@param ref_param EffectParam
---@return table, integer
function eff.EffectSet.create_table(ref_param)
    local cache = ref_param.cache

    local table_effect = cache.EffectArray
    local table_weight = cache.Weights
    local result = {}
    local total_weight = 0
    for index, effect in ipairs(table_effect) do
        local item = {effect = effect, weight = 1}
        if table_weight and table_weight[index] then
            item.weight = table_weight[index]
        end
        table.insert(result,item)
        total_weight =  total_weight + item.weight
    end
    return result, total_weight
end

---comment
---@param effects table
---@param with_replacement boolean
---@param randomized boolean
---@param total_weight number
---@return string
function eff.EffectSet.pick_from_table(effects, with_replacement, randomized, total_weight)
    local index = 1
    if randomized and total_weight > 0 then
        local start = 0
        local rnd = math.random() * total_weight
        for i, value in ipairs(effects) do
            start = start + value.weight
            if start >= rnd then
                index = i
                break
            end
        end
    end
    local effect = effects[index].effect
    if not with_replacement then
        total_weight = total_weight - effects[index].weight
        table.remove(effects, index)
    end
    return effect, total_weight
end

---comment
---@param ref_param EffectParam
function eff.EffectSet.execute(ref_param)
    local cache = ref_param.cache
    local min_count = cache.MinCount
    local max_count = cache.MaxCount
    local count = 0
    if cache.EffectArray then
        count = #cache.EffectArray
    end
    ---@type number
    local pick = count
    if max_count == 0 or count == 0 then
        return
    end

    if max_count > 0 then
        if min_count < 0 then
            min_count  = 0
        end
        pick = base.math.random_smart(min_count,max_count)
    end

    if (not cache.SetFlags.WithReplacement) and (not cache.SetFlags.Recycle) and pick > count then
        pick = count
    end

    if pick == 0 then
        return
    end

    local source = ref_param.source
    if cache.SetFlags and cache.SetFlags.SetSource then
        source = ref_param.target
    end

    local replacement = cache.SetFlags.WithReplacement
    local randomized = cache.SetFlags.Unordered
    local effects = {}
    local total_weight = 0;
    local child_link
    local success = 0
    local has_inited = false
    local need_validate = cache.SetFlags.ValidateChildrens or false

    while (success < pick)
    do
        if #effects == 0 then
            -- 如果已经进行过一轮，但仍然没有选出任何东西来，那就不要再浪费时间了
            if has_inited and success == 0 then
                return
            end
            effects, total_weight = eff.EffectSet.create_table(ref_param)
            has_inited = true
        end
        child_link, total_weight = eff.EffectSet.pick_from_table(effects, replacement, randomized, total_weight)
        if child_link then
            local child_param=ref_param:create_child()
            child_param:init(source,ref_param.target)
            child_param:set_cache(child_link)
            local result = nil
            if child_param.cache then
               result = base.eff.execute(child_param)
            end
            if not need_validate or result == e_cmd.OK then
                success = success + 1
            end
        else
            return
        end
    end
end

---------------
-- EffectTeleport
---------------

eff.EffectTeleport={}

---TODO:Place validator
---@param ref_param EffectParam
---@return integer
function eff.EffectTeleport.validate(ref_param)
    local cache = ref_param.cache
    local unit = ref_param:parse_loc(cache.WhichUnit,e_target_type.unit)
    if not unit then
        return e_cmd.NoIntermediateUnit, '找不到需要传送的目标单位，请检查配置'
    end
    if cache.MinDistance > 0 then
        local target = ref_param.target:get_point()
        local center = unit:get_point()
        if cache.TeleportFlags.KeepOffsetToCenter then
            center = ref_param:parse_loc(cache.CenterLocation, e_target_type.point)
        end
        if target:distance(center) < cache.MinDistance then
            return e_cmd.TargetIsTooClose
        end
    end
    return e_cmd.OK
end

---comment
---@param ref_param EffectParam
function eff.EffectTeleport.execute(ref_param)
    local cache = ref_param.cache
    ---@type Unit Description
    local unit = ref_param:parse_loc(cache.WhichUnit,e_target_type.unit)
    local unit_point = unit:get_point()
    local center = unit_point
    if cache.TeleportFlags.KeepOffsetToCenter then
        center = ref_param:parse_loc(cache.CenterLocation, e_target_type.point)
    end

    local dest = ref_param.target:get_point()
    if cache.Range >= 0 then
        local angle = center:angle(dest)
        local range = center:distance(dest)
        if range > cache.Range then
            range = cache.Range
            dest = center:polar_to({angle, range})
        end
    end
    local offset = unit_point:distance(center)
    if offset > 0 then
        local offset_angle = center:angle(unit_point)
        dest = dest:polar_to({offset_angle, offset})
    end

    ref_param.inter_unit = unit

    ref_param:post_event(e_sub_name.teleport_start)

    unit:blink(dest, cache.SyncOffset)

    ref_param:post_event(e_sub_name.teleport_finish)

    if cache.ClearQueuedOrders then
        unit:clear_command()
    end

    if cache.TeleportEffect and cache.TeleportEffect ~= '' then
        ref_param:execute_child_on(cache.TeleportEffect, unit)
    end

end


---------------
-- EffectIssueOrder
---------------

eff.EffectIssueOrder={}

---@param ref_param EffectParam
---@return integer
---@return string?
function eff.EffectIssueOrder.validate(ref_param, do_cache)
    local cache = ref_param.cache
    local unit = ref_param:parse_loc(cache.WhichUnit,e_target_type.unit):get_unit()
    if not unit then
        return e_cmd.NoIntermediateUnit, '找不到拟被下达指令的单位，请检查配置'
    end

    if do_cache then
        ref_param.order_data = {}
        ref_param.order_data.unit = unit
        ref_param.order_data.type = cache.OrderType
    end

    local target_unit = ref_param:parse_loc(cache.TargetLocation,e_target_type.unit)

    if cache.OrderType == 'Abil' then
        local abil_cache = base.table.skill[cache.Abil]
        if not abil_cache then
            return e_cmd.CannotTargetThat, '技能不存在，请检查配置'
        end
        if do_cache then
            ref_param.order_data.cache = abil_cache
            ref_param.order_data.target_type = abil_cache.target_type
        end

        --单位目标技能必须有单位作为目标
        if abil_cache.target_type == 1 then
            if not target_unit then
                return e_cmd.CannotTargetThat, '单位技能指令必须以单位为目标'
            end
        end
    end

    return e_cmd.OK
end

---comment
---@param ref_param EffectParam
function eff.EffectIssueOrder.execute(ref_param)
    local cache = ref_param.cache
    local unit = ref_param.order_data.unit
    local data = {CmdIndex = cache.CmdIndex}
    if cache.OrderType == 'Abil' then
        unit:cast_effect_target(cache.Abil, ref_param.target, data)
    elseif cache.OrderType == 'Attack' then
        unit:attack_effect_target(ref_param.target, data)
    elseif cache.OrderType == 'Move' then
        local dest = ref_param.target:get_point()
        unit:walk(dest)
    end
end


---------------
-- EffectStopOrder
---------------

eff.EffectStopOrder={}

---comment
---@param ref_param EffectParam
---@return integer
---@return string?
function eff.EffectStopOrder.validate(ref_param)
    if(ref_param.cache.TargetType~=e_target_type.unit)then
        return e_cmd.MustTargetUnit, '打断指令的目标必须是单位'
    end
    return e_cmd.OK
end

---comment
---@param ref_param EffectParam
function eff.EffectStopOrder.execute(ref_param)
    local cache = ref_param.cache
    ---@type Unit Description
    local unit =  ref_param.target:get_unit()
    if cache.StopOrderFlags.StopAttack then
        unit:stop_attack()
    end
    if cache.StopOrderFlags.StopSpell then
        ---@type Skill Description
        local skill = unit:current_skill()
        if skill then
            local specified = false
            if cache.Abil and #cache.Abil > 0  then
                specified = true
                if skill:get_name() == cache.Abil then
                    skill:stop()
                end
            end
            if cache.AbilCategory and #cache.AbilCategory then
                specified = true
                ---@type TargetFilters
                local filter = base.target_filters:new(cache.AbilCategory)
                if skill:filter_categories(filter) then
                    skill:stop()
                end
            end
            if not specified then
                skill:stop()
            end
        end
    end
    if cache.StopOrderFlags.Stop then
        unit:stop()
    end
    if cache.StopOrderFlags.ClearQueuedOrders then
        unit:clean_command()
    end
end

---------------
-- EffectUserDataSet
---------------

eff.EffectUserDataSet={}

---comment
---@param ref_param EffectParam
---@return integer
---@return string
function eff.EffectUserDataSet.validate(ref_param)
    local cache = ref_param.cache
    if cache.Key == nil or #cache.Key == 0 then
        return e_cmd.Error, '缺少键名'
    end
    return e_cmd.OK
end

---comment
---@param ref_param EffectParam
function eff.EffectUserDataSet.execute(ref_param)
    local cache = ref_param.cache
    local new_value
    local key = cache.Key
    if cache.Operation == "Set" then
        new_value = cache.Amount
    elseif cache.Operation == "Add" then
        new_value = cache.Amount + (ref_param:user_data()[key] or cache.Fallback)
    end
    if new_value then
        ref_param:user_data()[key] = new_value
    end

    ref_param:execute_child_on(cache.EndEffect)
end

---------------
-- EffectUserDataCheck
---------------

eff.EffectUserDataCheck={}

---comment
---@param ref_param EffectParam
---@return integer
---@return string?
function eff.EffectUserDataCheck.validate(ref_param)
    local cache = ref_param.cache
    if cache.Key == nil or #cache.Key == 0 then
        return e_cmd.Error, '缺少键名'
    end
    return e_cmd.OK
end

---comment
---@param ref_param EffectParam
function eff.EffectUserDataCheck.execute(ref_param)
    local cache = ref_param.cache
    local key = cache.Key
    local value = ref_param:user_data()[key]
    if not value then
        ref_param:execute_child_on(cache.EffectNoExist)
        return
    end
    local min = type(cache.Min) == "number" and cache.Min or cache.Min(ref_param)
    local max = type(cache.Max) == "number" and cache.Max or cache.Max(ref_param)
    if value < min or value > max then
        ref_param:execute_child_on(cache.EffectFailure)
        return
    end
    ref_param:execute_child_on(cache.EffectSuccess)
end


---------------
-- EffectUserDataCheck
---------------

eff.EffectUnitModifyAttribute={}

---comment
---@param ref_param EffectParam
---@return integer
---@return string
function eff.EffectUnitModifyAttribute.validate(ref_param)
    if(ref_param.cache.TargetType~=e_target_type.unit)then
        return e_cmd.MustTargetUnit, '修改单位效果的目标必须是单位'
    end
    return e_cmd.OK
end


local modify_add = {
    _ = 'add_ex',
}

local modify_set = {
    _ = 'set_ex',
}

local modify_func = {
    Add = modify_add,
    Set = modify_set
}

---comment
---@param caster Unit
---@param unit Unit
---@param prop string
---@param operation string
---@param amount number
---@param is_heal boolean
local function modify_attribute(caster, unit, prop, operation, amount,is_heal, type)
    if amount > 0 and type == 1 and caster and is_heal and prop == '生命' and operation == 'Add' then
        local heal = {
            source = caster,
            target = unit,
            heal = amount,
        }
        caster:heal(heal)
    else
        local fun = modify_func[operation][prop] or modify_func[operation]._
        if fun then
            unit[fun](unit, prop, amount, type)
        end
    end
end

---comment
---@param ref_param EffectParam
function eff.EffectUnitModifyAttribute.execute(ref_param)
    local cache = ref_param.cache
    ---@type Unit Description
    local target_unit =  ref_param.target:get_unit()
    local is_heal = cache.ModifyUnitFlags.IsHeal

    for _, pair in ipairs(cache.KeyValuePairs) do
        local new_value
        local random = pair.Random or 0
        new_value = pair.Value(ref_param)
        new_value = base.math.random_smart(new_value, new_value + random)
        local type = pair.Percentage and 2 or 1
        modify_attribute(
            ref_param:caster():get_unit(),
            target_unit,
            pair.Key,
            cache.Operation,
            new_value,
            is_heal,
            type
        )
    end
end


---------------
-- EffectUnitModifyFacing
---------------

eff.EffectUnitModifyFacing={}

---comment
---@param ref_param EffectParam
---@return integer
---@return string
function eff.EffectUnitModifyFacing.validate(ref_param)
    local cache = ref_param.cache
    if(cache.TargetType~=e_target_type.unit)then
        return e_cmd.MustTargetUnit, '修改单位朝向效果的目标必须是单位'
    end

    local facing = ref_param:parse_angle(cache.Facing)
    if not facing then
        return e_cmd.Error, '朝向配置错误'
    end
    return e_cmd.OK
end

---comment
---@param ref_param EffectParam
function eff.EffectUnitModifyFacing.execute(ref_param)
    local cache = ref_param.cache
    ---@type Unit Description
    local unit =  ref_param.target

    local facing = ref_param:parse_angle(cache.Facing)

    unit:set_facing(facing, cache.Duration * 1000)
end


---------------
-- EffectUnitModifyFacing
---------------

eff.EffectUnitModifyHeight = {}

---comment
---@param ref_param EffectParam
---@return integer
---@return string?
function eff.EffectUnitModifyHeight.validate(ref_param)
    local cache = ref_param.cache
    if cache.TargetType ~= e_target_type.unit then
        return e_cmd.MustTargetUnit, '修改单位高度效果的目标必须是单位'
    end
    return e_cmd.OK
end

---comment
---@param ref_param EffectParam
function eff.EffectUnitModifyHeight.execute(ref_param)
    local cache = ref_param.cache
    ---@type Unit Description
    local unit =  ref_param.target:get_unit()

    if cache.HeightDelta and cache.HeightDelta ~= 0 then
        if not cache.Duration or cache.Duration == 0 then
            unit:add_height(cache.HeightDelta)
            return
        end
        local info = {}
        info.accumulated = 0
        info.update = {
            [true] = cache.HeightDelta / cache.Duration / 33
        }
        info.target = cache.HeightDelta
        base.game:event('游戏-帧', function (trig, _, _)
            base.on_frame_update_unit_height(true, unit, info)
            if info.target == info.accumulated then
                trig:remove()
            end
        end)
    end
end

---------------
-- EffectUnitModifyOwner
---------------

eff.EffectUnitModifyOwner={}

---comment
---@param ref_param EffectParam
---@return integer
---@return string
function eff.EffectUnitModifyOwner.validate(ref_param)
    local cache = ref_param.cache
    if(cache.TargetType~=e_target_type.unit)then
        return e_cmd.MustTargetUnit, '修改单位所属玩家效果的目标必须是单位'
    end
    local player=ref_param:parse_player(cache.Owner)
    if(player==nil or player.type~='player')then
        log.error('未正确指定单位所属玩家'..ref_param:debuginfo())
        return e_cmd.InvalidPlayer, '未正确指定单位所属玩家'
    end
    return e_cmd.OK
end

---comment
---@param ref_param EffectParam
function eff.EffectUnitModifyOwner.execute(ref_param)
    local cache = ref_param.cache
    ---@type Unit Description
    local unit =  ref_param.target

    local player=ref_param:parse_player(cache.Owner)

    unit:set_owner(player)
end


---------------
-- EffectPolarOffset
---------------

eff.EffectPolarOffset = {}

---comment
---@return integer
---@return string
function eff.EffectPolarOffset.validate(_)
    return e_cmd.OK
end

---comment
---@param ref_param EffectParam
function eff.EffectPolarOffset.execute(ref_param)
    local cache = ref_param.cache
    local offset_angle = ref_param:parse_angle(cache.Angle)
    if not offset_angle then
        offset_angle = 0
        ref_param:logfail(e_cmd.error, '坐标偏移节点偏移角度设置错误，是否错误地对点使用单位的朝向？')
    end
    local offset_distance = cache.Distance(ref_param) or 0
    if cache.OffsetByUnitRadius then
        offset_distance = offset_distance + ref_param.target:get_attackable_radius()
    end
    if ref_param.parent and ref_param.parent.cache and ref_param.parent.cache.NodeType == 'EffectPersistLoop' and ref_param.child_index then
        local index = ref_param.child_index - cache.PeriodChangeIndex(ref_param)
        offset_angle = offset_angle + cache.PeriodicAngleChange(ref_param) * index
        offset_distance = offset_distance + cache.PeriodicDistanceChange(ref_param) * index
    end
    local new_point = ref_param.target:get_point():polar_to({offset_angle, offset_distance})
    if cache.PointLocalVar and #cache.PointLocalVar > 0 then
        ref_param:set_var_point(cache.PointLocalVar, new_point)
    end
    ref_param:execute_child_on(cache.TargetEffect, new_point)
end



---------------
-- EffectRandomDelay
---------------

eff.EffectRandomDelay = { persist = true }

---comment
---@return integer
---@return string
function eff.EffectRandomDelay.validate(_)
    return e_cmd.OK
end

---comment
---@param ref_param EffectParam
function eff.EffectRandomDelay.execute(ref_param)
    local cache = ref_param.cache
    local time = cache.BaseAmount(ref_param) * 1000
    local random = math.random() * (cache.RandomAmount(ref_param) or 0) * 1000
    if cache.ActorArray and #cache.ActorArray then
        ref_param.radius = cache.Radius(ref_param)
    end
    base.wait(time + random, function ()
        ref_param:execute_child_on(cache.Effect)
        ref_param:stop()
    end)
end


---------------
-- EffectCustomAction
---------------

eff.EffectCustomAction={}

---comment
---@return integer
---@return string?
function eff.EffectCustomAction.validate(_)
    return e_cmd.OK
end

---comment
---@param ref_param EffectParam
function eff.EffectCustomAction.execute(ref_param)
    local cache = ref_param.cache
    if cache.Func(ref_param) == false then
        return
    end
    ref_param:execute_child_on(cache.Effect)
end


---------------
-- EffectPrint
---------------

eff.EffectPrint={}

---comment
---@return integer
---@return string?
function eff.EffectPrint.validate(_)
    return e_cmd.OK
end

---comment
---@param ref_param EffectParam
function eff.EffectPrint.execute(ref_param)
    local cache = ref_param.cache
    if not cache.On then
        return
    end
    ---@type Unit Description
    log.debug(cache.Output(ref_param))
    ref_param:execute_child_on(cache.Effect)
end

---------------
-- EffectUnitApplyMover
---------------

eff.EffectUnitApplyMover={ persist = true }

---comment
---@param ref_param EffectParam
---@return integer
---@return string
function eff.EffectUnitApplyMover.validate(ref_param)
    local cache = ref_param.cache
    if cache.TargetType ~= e_target_type.unit then
        return e_cmd.MustTargetUnit, '添加移动器的目标必须是单位'
    end

    local mover_cache = eff.cache(cache.Mover)
    if not mover_cache or mover_cache.Class ~= 'mover' then
        return e_cmd.error, '无效的移动器ID'
    end

    return e_cmd.OK
end

---comment
---@param ref_param EffectParam
function eff.EffectUnitApplyMover.execute(ref_param)
    local cache = ref_param.cache

    local unit = ref_param.target:get_unit()

    local mover_target = ref_param:parse_loc(cache.MoverTarget)

    local mover_cache = eff.cache(cache.Mover)

    ref_param.missile_data = ref_param.missile_data or {}

    ref_param.missile= unit
    ref_param.inter_unit = unit

    local mover_table = {
        source = ref_param.source,
        start = unit:get_point(),
        mover = unit,
        target = mover_target,
    }

    for key, value in pairs(mover_cache) do
        mover_table[key] = value
    end

    if mover_table.angle_speed then
        mover_table.angle_speed = mover_table.angle_speed(ref_param)
    end

    if mover_table.distance then
        mover_table.distance = mover_table.distance(ref_param)
    end

    if mover_table.hit_area then
        mover_table.hit_area = mover_table.hit_area(ref_param)
    end

    mover_table.hit_type = mover_cache.DoImpactUnit and '全部' or nil

    local scale = mover_cache.MissileScaling and mover_cache.MissileScaling(ref_param)
    if scale then
        unit:set_scale(scale, mover_cache.Link)
    end
    
    local mover

    if mover_cache.NodeType == 'MoverFollow' then
        if not mover_target or mover_target.type ~= 'unit' then
            log.error '跟随移动器的跟随目标必须是单位'
            return
        end
        mover_table.angle = mover_target:get_point():angle_to(unit:get_point())
        mover = mover_target:follow(mover_table)
        --TODO:其它移动器
    elseif mover_cache.NodeType == 'MoverTo' then
        ref_param.missile_data.missile_range = mover_target:get_point():distance(unit:get_point())
        if ref_param.target.type == e_target_type.unit then
            ref_param.missile_data.missile_range = ref_param.missile_data.missile_range * 2
            mover = base.game:mover_target(mover_table)
        else
            mover = base.game:mover_line(mover_table)
        end
    elseif mover_cache.NodeType == 'MoverFunction' then
        mover = base.game:mover_function(mover_table)
    end

    ref_param.missile_data.impacted_count = 0

    if not mover then
        ref_param:stop()
        return
    end

    ref_param.missile_data.mover = mover
    ref_param.missile_data.mover_table = mover_table

    ---@type TargetFilters Description
    local target_filter=base.target_filters:new(cache.ImpactSearchFilter)

    function mover:on_update(time)
        if mover_cache.FunctionServer then
            mover_cache.FunctionServer(ref_param, time)
        end
    end

    function mover:on_hit(new_target)
        if cache.ImpactEffect and target_filter:validate(ref_param:caster(), new_target) == e_cmd.OK then
            ref_param.it_target = new_target
            ref_param:post_new_target(new_target)
            if(ref_param:is_missile_detached()) then
                ref_param:stop()
                return
            end
            if cache.UnitLocalVar and #cache.UnitLocalVar > 0 then
                ref_param:set_var_unit(cache.UnitLocalVar, new_target)
            end
            -- 从父实例创建
            local child_param=ref_param:create_child()
            child_param:init(ref_param.source,new_target)
            child_param:set_cache(cache.ImpactEffect)
            if(child_param.cache)then
                eff.execute(child_param)
                local point = unit:get_point()
                point[3] = unit:get_height()
                if base.table.unit[cache.temp_impact_model] then
                    point:create_effect(cache.temp_impact_model)
                end
                if cache.ImpactActors then
                    for _, value in ipairs(cache.ImpactActors) do
                        local actor = ref_param:create_actor(value, point, true)
                        if actor then
                            actor:set_position_from(unit)
                        end
                    end
                end
            end
            ref_param.missile_data.impacted_count=ref_param.missile_data.impacted_count+1
            local impact_max = cache.ImpactMaxCount(ref_param)
            if(impact_max > 0)then
                if(impact_max <= ref_param.missile_data.impacted_count)then
                    self:remove()
                    ref_param:stop()
                end
            end
        end
    end

    function mover.on_remove()
        if(ref_param:is_missile_detached()) then
            return
        end
        unit:clear_scale(mover_cache)
    end

    function mover.on_finish()
        if cache.FinishEffect then
            ref_param:execute_child_on(cache.FinishEffect)
        end
    end
end



---------------
-- EffectUnitRemoveMover
---------------

eff.EffectUnitRemoveMover={}

---comment
---@param ref_param EffectParam
---@return integer
---@return string
function eff.EffectUnitRemoveMover.validate(ref_param)
    local cache = ref_param.cache
    if cache.TargetType ~= e_target_type.unit then
        return e_cmd.MustTargetUnit, '移除移动器的目标必须是单位'
    end

    return e_cmd.OK
end

---comment
---@param ref_param EffectParam
function eff.EffectUnitRemoveMover.execute(ref_param)
    local cache = ref_param.cache

    local unit = ref_param.target:get_unit()

    local mover_link = cache.Mover

    local remove_all = #mover_link == 0

    for mover in unit:each_mover() do
        if remove_all or mover.Link == mover_link then
            mover:remove()
        end
    end
end

---------------
-- EffectUnitRemove
---------------

eff.EffectUnitRemove={}

---comment
---@param ref_param EffectParam
---@return integer
---@return string
function eff.EffectUnitRemove.validate(ref_param)
    local cache = ref_param.cache
    if cache.TargetType ~= e_target_type.unit then
        return e_cmd.MustTargetUnit, '移除单位效果的目标必须是单位'
    end

    return e_cmd.OK
end

---comment
---@param ref_param EffectParam
function eff.EffectUnitRemove.execute(ref_param)
    local unit = ref_param.target:get_unit()
    if unit then
        unit:remove()
    end
end


---------------
-- EffectUnitRemove
---------------

eff.EffectUnitKill = {}

---comment
---@param ref_param EffectParam
---@return integer
---@return string?
function eff.EffectUnitKill.validate(ref_param)
    local cache = ref_param.cache
    if cache.TargetType ~= e_target_type.unit then
        return e_cmd.MustTargetUnit, '移除单位效果的目标必须是单位'
    end

    return e_cmd.OK
end

---comment
---@param ref_param EffectParam
function eff.EffectUnitKill.execute(ref_param)
    local unit = ref_param.target:get_unit()
    if unit then
        unit:kill(ref_param:caster())
    end
end

---------------
-- EffectUnitRevive
---------------

eff.EffectUnitRevive={}

---comment
---@param ref_param EffectParam
---@return CmdResult
---@return string?
function eff.EffectUnitRevive.validate(ref_param)
    local cache = ref_param.cache
    if cache.TargetType ~= e_target_type.unit then
        return e_cmd.MustTargetUnit, '复活单位效果的目标必须是单位'
    end

    return e_cmd.OK
end

---comment
---@param ref_param EffectParam
function eff.EffectUnitRevive.execute(ref_param)
    local unit = ref_param.target:get_unit()

    if unit then
        unit:reborn(unit:get_point())
    end
end


---comment
---@param unit Unit
---@param buff_link string
---@return Unit[]?, UnitBuff?
local function get_unit_buff_tracked_units(unit, buff_link)
    local unit_buff = base.unit_buff:get(unit, buff_link)
    if unit_buff then
       return unit_buff.tracked_units, unit_buff
    end
end

---------------
-- EffectBuffTargetsAddTarget
---------------

eff.EffectBuffTargetsAddTarget = {}

---comment
---@param ref_param EffectParam
---@return CmdResult
---@return string?
function eff.EffectBuffTargetsAddTarget.validate(ref_param)
    local cache = ref_param.cache
    if cache.TargetType ~= e_target_type.unit then
        return e_cmd.MustTargetUnit, 'Buff单位组操作的目标必须是单位'
    end

    local buff_owner = ref_param.target:get_unit()

    local _, unit_buff = get_unit_buff_tracked_units(buff_owner, cache.BuffLink)
    if not unit_buff then
        return e_cmd.CannotTargetThat, '目标没有指定buff，无法进行Buff单位组操作'
    end

    local new_unit = ref_param:parse_loc(cache.WhichUnit, e_target_type.unit)

    if not new_unit then
        return e_cmd.CannotTargetThat, '找不到要添加的目标单位'
    end

    return e_cmd.OK
end

---comment
---@param ref_param EffectParam
function eff.EffectBuffTargetsAddTarget.execute(ref_param)
    local cache = ref_param.cache

    ---@type Unit Description
    local buff_owner = ref_param.target:get_unit()

    ---@type Unit[]? Description
    local unit_table, unit_buff = get_unit_buff_tracked_units(buff_owner, cache.BuffLink)

    local new_unit = ref_param:parse_loc(cache.WhichUnit, e_target_type.unit)

    if not unit_table then
        unit_buff.tracked_units = {}
        unit_table = unit_buff and unit_buff.tracked_units or {}
    end

    table.insert(unit_table, new_unit)

    if cache.SnapRange > 0 then
        local start_point = unit_table[1]:get_point()
        local center = buff_owner:get_point()
        local start_angle = buff_owner:get_point():angle_to(start_point) or 0
        local count = #unit_table
        local angle_offset = 360 / count
        for _, value in ipairs(unit_table) do
            value:blink(center:polar_to({start_angle, cache.SnapRange}))
            start_angle = start_angle + angle_offset
        end
    end
end


---------------
-- EffectBuffTargetsRemoveTarget
---------------

eff.EffectBuffTargetsRemoveTarget = {}

---comment
---@param ref_param EffectParam
---@return CmdResult
---@return string?
function eff.EffectBuffTargetsRemoveTarget.validate(ref_param)
    local cache = ref_param.cache
    if cache.TargetType ~= e_target_type.unit then
        return e_cmd.MustTargetUnit, 'Buff单位组操作的目标必须是单位'
    end

    local buff_owner = ref_param.target:get_unit()

    local unit_table, _ = get_unit_buff_tracked_units(buff_owner, cache.BuffLink)

    if not unit_table then
        return e_cmd.NothingToExecute, 'Buff单位组中没有单位'
    end

    local new_unit = ref_param:parse_loc(cache.WhichUnit, e_target_type.unit)

    if not new_unit then
        return e_cmd.CannotTargetThat, '找不到要移除的目标单位'
    end

    return e_cmd.OK
end

---comment
---@param ref_param EffectParam
function eff.EffectBuffTargetsRemoveTarget.execute(ref_param)
    local cache = ref_param.cache

    local buff_owner = ref_param.target:get_unit()

    local unit_table, _ = get_unit_buff_tracked_units(buff_owner, cache.BuffLink)

    local unit_to_remove = ref_param:parse_loc(cache.WhichUnit, e_target_type.unit)

    if unit_table then
        for index, value in ipairs(unit_table) do
            if value ==  unit_to_remove then
                 table.remove(unit_table, index)
            end
         end
    end
end


---------------
-- EffectBuffTargetsClear
---------------

eff.EffectBuffTargetsClear = {}

---comment
---@param ref_param EffectParam
---@return CmdResult
---@return string?
function eff.EffectBuffTargetsClear.validate(ref_param)
    local cache = ref_param.cache
    if cache.TargetType ~= e_target_type.unit then
        return e_cmd.MustTargetUnit, 'Buff单位组操作的目标必须是单位'
    end

    local buff_owner = ref_param.target:get_unit()

    local unit_table, _ = get_unit_buff_tracked_units(buff_owner, cache.BuffLink)

    if not unit_table then
        return e_cmd.NothingToExecute, 'Buff单位组中没有单位'
    end

    return e_cmd.OK
end

---comment
---@param ref_param EffectParam
function eff.EffectBuffTargetsClear.execute(ref_param)
    local cache = ref_param.cache

    local buff_owner = ref_param.target:get_unit()

    local _, unit_buff = get_unit_buff_tracked_units(buff_owner, cache.BuffLink)

    if unit_buff then
        unit_buff.tracked_units = nil
    end
end


---------------
-- EffectBuffTargetsEnum
---------------

eff.EffectBuffTargetsEnum = {}

---comment
---@param ref_param EffectParam
---@return CmdResult
---@return string?
function eff.EffectBuffTargetsEnum.validate(ref_param)
    local cache = ref_param.cache
    if cache.TargetType ~= e_target_type.unit then
        return e_cmd.MustTargetUnit, 'Buff单位组操作的目标必须是单位'
    end

    local buff_owner = ref_param.target:get_unit()

    local unit_table, _ = get_unit_buff_tracked_units(buff_owner, cache.BuffLink)

    if not unit_table then
        return e_cmd.NothingToExecute, 'Buff单位组中没有单位'
    end

    return e_cmd.OK
end

---comment
---@param ref_param EffectParam
function eff.EffectBuffTargetsEnum.execute(ref_param)
    local cache = ref_param.cache

    local buff_owner = ref_param.target:get_unit()

    local unit_table, _ = get_unit_buff_tracked_units(buff_owner, cache.BuffLink)

    for _, value in ipairs(unit_table) do
        ref_param:execute_child_on(cache.Effect, value)
    end
end



---------------
-- EffectReplaceAbil
---------------

eff.EffectReplaceAbil = {}

---comment
---@param ref_param EffectParam
---@return CmdResult
---@return string?
function eff.EffectReplaceAbil.validate(ref_param)
    local cache = ref_param.cache
    if cache.TargetType ~= e_target_type.unit then
        return e_cmd.MustTargetUnit, '替换技能操作的目标必须是单位'
    end
    return e_cmd.OK
end

---comment
---@param ref_param EffectParam
function eff.EffectReplaceAbil.execute(ref_param)
    local cache = ref_param.cache

    local unit = ref_param.target:get_unit()
    if unit then
        unit:replace_skill(cache.AbilOld, cache.AbilNew)
    end
end

---------------
-- EffectUnitModifyOwner
---------------

eff.EffectUnitModifyOwner = {}

---comment
---@param ref_param EffectParam
---@return CmdResult
---@return string?
function eff.EffectUnitModifyOwner.validate(ref_param)
    local cache = ref_param.cache
    if cache.TargetType ~= e_target_type.unit then
        return e_cmd.MustTargetUnit, '修改所属操作的目标必须是单位'
    end

    local player = ref_param:parse_player(cache.Owner)
    if(player==nil or player.type~='player')then
        log.error('未正确指定单位所属玩家'..ref_param:debuginfo())
        return e_cmd.InvalidPlayer, '未正确指定单位所属玩家'
    end
    return e_cmd.OK
end

---comment
---@param ref_param EffectParam
function eff.EffectUnitModifyOwner.execute(ref_param)
    local cache = ref_param.cache

    local unit = ref_param.target:get_unit()
    if unit then
        local player = ref_param:parse_player(cache.Owner)
        if player then
            unit:set_owner(player)
        end
    end
end

---------------
-- EffectCreateItem
---------------

eff.EffectCreateItem={}

---comment
---@param ref_param EffectParam
---@return CmdResult
---@return string?
function eff.EffectCreateItem.validate(ref_param)
    local cache = ref_param.cache

    local item_cache = eff.cache(cache.ItemType)
    if not item_cache then
        log.error('未正确指定物品类型'..ref_param:debuginfo())
        return e_cmd.InvalidItemType, '未正确指定物品类型'
    end

    local count = cache.Count
    if not count or count < 1 then
        log.error('创建数量小于1'..ref_param:debuginfo())
        return e_cmd.NotSupported, '创建数量小于1'
    end

    local range = cache.Range
    if not range or range < 0 then
        log.error('未正确指定创建物品范围'..ref_param:debuginfo())
        return e_cmd.InvalidRange, '未正确指定创建物品范围'
    end

    return e_cmd.OK
end

---comment
---@param ref_param EffectParam
function eff.EffectCreateItem.execute(ref_param)
    local result = eff.EffectCreateItem.validate(ref_param)
    if result ~= eff.e_cmd.OK then
        return
    end

    local cache = ref_param.cache
    local item_type = cache.ItemType
    local count = cache.Count
    local range = cache.Range
    local caster = ref_param:caster()
    local scene = ref_param:get_scene()

    for _ = 1, count, 1 do
        local rnd_offset = base.point(math.random() * 2 * range - range, math.random() * 2 * range - range)
        local item = base.item.create_to_point(item_type, caster:get_point() + rnd_offset, scene)
    end
end