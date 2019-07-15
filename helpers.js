/**
 * Broadcast (to all connections)
 */
const broadcast = function (_pkg, _pool, _exclude = null) {
    Object.keys(_pool).forEach(function(_k, _i) {
        /* Set connection (from pool). */
        let conn = _pool[_k]

        /* Filter out a connection id. */
        // NOTE: Used primarily to exclude message sender.
        if (_exclude !== conn.id) {
            /* Send "stringified" package. */
            conn.write(JSON.stringify(_pkg))
        }
    })
}

module.exports = {
    broadcast
}
