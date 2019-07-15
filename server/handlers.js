const ethers = require('ethers')

const broadcast = require('./helpers').broadcast

const getChallenge = require('./network').getChallenge

/**
 * Handle Error
 */
const _errorHandler = function (_err) {
    console.error('ERROR:', _err)
}

const _handleClose = function () {
    console.log('Closed connection.')
}

/**
 * Handle Connection
 */
const connection = async function (_conn, _pool, _db, _logger) {
    // console.log('CONN', _conn)

    /* Set connection id. */
    const connId = _conn.id

    /* Add/update connection in pool. */
    _pool[connId] = _conn

    /* Build session (for database). */
    const session = {
        id: _conn.id,
        headers: _conn.headers,
        protocol: _conn.protocol
    }

    if (_conn.headers && _conn.headers['x-forwarded-for']) {
        let ip = _conn.headers['x-forwarded-for'].split(/\s*,\s*/)[0]

        _logger.info(`Connection from [ ${ip} ]`)
    }

    /* Insert into (success) database. */
    let result = await _db.insert(session)
        .catch(_error => {
            console.error('DB ERROR:', _error)
        })

    // console.log('DB RESULT', result)

    /* Initialize error listener. */
    _conn.on('error', _errorHandler)

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

        // let connCount = Object.keys(_pool).length
        //
        // let note = {
        //     id: connId,
        //     welcome: 'please be patient...',
        //     timestamp: new Date(),
        //     connCount: connCount
        // }

        /* Broadcast to all (except sender). */
        // broadcast(note, _pool, connId)
        broadcast(data, _pool, connId)
    })

    /* Set ZeroGold address. */
    // FIXME Pull this from `db.0net.io`.
    const zgAddress = '0xf6E9Fc9eB4C20eaE63Cb2d7675F4dD48B008C531' // KOVAN

    let challenge = await getChallenge(zgAddress)
    challenge = challenge.toHexString()

    const config = require('./config.json')
    const address = config['purse'].address

    let pkg = {
        action: 'init',
        address,
        challenge,
        difficulty: '1',
        target: '0x040000000000000000000000000000000000000000000000000000000000'
    }

    console.log('sending pkg', pkg)

    _conn.write(JSON.stringify(pkg))
}

module.exports = {
    connection,
    error: _errorHandler
}
