console.log('Welcome to InfinityPool')

const app = require('express')()
const http = require('http').createServer(app)
// const io = require('socket.io')(http)

const WebSocket = require('ws')
const wss = new WebSocket.Server({ port: 3000 })

const nano = require('nano')('http://localhost:5984')
const winston = require('winston')

const moment = require('moment')

/* Initialize database connection. */
const dbConn = nano.db.use('nametag')

/* Set keep-alive interval. */
const KEEP_ALIVE_INTERVAL = 15000

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

const logger = winston.createLogger({
    level: 'debug',
    format: winston.format.json(),
    transports: [
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
wss.broadcast = function (_data) {
    wss.clients.forEach(function (_client) {
        if (_client.readyState === WebSocket.OPEN) {
            _client.send(_data)
        }
    })
}

wss.on('close', () => {
    console.log('Closing client connection.')
})

wss.on('connection', function (_ws, _req) {
    /* Set flag. */
    _ws.isAlive = true

    /* Handle pong. */
    _ws.on('pong', _heartbeat)

    if (_req.headers && _req.headers['x-forwarded-for']) {
        const ip = _req.headers['x-forwarded-for'].split(/\s*,\s*/)[0]

        console.log(`Connection from [ ${ip} ]`)
    }

    _ws.on('message', function (_message) {
        console.log('received: %s', _message)

        logger.debug(`received: [ ${_message} ]`)
    })

    _ws.send('hi there, this is Minado.Network..')
})

/* Start broadcasting. */
// const interval = setInterval(() => {
//     console.log('broadcasting..')
//
//     wss.broadcast(`Just want to say hi! the time is [ ${new Date()} ]`)
// }, KEEP_ALIVE_INTERVAL)

/* Start ping interval. */
const interval = setInterval(function () {
    /* Ping each client. */
    wss.clients.forEach(function (_ws) {
        console.log('searching..')

        /* Test for recent heartbeat. */
        if (_ws.isAlive === false) {
            console.log('Terminating connection to', _ws)

            /* Terminate connection. */
            return _ws.terminate()
        }

        /* Set flag. */
        _ws.isAlive = false

        /* Ping client. */
        _ws.ping(_noop)
    })
}, KEEP_ALIVE_INTERVAL)

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
