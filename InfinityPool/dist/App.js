"use strict";
exports.__esModule = true;
var express = require("express");
var moment = require("moment");
// const Web3 = require('web3')
var App = /** @class */ (function () {
    function App() {
        this.express = express();
        this._mountRoutes();
        this._runMintTest();
    }
    App.prototype._mountRoutes = function () {
        var router = express.Router();
        router.get('/', function (req, res) {
            console.log('req.query', req.query);
            res.json({
                message: 'Welcome to Infinity Pool! - ' + moment().unix()
            });
        });
        this.express.use('/', router);
    };
    App.prototype._runMintTest = function () {
        console.log('Running Mint test...');
    };
    return App;
}());
exports["default"] = new App().express;
