"use strict";
// import express from 'express'
//
// console.log(`Running Minado's Infinity Pool Server...`)
//
// const app = express()
// const port = 3030
//
// app.get('/', (req, res) => res.send('Hello Vue!'))
//
// app.listen(port, () => console.log(`Example app listening on port ${port}!`))
exports.__esModule = true;
var App_1 = require("./App");
var port = process.env.PORT || 3000;
App_1["default"].listen(port, function (err) {
    if (err) {
        return console.log(err);
    }
    return console.log("server is listening on " + port);
});
