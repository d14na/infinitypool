import * as express from 'express'
import * as moment from 'moment'
// import * as Web3 from 'web3'

const Web3 = require('web3')

const HTTP_PROVIDER = 'https://mainnet.infura.io/v3/97524564d982452caee95b257a54064e'

class App {
    public express: any

    constructor () {
        this.express = express()

        this._mountRoutes()
        this._runMintTest()
        this._runWeb3Test()
        this._runWeb3Test2()
    }

    private _mountRoutes(): void {
        const router = express.Router()

        router.get('/', (req, res) => {
            console.log('req.query', req.query)

            res.json({
                message: 'Welcome to Infinity Pool! - ' + moment().unix()
            })
        })

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

    private async _runWeb3Test2() {
        /* Initilize address. */
        const from = ''
        // const from = CONFIG['bots']['auntieAlice'].address

        /* Initilize private key. */
        const pk = ''
        // const pk = CONFIG['bots']['auntieAlice'].privateKey

        const web3 = new Web3(new Web3.providers.HttpProvider(HTTP_PROVIDER))

        /* Initialize new account from private key. */
        // const acct = web3.eth.accounts.privateKeyToAccount(pk)

        /* Initilize address. */
        const contractAddress = '0xB6eD7644C69416d67B522e20bC294A9a9B405B31'

        /* Initilize abi. */
        const abi = require(__dirname + '/../../contracts/_0xBitcoin.json')

        /* Initialize gas price. */
        const gasPrice = '20000000000' // default gas price in wei, 20 gwei in this case

        /* Initialize options. */
        const options = { from, gasPrice }

        const myContract = new web3.eth.Contract(
            abi, contractAddress, options)

        // console.log('MY CONTRACT', myContract)

        myContract.methods
            .getChallengeNumber().call({ from },
        function (_error: any, _result: any) {
            if (_error) return console.error(_error)

            console.log('RESULT', _result)

            // let pkg = {
            //     balance: _result,
            //     bricks: parseInt(_result / 100000000)
            // }

            // res.json(pkg)
        })
    }

}

export default new App().express
