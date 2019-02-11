"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : new P(function (resolve) { resolve(result.value); }).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
    return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (_) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
exports.__esModule = true;
var express = require("express");
var moment = require("moment");
// import * as Web3 from 'web3'
var Web3 = require('web3');
var HTTP_PROVIDER = 'https://mainnet.infura.io/v3/97524564d982452caee95b257a54064e';
var App = /** @class */ (function () {
    function App() {
        this.express = express();
        this._mountRoutes();
        this._runMintTest();
        this._runWeb3Test();
        this._runWeb3Test2();
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
    App.prototype._runWeb3Test = function () {
        return __awaiter(this, void 0, void 0, function () {
            var web3, blockNumber;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        console.log('Running Web3 test...');
                        web3 = new Web3(new Web3.providers.HttpProvider(HTTP_PROVIDER));
                        return [4 /*yield*/, web3.eth.getBlockNumber()];
                    case 1:
                        blockNumber = _a.sent();
                        console.log('BLOCK NUMBER', blockNumber);
                        return [2 /*return*/];
                }
            });
        });
    };
    App.prototype._runWeb3Test2 = function () {
        return __awaiter(this, void 0, void 0, function () {
            var from, pk, web3, contractAddress, abi, gasPrice, options, myContract;
            return __generator(this, function (_a) {
                from = '';
                pk = '';
                web3 = new Web3(new Web3.providers.HttpProvider(HTTP_PROVIDER));
                contractAddress = '0xB6eD7644C69416d67B522e20bC294A9a9B405B31';
                abi = require(__dirname + '/../../contracts/_0xBitcoin.json');
                gasPrice = '20000000000' // default gas price in wei, 20 gwei in this case
                ;
                options = { from: from, gasPrice: gasPrice };
                myContract = new web3.eth.Contract(abi, contractAddress, options);
                // console.log('MY CONTRACT', myContract)
                myContract.methods
                    .getChallengeNumber().call({ from: from }, function (_error, _result) {
                    if (_error)
                        return console.error(_error);
                    console.log('RESULT', _result);
                    // let pkg = {
                    //     balance: _result,
                    //     bricks: parseInt(_result / 100000000)
                    // }
                    // res.json(pkg)
                });
                return [2 /*return*/];
            });
        });
    };
    return App;
}());
exports["default"] = new App().express;
