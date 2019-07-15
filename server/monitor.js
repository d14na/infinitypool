let contractEnsName = 'registrar.firefly.eth';

let topic = ethers.utils.id("nameRegistered(bytes32,address,uint256)");

let filter = {
    address: contractEnsName,
    topics: [ topic ]
}

provider.on(filter, (result) => {
    console.log(result);
    // {
    //    blockNumber: 3606106,
    //    blockHash: "0x878aa7059c93239437f66baeec82332dcb2f9288bcdf6eb1ff3ba6998cdf8f69",
    //    transactionIndex: 6,
    //    removed: false,
    //    address: "0x6fC21092DA55B392b045eD78F4732bff3C580e2c",
    //    data: "0x00000000000000000000000006b5955a67d827cdf91823e3bb8f069e6c89c1d6" +
    //            "000000000000000000000000000000000000000000000000016345785d8a0000",
    //    topics: [
    //      "0x179ef3319e6587f6efd3157b34c8b357141528074bcb03f9903589876168fa14",
    //      "0x90a4d0958790016bde1de8375806da3be227ff48e611aefea36303fb86bca5ad"
    //    ],
    //    transactionHash: "0x0d6f43accb067ca8e391666f37f8e8ad75f88ebd8036c9166fd2d0b93b214d2e",
    //    logIndex: 6
    // }
})
