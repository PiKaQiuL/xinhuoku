for player in base.each_player() do
    player.component = {}
end
local component_name = {} --[[ k = name, v = component]]

function base.get_last_created_component()
    ---@ui 触发器最后创建的简易控件
    ---@belong simple_component
    ---@description 触发器最后创建的简易控件
    ---@applicable value
    return base.last_created_component
end

-- function base.get_component_by_name(name:string) component
--     ---@ui 名称为~1~的简易控件
--     ---@belong simple_component
--     ---@description 通过名称获得简易控件
--     ---@applicable value
--     return name
-- end

function base.component_position(x, y)
    ---@ui x：~1~，y：~2~
    ---@belong simple_component
    ---@description 简易控件位置
    ---@applicable value
    ---@name1 位置x
    ---@name2 位置y
    ---@arg1 0
    ---@arg2 0
    local position = {
        x,
        y
    }
    return position
end
 ---@keyword 简易控件 位置
function base.component_size(width, height)
    ---@ui 宽：~1~，高：~2~
    ---@belong simple_component
    ---@description 简易控件尺寸
    ---@applicable value
    ---@name1 宽度
    ---@name2 高度
    ---@arg1 50
    ---@arg2 50
    local size = {
        width,
        height
    }
    return size
end
 ---@keyword 简易控件 尺寸
function base.component_color(r, g, b)
    ---@ui r：~1~，g：~2~，b：~3~
    ---@belong simple_component
    ---@description 简易控件染色
    ---@applicable value
    ---@name1 红色通道
    ---@name2 绿色通道
    ---@name3 蓝色通道
    ---@arg1 1
    ---@arg2 1
    ---@arg3 1
    local color = {
        r,
        g,
        b
    }
    return color
end
 ---@keyword 简易控件 染色
---------------------------------创建-------------------------------------
function base.create_component_button(position, size, text, visiblity, event_label)
    ---@ui 在~1~创建一个按钮简易控件，尺寸为：~2~，文字为：~3~，初始可见为：~4~，简易控件标签为：~5~
    ---@belong simple_component
    ---@description 创建按钮简易控件
    ---@applicable both
    ---@name1 位置
    ---@name2 尺寸
    ---@name3 文字
    ---@name4 初始可见性
    ---@name5 简易控件标签
    ---@arg1 true
    ---@arg2 base.component_size(120, 60)
    ---@arg3 base.component_position(0, 0)
    local component_id = # base.player(1).component + 1
    local msg = {
        component_id = component_id,
        type = 'button',
        position = position,
        size = size,
        text = text,
        visiblity = visiblity,
        event_label = event_label,
        can_be_clicked = true
    } --[[可被点击]]
    for player in base.each_player() do
        table.insert(player.component, msg)
    end
    base.game:ui'create_component_button'(msg)
    base.last_created_component = component_id
    return component_id
end
 ---@keyword 按钮 创建
function base.create_component_picture(position, size, image, visiblity, event_label)
    ---@ui 在~1~创建一个图片简易控件，尺寸为：~2~，图片为：~3~，初始可见为：~4~，简易控件标签为：~5~
    ---@belong simple_component
    ---@description 创建图片简易控件
    ---@applicable both
    ---@name1 位置
    ---@name2 尺寸
    ---@name3 图片
    ---@name4 初始可见性
    ---@name5 简易控件标签
    ---@arg1 true
    ---@arg2 ''
    ---@arg3 base.component_size(200, 200)
    ---@arg4 base.component_position(0, 0)
    local component_id = # base.player(1).component + 1
    local msg = {
        component_id = component_id,
        type = 'picture',
        position = position,
        size = size,
        image = image,
        visiblity = visiblity,
        event_label = event_label,
        can_be_clicked = true
    } --[[可被点击  opacity = 0,--不透明度]]
    for player in base.each_player() do
        table.insert(player.component, msg)
    end
    base.game:ui'create_component_picture'(msg)
    base.last_created_component = component_id
    return component_id
end
 ---@keyword 按钮 创建
function base.create_component_text(position, size, text, font_size, visiblity, event_label)
    ---@ui 在~1~创建文本简易控件，尺寸为：~2~，文字为：~3~，字号为：~4~，初始可见为：~5~，简易控件标签为：~6~
    ---@belong simple_component
    ---@description 创建文本简易控件
    ---@applicable both
    ---@name1 位置
    ---@name2 尺寸
    ---@name3 文字
    ---@name4 字号
    ---@name5 初始可见性
    ---@name6 简易控件标签
    ---@arg1 true
    ---@arg2 20
    ---@arg3 base.component_size(200, 200)
    ---@arg4 base.component_position(0, 0)
    local component_id = # base.player(1).component + 1
    local msg = {
        component_id = component_id,
        type = 'text',
        position = position,
        size = size,
        text = text,
        font_size = font_size,
        visiblity = visiblity,
        event_label = event_label
    } --[[字号]]
    for player in base.each_player() do
        table.insert(player.component, msg)
    end
    base.game:ui'create_component_text'(msg)
    base.last_created_component = component_id
    return component_id
end ---@keyword 按钮 创建
---------------------------------移除-------------------------------------
function base.destroy_component(component_id)
    ---@ui 移除~1~
    ---@belong simple_component
    ---@description 移除简易控件
    ---@applicable action
    ---@name1 简易控件
    ---@arg1 base.get_last_created_component()
    if component_check(component_id) then
        for player in base.each_player() do
            player.component[component_id] = {}
        end
        base.game:ui'destroy_component'{
            component_id = component_id
        }
    end
end
 ---@keyword 移除 简易控件
---------------------------------更改-------------------------------------
-- function base.set_component_position(component:component, name:string)
--     ---@ui 设置简易控件~1~的名称为
--     ---@description 设置简易控件名称
--     ---@keyword 设置 简易控件 名称
--     ---@belong simple_component
--     ---@applicable action
--     ---@name1 简易控件
--     ---@name2 名称
--     ---@arg1 base.get_last_created_component()
--     local name = tostring(component)
--     player.component[name].position = position
--     base.game:ui 'set_component_position'{
--         name = name,
--         position = position,
--     }
-- end

function base.set_component_position(player, component_id, position)
    ---@ui 设置~1~的~2~位置为~3~
    ---@belong simple_component
    ---@description 设置简易控件位置
    ---@applicable action
    ---@name1 玩家
    ---@name2 简易控件
    ---@name3 位置
    ---@arg1 base.component_position()
    ---@arg2 base.get_last_created_component()
    ---@arg3 base.player(1)
    if component_check(component_id) then
        player.component[component_id].position = position
        player:ui'set_component_position'{
            component_id = component_id,
            position = position
        }
    end
end
 ---@keyword 设置 简易控件 位置
function base.set_component_size(player, component_id, size)
    ---@ui 设置~1~的~2~尺寸为~3~
    ---@belong simple_component
    ---@description 设置简易控件尺寸
    ---@applicable action
    ---@name1 玩家
    ---@name2 简易控件
    ---@name3 尺寸
    ---@arg1 base.component_size()
    ---@arg2 base.get_last_created_component()
    ---@arg3 base.player(1)
    if component_check(component_id) then
        player.component[component_id].size = size
        player:ui'set_component_size'{
            component_id = component_id,
            size = size
        }
    end
end
 ---@keyword 设置 简易控件 尺寸
function base.set_component_visiblity(component_id, player, visiblity)
    ---@ui 令~1~对~2~~3~
    ---@belong simple_component
    ---@description 设置简易控件可见性
    ---@applicable action
    ---@name1 简易控件
    ---@name2 玩家
    ---@name3 可见性
    ---@arg1 true
    ---@arg2 base.player(1)
    ---@arg3 base.get_last_created_component()
    if component_check(component_id) then
        player.component[component_id].visiblity = visiblity
        player:ui'set_component_visiblity'{
            component_id = component_id,
            visiblity = visiblity
        }
    end
end
 ---@keyword 设置 简易控件 可见性
function base.set_component_color(player, component_id, color)
    ---@ui 为~1~的~2~染色，数值为~3~
    ---@belong simple_component
    ---@description 设置简易控件染色
    ---@applicable action
    ---@name1 玩家
    ---@name2 简易控件
    ---@name3 染色
    ---@arg1 base.component_color()
    ---@arg2 base.get_last_created_component()
    ---@arg3 base.player(1)
    if component_check(component_id) then
        player.component[component_id].color = color
        player:ui'set_component_color'{
            component_id = component_id,
            color = color
        }
    end
end
 ---@keyword 设置 简易控件 染色
function base.set_component_can_be_clicked(player, component_id, can_be_clicked)
    ---@ui 设置~1~的~2~~3~可被点击
    ---@belong simple_component
    ---@description 设置简易控件是否可被点击
    ---@applicable action
    ---@name1 玩家
    ---@name2 简易控件
    ---@name3 可被点击
    ---@arg1 true
    ---@arg2 base.get_last_created_component()
    ---@arg3 base.player(1)
    if component_check(component_id) then
        local component_type = player.component[component_id].type
        if component_type_check(component_type, {
            'button',
            'picture'
        }) then
            player.component[component_id].can_be_clicked = can_be_clicked
            player:ui'set_component_can_be_clicked'{
                component_id = component_id,
                can_be_clicked = can_be_clicked
            }
        end
    end
end
 ---@keyword 设置 简易控件 可被点击
function base.set_component_text(player, component_id, text)
    ---@ui 设置~1~的~2~文本为~3~
    ---@belong simple_component
    ---@description 设置简易控件文本
    ---@applicable action
    ---@name1 玩家
    ---@name2 简易控件
    ---@name3 文本
    ---@arg1 base.get_last_created_component()
    ---@arg2 base.player(1)
    if component_check(component_id) then
        local component_type = player.component[component_id].type
        if component_type_check(component_type, {
            'button',
            'text'
        }) then
            player.component[component_id].text = text
            player:ui'set_component_text'{
                component_id = component_id,
                text = text
            }
        end
    end
end
 ---@keyword 设置 简易控件 文本
function base.set_component_font_size(player, component_id, font_size)
    ---@ui 设置~1~的~2~字号为~3~
    ---@belong simple_component
    ---@description 设置简易控件字号
    ---@applicable action
    ---@name1 玩家
    ---@name2 简易控件
    ---@name3 字号
    ---@arg1 base.get_last_created_component()
    ---@arg2 base.player(1)
    if component_check(component_id) then
        local component_type = player.component[component_id].type
        if component_type_check(component_type, {
            'button',
            'text'
        }) then
            player.component[component_id].font_size = font_size
            player:ui'set_component_text'{
                component_id = component_id,
                font_size = font_size
            }
        end
    end
end
 ---@keyword 设置 简易控件 字号
function base.set_component_image(player, component_id, image)
    ---@ui 设置~1~的~2~图片为~3~
    ---@belong simple_component
    ---@description 设置简易控件图片
    ---@applicable action
    ---@name1 玩家
    ---@name2 简易控件
    ---@name3 图片路径
    ---@arg1 base.get_last_created_component()
    ---@arg2 base.player(1)
    if component_check(component_id) then
        local component_type = player.component[component_id].type
        if component_type_check(component_type, {
            'picture'
        }) then
            player.component[component_id].image = image
            player:ui'set_component_image'{
                component_id = component_id,
                image = image
            }
        end
    end
end
 ---@keyword 设置 简易控件 图片
function base.set_component_opacity(player, component_id, opacity)
    ---@ui 设置~1~的~2~图片不透明度为~3~
    ---@belong simple_component
    ---@description 设置简易控件图片不透明度
    ---@applicable action
    ---@name1 玩家
    ---@name2 简易控件
    ---@name3 不透明度
    ---@arg1 base.get_last_created_component()
    ---@arg2 base.player(1)
    if component_check(component_id) then
        local component_type = player.component[component_id].type
        if component_type_check(component_type, {
            'picture'
        }) then
            player.component[component_id].opacity = opacity
            player:ui'set_component_opacity'{
                component_id = component_id,
                opacity = opacity
            }
        end
    end
end
 ---@keyword 设置 简易控件 图片 不透明度
function base.set_component_zoom_type(player, component_id, zoom_type)
    ---@ui 设置~1~的~2~图片缩放方式为~3~
    ---@belong simple_component
    ---@description 设置简易控件图片缩放方式
    ---@applicable action
    ---@name1 玩家
    ---@name2 简易控件
    ---@name3 缩放方式
    ---@arg1 "none"
    ---@arg2 base.get_last_created_component()
    ---@arg3 base.player(1)
    if component_check(component_id) then
        local component_type = player.component[component_id].type
        if component_type_check(component_type, {
            'picture'
        }) then
            player.component[component_id].zoom_type = zoom_type
            player:ui'set_component_zoom_type'{
                component_id = component_id,
                zoom_type = zoom_type
            }
        end
    end
end
 ---@keyword 设置 简易控件 图片 缩放
function base.set_component_auto_line_feed(player, component_id, auto_line_feed)
    ---@ui 设置~1~的~2~文本自动换行为~3~
    ---@belong simple_component
    ---@description 设置简易控件文本自动换行
    ---@applicable action
    ---@name1 玩家
    ---@name2 简易控件
    ---@name3 自动换行
    ---@arg1 base.get_last_created_component()
    ---@arg2 base.player(1)
    if component_check(component_id) then
        local component_type = player.component[component_id].type
        if component_type_check(component_type, {
            'text'
        }) then
            player.component[component_id].auto_line_feed = auto_line_feed
            player:ui'set_component_zoom_type'{
                component_id = component_id,
                auto_line_feed = auto_line_feed
            }
        end
    end
end
 ---@keyword 设置 简易控件 文本 自动换行
function base.set_component_text_align(player, component_id, align)
    ---@ui 设置~1~的~2~文本横向对齐方式为~3~
    ---@belong simple_component
    ---@description 设置简易控件文本横向对齐方式
    ---@applicable action
    ---@name1 玩家
    ---@name2 简易控件
    ---@name3 横向对齐方式
    ---@arg1 "center"
    ---@arg2 base.get_last_created_component()
    ---@arg3 base.player(1)
    if component_check(component_id) then
        local component_type = player.component[component_id].type
        if component_type_check(component_type, {
            'text'
        }) then
            player.component[component_id].text_align = text_align
            player:ui'set_component_text_align'{
                component_id = component_id,
                align = align
            }
        end
    end
end
 ---@keyword 设置 简易控件 文本 对齐
function base.set_component_text_vertical_align(player, component_id, vertical_align)
    ---@ui 设置~1~的~2~文本纵向对齐方式为~3~
    ---@belong simple_component
    ---@description 设置简易控件文本纵向对齐方式
    ---@applicable action
    ---@name1 玩家
    ---@name2 简易控件
    ---@name3 纵向对齐方式
    ---@arg1 "center"
    ---@arg2 base.get_last_created_component()
    ---@arg3 base.player(1)
    if component_check(component_id) then
        local component_type = player.component[component_id].type
        if component_type_check(component_type, {
            'text'
        }) then
            player.component[component_id].text_vertical_align = text_vertical_align
            player:ui'set_component_text_vertical_align'{
                component_id = component_id,
                vertical_align = vertical_align
            }
        end
    end
end
 ---@keyword 设置 简易控件 文本 对齐
---------------------------------读取-------------------------------------

function base.get_component_position(player, component_id)
    ---@ui ~1~的~2~位置
    ---@belong simple_component
    ---@description 获得简易控件位置
    ---@applicable value
    ---@name1 简易控件
    ---@name2 玩家
    ---@arg1 base.get_last_created_component()
    ---@arg2 base.player(1)
    if component_check(component_id) then
        return player.component[component_id].position
    end
end
 ---@keyword 简易控件 位置
function base.get_component_size(player, component_id)
    ---@ui ~1~的~2~尺寸
    ---@belong simple_component
    ---@description 获得简易控件尺寸
    ---@applicable value
    ---@name1 简易控件
    ---@name2 玩家
    ---@arg1 base.get_last_created_component()
    ---@arg2 base.player(1)
    if component_check(component_id) then
        return player.component[component_id].size
    end
end
 ---@keyword 简易控件 尺寸
function base.get_component_visiblity(component_id, player)
    ---@ui ~1~是否对~2~可见
    ---@belong simple_component
    ---@description 简易控件是否可见
    ---@applicable value
    ---@name1 简易控件
    ---@name2 玩家
    ---@arg1 base.get_last_created_component()
    ---@arg2 base.player(1)
    if component_check(component_id) then
        return player.component[component_id].visiblity
    end
end ---@keyword 简易控件 是否 可见
function base.get_component_color(player, component_id)
    ---@ui ~1~的~2~染色参数
    ---@belong simple_component
    ---@description 获得简易控件染色参数
    ---@applicable value
    ---@name1 玩家
    ---@name2 简易控件
    ---@arg1 base.get_last_created_component()
    ---@arg2 base.player(1)
    if component_check(component_id) then
        return player.component[component_id].color
    end
end
 ---@keyword 简易控件 染色
function base.get_component_can_be_clicked(player, component_id)
    ---@ui ~1~的~2~是否可被点击
    ---@belong simple_component
    ---@description 获得简易控件是否可被点击
    ---@applicable value
    ---@name1 玩家
    ---@name2 简易控件
    ---@arg1 base.get_last_created_component()
    ---@arg2 base.player(1)
    if component_check(component_id) then
        local component_type = player.component[component_id].type
        if component_type_check(component_type, {
            'button',
            'picture'
        }) then
            return player.component[component_id].can_be_clicked
        end
    end
end
 ---@keyword 简易控件 可被点击
function base.get_component_text(player, component_id)
    ---@ui ~1~的~2~文本
    ---@belong simple_component
    ---@description 获得简易控件文本
    ---@applicable value
    ---@name1 玩家
    ---@name2 简易控件
    ---@arg1 base.get_last_created_component()
    ---@arg2 base.player(1)
    if component_check(component_id) then
        local component_type = player.component[component_id].type
        if component_type_check(component_type, {
            'button',
            'text'
        }) then
            return player.component[component_id].text
        end
    end
end
 ---@keyword 简易控件 文本
function base.get_component_font_size(player, component_id)
    ---@ui ~1~的~2~字号
    ---@belong simple_component
    ---@description 获得简易控件字号
    ---@applicable value
    ---@name1 玩家
    ---@name2 简易控件
    ---@arg1 base.get_last_created_component()
    ---@arg2 base.player(1)
    if component_check(component_id) then
        local component_type = player.component[component_id].type
        if component_type_check(component_type, {
            'button',
            'text'
        }) then
            return player.component[component_id].font_size
        end
    end
end
 ---@keyword 简易控件 字号
function base.get_component_image(player, component_id)
    ---@ui ~1~的~2~图片
    ---@belong simple_component
    ---@description 获得简易控件图片
    ---@applicable value
    ---@name1 玩家
    ---@name2 简易控件
    ---@arg1 base.get_last_created_component()
    ---@arg2 base.player(1)
    if component_check(component_id) then
        local component_type = player.component[component_id].type
        if component_type_check(component_type, {
            'picture'
        }) then
            return player.component[component_id].image
        end
    end
end
 ---@keyword 简易控件 图片
function base.get_component_opacity(player, component_id)
    ---@ui ~1~的~2~不透明度
    ---@belong simple_component
    ---@description 获得简易控件不透明度
    ---@applicable value
    ---@name1 玩家
    ---@name2 简易控件
    ---@arg1 base.get_last_created_component()
    ---@arg2 base.player(1)
    if component_check(component_id) then
        local component_type = player.component[component_id].type
        if component_type_check(component_type, {
            'picture'
        }) then
            return player.component[component_id].opacity
        end
    end
end
 ---@keyword 简易控件 不透明度
function base.get_component_zoom_type(player, component_id)
    ---@ui ~1~的~2~图片缩放方式
    ---@belong simple_component
    ---@description 获得简易控件图片缩放方式
    ---@applicable value
    ---@name1 玩家
    ---@name2 简易控件
    ---@arg1 base.get_last_created_component()
    ---@arg2 base.player(1)
    if component_check(component_id) then
        local component_type = player.component[component_id].type
        if component_type_check(component_type, {
            'picture'
        }) then
            return player.component[component_id].zoom_type
        end
    end
end
 ---@keyword 简易控件 图片 缩放方式
function base.get_component_auto_line_feed(player, component_id)
    ---@ui ~1~的~2~文本是否自动换行
    ---@belong simple_component
    ---@description 获得简易控件文本是否自动换行
    ---@applicable value
    ---@name1 玩家
    ---@name2 简易控件
    ---@arg1 base.get_last_created_component()
    ---@arg2 base.player(1)
    if component_check(component_id) then
        local component_type = player.component[component_id].type
        if component_type_check(component_type, {
            'button',
            'text'
        }) then
            return player.component[component_id].auto_line_feed
        end
    end
end
 ---@keyword 简易控件 文本 自动换行
function base.get_component_text_align(player, component_id)
    ---@ui ~1~的~2~文本横向对齐方式
    ---@belong simple_component
    ---@description 获得简易控件文本横向对齐方式
    ---@applicable value
    ---@name1 玩家
    ---@name2 简易控件
    ---@arg1 base.get_last_created_component()
    ---@arg2 base.player(1)
    if component_check(component_id) then
        local component_type = player.component[component_id].type
        if component_type_check(component_type, {
            'text'
        }) then
            return player.component[component_id].align
        end
    end
end
 ---@keyword 简易控件 文本 对齐
function base.get_component_text_vertical_align(player, component_id)
    ---@ui ~1~的~2~文本纵向对齐方式
    ---@belong simple_component
    ---@description 获得简易控件文本纵向对齐方式
    ---@applicable value
    ---@name1 玩家
    ---@name2 简易控件
    ---@arg1 base.get_last_created_component()
    ---@arg2 base.player(1)
    if component_check(component_id) then
        local component_type = player.component[component_id].type
        if component_type_check(component_type, {
            'text'
        }) then
            return player.component[component_id].vertical_align
        end
    end
end

 ---@keyword 简易控件 文本 对齐
---------------------------------接受-------------------------------------

base.ui.proto.component_event = function(player, msg)
    print('点击了', msg.event_label)
    -- player:event_notify('简易控件-点击', player, msg.event_label)
    player:event_notify('玩家-点击简易控件', player, msg.event_label)
end