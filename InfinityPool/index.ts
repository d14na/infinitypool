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

import pool from './App'

const port = process.env.PORT || 3000

pool.listen(port, (err: any) => {
    if (err) {
        return console.log(err)
    }

    return console.log(`server is listening on ${port}`)
})
