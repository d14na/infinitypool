const http = require('http')
const nano = require('nano')('http://localhost:5984')
const node_static = require('node-static')
const sockjs = require('sockjs')
const winston = require('winston')

const ethers = require('ethers')
const moment = require('moment')

/* Initialize database connection. */
// const dbConn = nano.db.use('ministo')
// const dbConn = nano.db.use('ministo-ropsten')
const dbConn = nano.db.use('ministo_sessions')

/* Set keep-alive interval. */
const KEEP_ALIVE_INTERVAL = 15000

/* Set port number. */
const PORT = 3000

/* Initialize connections pool. */
let connPool = {}

/* Initialize SockJS (fallback) URL. */
const sockjs_url = 'https://cdn.0net.io/libs/sockjs-client/1.1.4/js/sockjs.min.js'

/* Create SockJS (WebSocket) server. */
const ws = sockjs.createServer({ sockjs_url })

/* Initialize error listener. */
ws.on('error', (_err) => {
    console.error('WebSockets fatal error', _err)
})

/* Handle new client connection. */
ws.on('connection', async (_conn) => {
    // console.log('CONN', _conn)

    /* Set connection id. */
    const connId = _conn.id

    /* Add/update connection in pool. */
    connPool[connId] = _conn

    /* Build session (for database). */
    const session = {
        id: _conn.id,
        headers: _conn.headers,
        protocol: _conn.protocol
    }

    /* Insert into (success) database. */
    let result = await dbConn.insert(session)
        .catch(_error => {
            console.error('DB ERROR:', _error)
        })

    console.log('DB RESULT', result)

    /* Initialize error listener. */
    _conn.on('error', _handleError)

    /* Initialize close listener. */
    _conn.on('close', _handleClose)

    /* Initialize data (message) listener. */
    _conn.on('data', (_data) => {
        /* Initialize data. */
        let data = null

        /* Protect server process from FAILED parsing. */
        try {
            /* Parse the incoming data. */
            data = JSON.parse(_data)
        } catch (_err) {
            return console.log('Error parsing incoming data', _data)
        }

        console.log('DATA (parsed)', data)

        let connCount = Object.keys(connPool).length

        let note = {
            id: connId,
            welcome: 'please be patient...',
            timestamp: new Date(),
            connCount: connCount
        }

        /* Broadcast to all (except sender). */
        _broadcast(note, connId)
    })
})

const _handleError = function (_err) {
    console.log('ERROR:', _err)
}

const _handleClose = function (_e) {
    console.log('CLOSED:', _e)
}

/**
 * Broadcast (to all connections)
 */
const _broadcast = function (_pkg, connId = null) {
    Object.keys(connPool).forEach(function(_k, _i) {
        /* Set connection (from pool). */
        let conn = connPool[_k]

        /* Filter out a connection id. */
        // NOTE: Used primarily to exclude message sender.
        if (connId !== conn.id) {
            /* Send "stringified" package. */
            conn.write(JSON.stringify(_pkg))
        }
    })
}

/* Initialize static files. */
const static_directory = new node_static.Server(__dirname)

const server = http.createServer()

server.addListener('request', function (req, res) {
    static_directory.serve(req, res)
})

server.addListener('upgrade', function (req, res) {
    res.end()
})

/* Install WebSocket server handlers. */
ws.installHandlers(server)

/* Start listening (for incoming CLIENT connections). */
// NOTE Localhost proxy via Nginx (providing TLS/SSL).
server.listen(PORT, '0.0.0.0')



// const app = require('express')()
// const http = require('http').createServer(app)
// const io = require('socket.io')(http)

// const WebSocket = require('ws')
// const wss = new WebSocket.Server({ port: 3000 })

// io.on('connection', function (_socket) {
//     // console.log('an user connected', _socket)
//     console.log('an user connected')
//
//     const clientId = _socket.id
//     console.log('Client Id', clientId)
//
//     const handshake = _socket.handshake
//     console.log('Handshake', handshake)
// })

// http.listen(3000, function () {
//     console.log('listening on *:3000')
// })

function _noop () {}

function _heartbeat () {
    console.log('got a heartbeat.')

    this.isAlive = true
}

console.log('Welcome to InfinityPool')

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

if (process.env.NODE_ENV !== 'production') {
    logger.add(new winston.transports.Console({
        format: winston.format.simple()
    }))
}

// Broadcast to all.
// wss.broadcast = function (_data) {
//     wss.clients.forEach(function (_client) {
//         if (_client.readyState === WebSocket.OPEN) {
//             _client.send(_data)
//         }
//     })
// }

// wss.on('close', () => {
//     console.log('Closing client connection.')
// })

// wss.on('connection', function (_ws, _req) {
//     /* Log connection source (ip address). */
//     if (_req.headers && _req.headers['x-forwarded-for']) {
//         const ip = _req.headers['x-forwarded-for'].split(/\s*,\s*/)[0]
//
//         logger.info(`Connection from [ ${ip} ]`)
//     }
//
//     /* Set flag. */
//     _ws.isAlive = true
//
//     /* Handle pong. */
//     _ws.on('pong', _heartbeat)
//
//     /* Handle message. */
//     _ws.on('message', function (_message) {
//         logger.debug(`received: [ ${_message} ]`)
//     })
//
//     /* Set action. */
//     const action = 'init'
//
//     /* Set address. */
//     const address = '0xaE6A6bfDe0B226302ccA6155f487D1f46e6AC821'
//
//     /* Set challenge. */
//     // const challengeNum = ethers.utils.bigNumberify(
//     //     '71152175942061195429752053136004011344333682236262982809903143900646877130177')
//     // const challenge = challengeNum.toHexString()
//     const challenge = '0x8a4ef18d3b802dab9164b66ee1b07dc8b64eec8a7b3722bb09a053d832b97086'
//
//     /* Set difficulty. */
//     const difficulty = 1
//
//     /* Set target. */
//     // const target = '27606985387162255149739023449108101809804435888681546220650096895197184'
//     // const target = '441711766194596082395824375185729628956870974218904739530401550323154944' // 64
//     // const target = '11579208923731619542357098500868790785326998466564056403945758400791312963993' // 256
//     // const target = '0x04000000000000000000000000000000000000000000000000000000000000' // easy solve
//     const target = '0x040000000000000000000000000000000000000000000000000000000000' // 0xToken diff-1
//
//     /* Set metadata. */
//     const metadata = 'ZeroGold - 0GOLD'
//
//     /* Build welcome package. */
//     const pkg = {
//         action,
//         address,
//         challenge,
//         difficulty,
//         target,
//         metadata
//     }
//
//     /* Send welcome package. */
//     _ws.send(JSON.stringify(pkg))
// })

/* Start broadcasting. */
// const interval = setInterval(() => {
//     console.log('broadcasting..')
//
//     wss.broadcast(`Just want to say hi! the time is [ ${new Date()} ]`)
// }, KEEP_ALIVE_INTERVAL)

/* Start ping interval. */
// const interval = setInterval(function () {
//     /* Ping each client. */
//     wss.clients.forEach(function (_ws) {
//         console.log('searching..')
//
//         /* Test for recent heartbeat. */
//         if (_ws.isAlive === false) {
//             console.log('Terminating connection to', _ws)
//
//             /* Terminate connection. */
//             return _ws.terminate()
//         }
//
//         /* Set flag. */
//         _ws.isAlive = false
//
//         /* Ping client. */
//         _ws.ping(_noop)
//     })
// }, KEEP_ALIVE_INTERVAL)

const submitShare = async function (args, callback) {
    /* Initialize valid JSON flag. */
    let validJSONSubmit = true

    /* Localize arguments. */
    const nonce           = args[0]
    const minerEthAddress = args[1]
    const digest          = args[2]
    const difficulty      = args[3]
    const challengeNumber = args[4]

    /* Validate arguments. */
    if (
        difficulty      === null ||
        nonce           === null ||
        minerEthAddress === null ||
        challengeNumber === null ||
        digest          === null
    ) {
        validJSONSubmit = false

        return callback(null, validJSONSubmit)
    }

    /* Set minimum share difficulty. */
    // const minShareDifficulty = self.getPoolMinimumShareDifficulty()
    const minShareDifficulty = 2**6 // 64
    // const minShareDifficulty = 2**16 // 65536

    console.log('minShareDifficulty', minShareDifficulty)

    /* Validate minimum share difficulty. */
    if (difficulty < minShareDifficulty) {
        validJSONSubmit = false

        return callback(null, validJSONSubmit)
    }

    // const poolEthAddress = self.getMintingAccount().address
    const poolEthAddress = require('./config')['purse'].address

    const poolChallengeNumber = await self.tokenInterface
        .getPoolChallengeNumber()

    const computedDigest = web3utils.soliditySha3(
        poolChallengeNumber, poolEthAddress, nonce)

    const digestBigNumber = web3utils.toBN(digest)
    const claimedTarget = self.getTargetFromDifficulty(difficulty)

    /* Validate claimed target. */
    if (
        computedDigest !== digest ||
        digestBigNumber.gt(claimedTarget)
    ) {
        validJSONSubmit = false

        return callback(null, validJSONSubmit)
    }

    /* Set ETH block number. */
    const block = await self.redisInterface.getEthBlockNumber()

    const shareData = {
        block,
        nonce,
        minerEthAddress,
        challengeNumber,
        digest,
        difficulty
    }

    const response = await self.redisInterface.pushToRedisList(
        'queued_shares_list', JSON.stringify(shareData))

    callback(null, validJSONSubmit)
}
