import * as express from 'express'
import * as moment from 'moment'
// const Web3 = require('web3')

class App {
    public express

    constructor () {
        this.express = express()

        this._mountRoutes()
        this._runMintTest()
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
}

export default new App().express
