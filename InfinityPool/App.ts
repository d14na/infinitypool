import * as express from 'express'
import * as moment from 'moment'
// import * as Web3 from 'web3'

// FIXME: `import` not working; or disable warning
const Web3 = require('web3')

/* Initialize constants. */
const HTTP_PROVIDER = 'https://mainnet.infura.io/v3/97524564d982452caee95b257a54064e'

class App {
    public express: any
    public web3: any

    constructor () {
        /* Initialize express. */
        this.express = express()

        /* Initialize web3. */
        this.web3 = new Web3(new Web3.providers.HttpProvider(HTTP_PROVIDER))

        this._mountRoutes()
        this._runMintTest()
        this._runWeb3Test()
    }

    /**
     * Mount Routes
     */
    private _mountRoutes(): void {
        const router = express.Router()

        /* API Root. */
        router.get('/', (req, res) => {
            console.log('req.query', req.query)

            /* Initialize message. */
            const message = 'Welcome to Infinity Pool!'

            /* Initialize system time. */
            const systime = moment().unix()

            /* Return JSON. */
            res.json({
                message,
                systime
            })
        })

        /* Pool Statistics. */
        router.get('/stats', async (req, res) => {
            /* Retrieve challenge number. */
            const challengeNumber = await this._getChallengeNumber()
                .catch(_error => console.error('ERROR: _getChallengeNumber', _error))

            /* Return JSON. */
            res.json({
                challengeNumber
            })
        })

        /* Profile Summary. */
        router.get('/profile/:address', async (req, res) => {
            console.log('req.params', req.params)

            /* Return JSON. */
            res.json({
                message: 'un-implemented'
            })
        })

        /* Use router. */
        this.express.use('/', router)
    }

    private _runMintTest() {
        console.log('Running Mint test...')
    }

    private async _runWeb3Test() {
        console.log('Running Web3 test...')

        const web3 = new Web3(new Web3.providers.HttpProvider(HTTP_PROVIDER))

        const blockNumber = await web3.eth.getBlockNumber()

        console.log('BLOCK NUMBER', blockNumber)
    }

    /**
     * Get Challenge Number
     */
    private _getChallengeNumber() {
        /* Localize this. */
        const self = this

        /* Return a promise. */
        return new Promise(function (_resolve, _reject) {
            /* Initilize address. */
            const contractAddress = '0xB6eD7644C69416d67B522e20bC294A9a9B405B31'

            /* Initilize abi. */
            const abi = require(__dirname + '/../abi/_0xBitcoin.json')

            /* Initialize options. */
            const options = {}

            /* Initialize contract. */
            const contract = self.web3.eth.Contract(
                abi, contractAddress, options)

            /* Initialize contract handler. */
            const _handler = function (_error: any, _result: any) {
                if (_error) {
                    /* Return with rejected promise. */
                    return _reject(_error)
                }

                /* Resolve promise. */
                _resolve(_result)
            }

            /* Call contract. */
            contract.methods.getChallengeNumber().call(options, _handler)
        })
    }

}

export default new App().express
