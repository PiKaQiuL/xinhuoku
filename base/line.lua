Line = Line or base.tsc.__TS__Class()
Line.name = 'Line'

---TODO: 设置类型
---base.tsc.__TS__ClassExtends(Line, Array<Point>)

local mt = Line.prototype
mt.type = 'line'

function mt:get(i)
    if self[i] then
        return self[i]
    end
    log.error(string.format('错误的索引[%s](%s)', i, type(i)))
end

function base.line(points)
    return setmetatable(points, mt)
end

return {
    Line = Line
}