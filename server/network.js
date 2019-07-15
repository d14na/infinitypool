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

        /* Initialize contract. */
        const contract = new ethers.Contract(contractAddress, abi, PROVIDER)

        /* Retrieve contract value. */
        let challenge = await contract.getChallenge(_token)
            .catch((_err) => { _reject(_err) })

        console.log('CHALLENGE', challenge, challenge.toString())

        /* Resolve promise. */
        _resolve(challenge)
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

        /* Set contract address. */
        // FIXME Pull this from `db.0net.io`.
        const contractAddress = '0x9fb54e00a1fe2df35f685f46c9c78b7cfcc9c5cb' // KOVAN

        /* Initialize contract. */
        const contract = new ethers.Contract(contractAddress, abi, wallet)

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
    mint
}
