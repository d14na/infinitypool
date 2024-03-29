const http = require('http')
const nodeStatic = require('node-static')
const sockjs = require('sockjs')
const winston = require('winston')

const ethers = require('ethers')
const moment = require('moment')

/* Set keep-alive interval. */
const KEEP_ALIVE_INTERVAL = 15000

/* Set port number. */
const PORT = 3000

/* Initialize SockJS (fallback) URL. */
const sockjs_url = 'https://cdn.0net.io/libs/sockjs-client/1.1.4/js/sockjs.min.js'

/* Create SockJS (WebSocket) server. */
const ws = sockjs.createServer({ sockjs_url })

/**
 * Calculate Log Name (by Date)
 */
const _calcLogName = function (_isError) {
    const today = moment().format('YYYYMMDD')

    if (_isError) {
        return `${today}-error.log`
    } else {
        return `${today}.log`
    }
}

/* Initialize Winston. */
const logger = winston.createLogger({
    level: 'debug',
    format: winston.format.json(),
    transports: [
        new winston.transports.Console(),
        new winston.transports.File({ filename: './logs/' + _calcLogName(true), level: 'error' }),
        new winston.transports.File({ filename: './logs/' + _calcLogName() })
    ]
})

/* Development formatting (for Winston). */
if (process.env.NODE_ENV !== 'production') {
    logger.add(new winston.transports.Console({
        format: winston.format.simple()
    }))
}

/* Initialize connections pool. */
let connPool = {}

/* Initialize token parameters. */
let tokenParams = {}

/* Initialize static files. */
const staticDir = new nodeStatic.Server(__dirname)

/* Initialize web server. */
const server = http.createServer()

/* Add request listener. */
server.addListener('request', function (req, res) {
    staticDir.serve(req, res)
})

/* Add upgrade listener. */
server.addListener('upgrade', function (req, res) {
    res.end()
})

/* Install WebSocket server handlers. */
ws.installHandlers(server)

/* Initialize error listener. */
ws.on('error', require('./handlers').error)

/* Handle new client connection. */
ws.on('connection', (_conn) => {
    let handler = require('./handlers').connection
    let resp = handler(_conn, connPool, logger)
})

/* Start listening (for incoming CLIENT connections). */
// NOTE Localhost proxy via Nginx (providing TLS/SSL).
server.listen(PORT, '0.0.0.0')

console.log('\n*** Welcome to InfinityPool ***\n\n')

/* No-op. */
function _noop () {}

/* Heartbeat. */
function _heartbeat () {
    console.log('got a heartbeat.')

    this.isAlive = true
}
