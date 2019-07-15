const ethers = require('ethers')

/* Set provider. */
const PROVIDER = ethers.getDefaultProvider('kovan')

/**
 * Get Challenge (Number)
 */
const getChallenge = function (_token) {
    return new Promise(async function (_resolve, _reject) {
        /* Set abi. */
        const abi = require('../contracts/Minado.json')

        /* Set contract address. */
        // FIXME Pull this from `db.0net.io`.
        const contractAddress = '0x9fb54e00a1fe2df35f685f46c9c78b7cfcc9c5cb' // KOVAN

        /* Set ZeroGold address. */
        // FIXME Pull this from `db.0net.io`.
        const zgAddress = '0xf6E9Fc9eB4C20eaE63Cb2d7675F4dD48B008C531' // KOVAN

        /* Initialize contract. */
        const contract = new ethers.Contract(contractAddress, abi, PROVIDER)

        /* Retrieve contract value. */
        let challenge = await contract.getChallenge(zgAddress)
            .catch((_err) => { reject(_err) })

        console.log('CHALLENGE', challenge, challenge.toString())

        /* Resolve promise. */
        _resolve(challenge)
    })
}

module.exports = {
    getChallenge
}
