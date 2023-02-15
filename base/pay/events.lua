
-- 支付相关事件

return {

    -- 收到此事件时需要禁用 ui
    DISABLE_UI = 'disable_ui',

    -- 收到此事件时可以启用 ui
    ENABLE_UI = 'enable_ui',

    -- 如果用户点击了 '完成支付' 但实际上并未完成会触发此事件
    UNFINISHED = 'unfinished'
}