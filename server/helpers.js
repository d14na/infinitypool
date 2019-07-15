/**
 * Broadcast (to all connections)
 */
const broadcast = function (_pkg, _pool, _exclude = null) {
    Object.keys(_pool).forEach(function(_k, _i) {
        /* Set connection (from pool). */
        let conn = _pool[_k]

        /* Filter out a connection id. */
        // NOTE: Used primarily to exclude message sender.
        if (_exclude !== conn.id) {
            /* Send "stringified" package. */
            conn.write(JSON.stringify(_pkg))
        }
    })
}

/**
 * Submit Share
 */
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

module.exports = {
    broadcast
}
