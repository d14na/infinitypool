const ethers = require('ethers')

/* Set provider. */
const PROVIDER = ethers.getDefaultProvider('kovan')

/* Set contract address. */
// FIXME Pull this from `db.0net.io`.
const CONTRACT_ADDRESS = '0xc03e3031359dfb1b5a5f2e1e9ae65feb0e114af4' // Minado.sol

/**
 * Get Challenge (Number)
 */
const getChallenge = function (_token) {
    return new Promise(async function (_resolve, _reject) {
        /* Set abi. */
        const abi = require('../contracts/Minado.json')

        /* Initialize contract. */
        const contract = new ethers.Contract(CONTRACT_ADDRESS, abi, PROVIDER)

        /* Retrieve contract value. */
        let challenge = await contract.getChallenge(_token)
            .catch((_err) => { _reject(_err) })

        /* Resolve promise. */
        _resolve(challenge)
    })
}

/**
 * Get Target (Number)
 */
const getTarget = function (_token) {
    return new Promise(async function (_resolve, _reject) {
        /* Set abi. */
        const abi = require('../contracts/Minado.json')

        /* Initialize contract. */
        const contract = new ethers.Contract(CONTRACT_ADDRESS, abi, PROVIDER)

        /* Retrieve contract value. */
        let target = await contract.getTarget(_token)
            .catch((_err) => { _reject(_err) })

        /* Resolve promise. */
        _resolve(target)
    })
}

/**
 * Mint (Token)
 */
const mint = function (_token, _digest, _nonce) {
    return new Promise(async function (_resolve, _reject) {
        const config = require('./config.json')
        const privateKey = config['purse'].privateKey
        const provider = ethers.getDefaultProvider('kovan')
        const wallet = new ethers.Wallet(privateKey, provider)

        /* Set abi. */
        const abi = require('../contracts/Minado.json')

        /* Initialize contract. */
        const contract = new ethers.Contract(CONTRACT_ADDRESS, abi, wallet)

        /* Retrieve contract value. */
        let tx = await contract.mint(_token, _digest, _nonce)
            .catch((_err) => { _reject(_err) })

        // console.log(tx.hash)

        /* Resolve promise. */
        _resolve(tx)
    })
}

module.exports = {
    getChallenge,
    getTarget,
    mint
}
