--提供给用户使用的一些小辅助工具集
local co  = include 'base.co'

--查询最近跟自己一起玩的玩家列表
base.auxiliary.latest_games = function(userid, mapname, cb_function)
    local sql_in = "(SELECT temp.session_id FROM (SELECT session_id FROM stat_db.session_start_stat where user_id = " .. userid .. " and game_map_name = '" .. mapname .. "'"
    sql_in = sql_in .. " order by start_time desc limit 5) as temp)"
    local sql = "SELECT session_id, user_id, start_time FROM stat_db.session_start_stat where session_id IN " .. sql_in
    --所有总表
    local all_table = {}     

    co.async(function(sql)
        --print('together_map ready to sql: '..sql)
        --log.info('together_map ready to sql: '..sql)

        local query_sql = co.wrap(base.backend.query_sql_async)
        local result_set = query_sql(sql, {})

        if type(result_set) ~= 'table' then
            print('together_map: query_sql error')
            log.info('together_map: query_sql error')
            return
        end

        local rows, row_size, cols, col_size = result_set.dump()

        --将查询结果插入表里
        for index, col_content in pairs(rows) do
            
            --每个玩法场次
            local sessionid = rows[index][1]

            if all_table[sessionid] == nil then
                all_table[sessionid] = {}
            end

            if all_table[sessionid].user_list == nil then
                all_table[sessionid].user_list = {}
            end

            --每个session有哪些玩家参与 
            table.insert(all_table[sessionid].user_list, rows[index][2])
            --开始时间
            all_table[sessionid].start_time = rows[index][3]
        end   
        
        --调用回调函数
        cb_function(all_table)
    end, sql)
end