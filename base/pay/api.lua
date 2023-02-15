
-- 这里定义的是和支付服务端交互的接口

return {
    REQ_CREATE_PAYMENT = '/api/create-payment',
    REQ_CANCEL_PAYMENT = '/api/cancel-payment',
    REQ_QUERY_PAYMENT = '/api/query-payment',
    REQ_GET_BALANCE = '/api/get-balance',

    STATUS = {
        PENDING = 'pending',
        FINISH = 'finish',
        TIMEOUT = 'timeout',
        CANCEL = 'cancel',
        INVALID = 'invalid'
    },

    ERROR_CODE = {
        SUCCESS = 0,

        PAYMENT_ID_DUPLICATE = 1,
        INVALID_USER_ID = 2,
        INVALID_AMOUNT = 3,

        ACCESS_DENIED = 100,
        PAYMENT_ALREADY_FINISHED = 101,
        SERVICE_ERROR = 102,

        PAYMENT_NOT_EXIST = 200,
    }
}