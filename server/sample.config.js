const config = {
    minimumShareDifficulty : 65536,
    solutionGasPriceWei    : 10,
    transferGasPriceWei    : 6,
    poolTokenFee           : 3,
    minBalanceForTransfer  : 300000000,
    populationLimit        : 100,
    // web3provider           : 'https://mainnet.infura.io/v3/97524564d982452caee95b257a54064e',
    purse: {
        address: '0x9402ceF956C1FbBf302738c6589680AFebf101f6',
        privateKey: '0x00000000000000000000000000000000'
    }
}

exports.config = config
