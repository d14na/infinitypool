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
var Nano = require("nano");
// FIXME: `import` not working; or disable warning
var Web3 = require('web3');
/* Initialize constants. */
var HTTP_PROVIDER = 'https://mainnet.infura.io/v3/97524564d982452caee95b257a54064e';
var App = /** @class */ (function () {
    function App() {
        /* Initialize express. */
        this.express = express();
        /* Initialize web3. */
        this.web3 = new Web3(new Web3.providers.HttpProvider(HTTP_PROVIDER));
        /* Initialize Nano connection to localhost CouchDb. */
        this.nano = Nano('http://127.0.0.1:5984');
        this._mountRoutes();
        this._runMintTest();
        this._runWeb3Test();
        this._runDbTest();
    }
    /**
     * Mount Routes
     */
    App.prototype._mountRoutes = function () {
        var _this = this;
        var router = express.Router();
        /* API Root. */
        router.get('/', function (req, res) {
            console.log('req.query', req.query);
            /* Initialize message. */
            var message = 'Welcome to Infinity Pool!';
            /* Initialize system time. */
            var systime = moment().unix();
            /* Return JSON. */
            res.json({
                message: message,
                systime: systime
            });
        });
        /* Pool Statistics. */
        router.get('/stats', function (req, res) { return __awaiter(_this, void 0, void 0, function () {
            var challengeNumber;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0: return [4 /*yield*/, this._getChallengeNumber()["catch"](function (_error) { return console.error('ERROR: _getChallengeNumber', _error); })
                        /* Return JSON. */
                    ];
                    case 1:
                        challengeNumber = _a.sent();
                        /* Return JSON. */
                        res.json({
                            challengeNumber: challengeNumber
                        });
                        return [2 /*return*/];
                }
            });
        }); });
        /* Profile Summary. */
        router.get('/profile/:address', function (req, res) { return __awaiter(_this, void 0, void 0, function () {
            return __generator(this, function (_a) {
                console.log('req.params', req.params);
                /* Return JSON. */
                res.json({
                    message: 'un-implemented'
                });
                return [2 /*return*/];
            });
        }); });
        /* Use router. */
        this.express.use('/', router);
    };
    App.prototype._runMintTest = function () {
        console.log('Running Mint test...');
    };
    App.prototype._runDbTest = function () {
        return __awaiter(this, void 0, void 0, function () {
            var db, results;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        console.log('Running Db test...');
                        db = this.nano.db.use('profiles');
                        return [4 /*yield*/, db.get('rabbit')];
                    case 1:
                        results = _a.sent();
                        console.log('RESULTS', results);
                        db.list().then(function (body) {
                            body.rows.forEach(function (doc) {
                                console.log(doc);
                            });
                        });
                        return [2 /*return*/];
                }
            });
        });
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
    /**
     * Get Challenge Number
     */
    App.prototype._getChallengeNumber = function () {
        /* Localize this. */
        var self = this;
        /* Return a promise. */
        return new Promise(function (_resolve, _reject) {
            /* Initilize address. */
            var contractAddress = '0xB6eD7644C69416d67B522e20bC294A9a9B405B31';
            /* Initilize abi. */
            var abi = require(__dirname + '/../abi/_0xBitcoin.json');
            /* Initialize options. */
            var options = {};
            /* Initialize contract. */
            var contract = self.web3.eth.Contract(abi, contractAddress, options);
            /* Initialize contract handler. */
            var _handler = function (_error, _result) {
                if (_error) {
                    /* Return with rejected promise. */
                    return _reject(_error);
                }
                /* Resolve promise. */
                _resolve(_result);
            };
            /* Call contract. */
            contract.methods.getChallengeNumber().call(options, _handler);
        });
    };
    return App;
}());
exports["default"] = new App().express;
