const ethers = require('ethers')
const moment = require('moment')
const nano = require('nano')('http://localhost:5984')

const broadcast = require('./helpers').broadcast

const getChallenge = require('./network').getChallenge
const getTarget = require('./network').getTarget

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
const connection = async function (_conn, _pool, _logger) {
    // console.log('CONN', _conn)

    /* Set connection id. */
    const connId = _conn.id

    /* Add/update connection in pool. */
    _pool[connId] = _conn

    /* Build session (for database). */
    const session = {
        id: _conn.id,
        headers: _conn.headers,
        protocol: _conn.protocol,
        createdAt: moment().valueOf()
    }

    if (_conn.headers && _conn.headers['x-forwarded-for']) {
        let ip = _conn.headers['x-forwarded-for'].split(/\s*,\s*/)[0]

        _logger.info(`Connection from [ ${ip} ]`)
    }

    /* Initialize db connection. */
    const dbSessions = nano.db.use('minado_sessions')

    /* Insert into (success) database. */
    let result = await dbSessions.insert(session)
        .catch(_error => {
            console.error('DB ERROR:', _error)
        })

    // console.log('DB RESULT', result)

    /* Initialize error listener. */
    _conn.on('error', _errorHandler)

    /* Initialize close listener. */
    _conn.on('close', _handleClose)

    /* Initialize data (message) listener. */
    _conn.on('data', async (_data) => {
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

        /* Validate share. */
        if (data && data.digest && data.solution) {
            /* Initialize db connection. */
            // const dbShares = nano.db.use('ministo_shares')
            const dbShares = nano.db.use('ministo_shares_kovan')

            /* Build share package. */
            const share = {
                ...data,
                createdAt: moment().valueOf()
            }

            /* Insert into (success) database. */
            let result = await dbShares.insert(share)
                .catch(_error => {
                    console.error('DB ERROR:', _error)
                })

            // console.log('DB RESULT', result)

            /* Validate MINTING solution. */
            if (1 === 1) {
                let token = data.token
                let digest = data.digest
                let nonce = data.solution

                const mint = require('./network').mint

                let tx = await mint(token, digest, nonce)
                    .catch((_err) => { console.error(_err) })

                if (tx && tx.hash) {
                    // console.log('TRANSACTION', tx)
                    console.log(`Transaction submitted as [ ${tx.hash} ]`)
                }

                /* Initialize db connection. */
                // const dbSolutions = nano.db.use('minado_solutions')
                const dbSolutions = nano.db.use('minado_solutions_kovan')

                /* Build solution package. */
                const solution = {
                    share,
                    tx,
                    createdAt: moment().valueOf()
                }

                /* Insert into (success) database. */
                result = await dbSolutions.insert(solution)
                    .catch(_error => {
                        console.error('DB ERROR:', _error)
                    })

                // console.log('DB RESULT', result)

                if (tx) {
                    await tx.wait()
                    console.log('Transaction Receipt', tx)
                }
            }
        }
    })

    /* Set ZeroGold address. */
    // FIXME Pull this from `db.0net.io`.
    const zgAddress = '0xf6E9Fc9eB4C20eaE63Cb2d7675F4dD48B008C531' // KOVAN

    let action = 'init'

    const config = require('./config.json')
    const address = config['purse'].address

    let challenge = await getChallenge(zgAddress)
    challenge = challenge.toHexString()

    let target = await getTarget(zgAddress)
    target = target.toHexString()

    let difficulty = '1'

    let pkg = {
        action,
        address,
        challenge,
        target,
        difficulty
    }

    console.log('sending pkg', pkg)

    _conn.write(JSON.stringify(pkg))
}

module.exports = {
    connection,
    error: _errorHandler
}
