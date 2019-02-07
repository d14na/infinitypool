pragma solidity ^0.4.25;

/*******************************************************************************
 *
 * Copyright (c) 2018 Decentralization Authority MDAO.
 * Released under the MIT License.
 *
 * Minado - Crypto Token Mining & Forging Community
 *
 *          Mineable (ERC-918) Tokens
 *          -------------------------
 *
 *          Minado has been optimized for mining ERC918-compatible tokens via
 *          the InfinityPool; a public storage of mineable ERC-20 tokens.
 *
 *          Learn more below:
 *
 *          Official : https://minado.network
 *          Ethereum : https://eips.ethereum.org/EIPS/eip-918
 *          Github   : https://github.com/ethereum/EIPs/pull/918
 *          Reddit   : https://www.reddit.com/r/Tokenmining
 *
 *          InfinityStone Forging
 *          ---------------------
 *
 *          Minado makes it simple and fun for STAEKers to manage their
 *          InfinityStone forging activities in the InfinityWell.
 *
 *          0STONEs can be used to claim instant rewards towards ANY ERC-20 and/or
 *          ERC-721 token(s) currently owned by the InfinityWell.
 *
 *          Learn more below:
 *
 *          Official : https://infinitystone.xyz
 *          Reddit   : https://www.reddit.com/r/InfinityStone
 *
 * Version 19.2.5
 *
 * Web    : https://d14na.org
 * Email  : support@d14na.org
 */


/*******************************************************************************
 *
 * SafeMath
 */
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


/*******************************************************************************
 *
 * Owned contract
 */
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);

        emit OwnershipTransferred(owner, newOwner);

        owner = newOwner;

        newOwner = address(0);
    }
}


/*******************************************************************************
 *
 * Zer0netDb Interface
 */
contract Zer0netDbInterface {
    /* Interface getters. */
    function getAddress(bytes32 _key) external view returns (address);
    function getBool(bytes32 _key)    external view returns (bool);
    function getBytes(bytes32 _key)   external view returns (bytes);
    function getInt(bytes32 _key)     external view returns (int);
    function getString(bytes32 _key)  external view returns (string);
    function getUint(bytes32 _key)    external view returns (uint);

    /* Interface setters. */
    function setAddress(bytes32 _key, address _value) external;
    function setBool(bytes32 _key, bool _value) external;
    function setBytes(bytes32 _key, bytes _value) external;
    function setInt(bytes32 _key, int _value) external;
    function setString(bytes32 _key, string _value) external;
    function setUint(bytes32 _key, uint _value) external;

    /* Interface deletes. */
    function deleteAddress(bytes32 _key) external;
    function deleteBool(bytes32 _key) external;
    function deleteBytes(bytes32 _key) external;
    function deleteInt(bytes32 _key) external;
    function deleteString(bytes32 _key) external;
    function deleteUint(bytes32 _key) external;
}


/*******************************************************************************
 *
 * ERC Token Standard #20 Interface
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
 */
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


/*******************************************************************************
 *
 * InfinityPool Interface
 */
contract InfinityPoolInterface {
    function transfer(address _token, address _to, uint _tokens) external;
}


/*******************************************************************************
 *
 * InfinityWell Interface
 */
contract InfinityWellInterface {
    function forgeStones(address _owner, uint _tokens) external;
    function destroyStones(address _owner, uint _tokens) external;
    function transferERC20(address _token, address _to, uint _tokens) external;
    function transferERC721(address _token, address _to, uint256 _tokenId) external;
}


/*******************************************************************************
 *
 * @notice Minado - Merged Token Mining Contract
 *
 * @dev This is a multi-token mining contract, which manages the proof-of-work
 *      verifications before authorizing the movement of tokens from the
 *      InfinityPool.
 */
contract Minado is Owned {
    using SafeMath for uint;

    /* Initialize version name. */
    string public version;

    /* Initialize predecessor contract. */
    address public predecessor;

    /* Initialize successor contract. */
    address public successor;

    /* Initialize Zer0net Db contract. */
    Zer0netDbInterface public zer0netDb;

    /* Initialize ZeroGold contract. */
    ERC20Interface public zeroGold;

    /* Initialize InfinityWell contract. */
    InfinityWellInterface public infinityWell;

    /**
     * Blocks Per Re-adjustment
     *
     * By default, we automatically trigger a difficulty adjustment
     * after 144 blocks (aporox 24hrs). Frequent adjustments are
     * especially important with low-liquidity tokens that are more
     * susceptible to mining manipulation.
     *
     * For additional control, token owners retain the ability to trigger
     * a difficulty re-calculation at any time.
     *
     * NOTE: Bitcoin re-adjusts its difficulty every 2016 blocks,
     *       which occurs approx. every 14 days.
     */
    uint private _INITIAL_BLOCKS_PER_ADJUSTMENT = 144; // approx. 24hrs

    /**
     * Large Target
     *
     * A big number used for difficulty targeting.
     *
     * NOTE: Bitcoin uses `2**224`.
     */
    uint private _LARGE_TARGET = 2**234;

    /**
     * Small Targets
     *
     * Two small numbers used for difficulty targeting.
     *
     * NOTE: GPU target is 65,536 and CPU target is 64.
     */
    uint private _SMALL_GPU_TARGET = 2**16; // GPU
    uint private _SMALL_CPU_TARGET = 2**6; // CPU

    /**
     * Block Per Re-adjustment
     *
     * NOTE: Ethereum blocks take approx 15 seconds each.
     *       1,000 blocks takes approx 4 hours.
     */
    uint private _BLOCKS_PER_EPOCH = 1000;

    /**
     * Set basis-point multiplier.
     *
     * NOTE: Used for (integer-based) fractional calculations.
     */
    uint private _BP_MUL = 10000;

    /**
     * Token Decimals (for InfinityStone)
     */
    uint private _TOKEN_DECIMALS = 18;

    event Claim(
        address owner,
        address[] tokens,
        uint[] quantities
    );

    event Excavate(
        address indexed token,
        address indexed miner,
        uint mintAmount,
        uint epochCount,
        bytes32 newChallengeNumber
    );

    event Mint(
        address indexed from,
        uint reward_amount,
        uint epochCount,
        bytes32 newChallengeNumber
    );

    event ReCalculate(
        address token,
        uint newDifficulty
    );

    /* Constructor. */
    constructor() public {
        /* Initialize Zer0netDb (eternal) storage database contract. */
        // NOTE We hard-code the address here, since it should never change.
        zer0netDb = Zer0netDbInterface(0xE865Fe1A1A3b342bF0E2fcB11fF4E3BCe58263af);

        /* Initialize the ZeroGold contract. */
        // NOTE We hard-code the address here, since it should never change.
        // zeroGold = ERC20Interface(0x6ef5bca539A4A01157af842B4823F54F9f7E9968);
        zeroGold = ERC20Interface(0x079F89645eD85b85a475BF2bdc82c82f327f2932); // ROPSTEN
    }

    /**
     * @dev Only allow access to an authorized Zer0net administrator.
     */
    modifier onlyAuthBy0Admin() {
        /* Verify write access is only permitted to authorized accounts. */
        require(zer0netDb.getBool(keccak256(
            abi.encodePacked(msg.sender, '.has.auth.for.minado'))) == true);

        _;      // function code is inserted here
    }

    /**
     * @dev Only allow access to "registered" token owner.
     */
    modifier onlyTokenOwner(address _token) {
        /* Set hash. */
        bytes32 hash = keccak256(
            abi.encodePacked('infinitypool.', _token, '.owner'));

        /* Retrieve value from Zer0net Db. */
        address tokenOwner = zer0netDb.getAddress(hash);

        /* Validate token owner. */
        require(msg.sender == tokenOwner);

        _;      // function code is inserted here
    }

    /**
     * @dev Only allow access to "registered" token owner.
     */
    modifier liveStaek() {
        /* Validate live staek. */
        require(getTTL() > block.number - 1);

        _;      // function code is inserted here
    }

    /***************************************************************************
     *
     * ACTIONS
     *
     */

    /**
     * Add NEW Mineable Token
     *
     * Handles the responsibility of storing the new token's
     * parameters in the Eternal database.
     *
     * NOTE: Eternal storage allows for quick and easy future upgrades.
     */
    function addMineableToken(
        address _token
    ) external onlyAuthBy0Admin returns (bool success) {

        // TODO Initialize all parameters.

        /* Set hash. */
        bytes32 adjustmentHash = keccak256(
            abi.encodePacked('infinitypool.', _token, '.blocks.per.adjustment'));

        /* Set value in Zer0net Db. */
        zer0netDb.setUint(adjustmentHash, _INITIAL_BLOCKS_PER_ADJUSTMENT);

        // TODO Run all initial procedures.
    }

    /**
     * Staek Of (Owner)
     *
     * Current balance of ZeroGold staeked to this contract.
     */
    function staekOf(address _owner) public view returns (uint staek) {
        /* Set hash. */
        bytes32 hash = keccak256(
            abi.encodePacked('infinitywell.', _owner, '.staek'));

        /* Retrieve value from Zer0net Db. */
        staek = zer0netDb.getUint(hash);
    }

    /**
     * Claim Gifts
     *
     * NOTE: Required pre-allowance/approval is required in order
     *       to successfully complete the transfer.
     */
    function claimGifts(
        address _token,
        uint _tokens,
        bytes _data
    ) external returns (bool success) {
        return _claimGifts(_token, msg.sender, _tokens, _data);
    }

    /**
     * Receive Approval
     *
     * Will typically be called from `approveAndCall`.
     *
     * NOTE: In this case, we have no use for data, as
     *       deposits are credited anonymously and only
     *       accessible to the token owner(s).
     */
    function receiveApproval(
        address _from,
        uint _tokens,
        address _token,
        bytes _data
    ) public returns (bool success) {
        return _claimGifts(_token, _from, _tokens, _data);
    }

    /**
     * Claim Gifts (ERC Token Rewards)
     *
     * @notice InfinityStone HODLers can claim their ERC token rewards.
     *
     * @dev Up to 5% for ERC-20 tokens; and a single ERC-721 collectible.
     */
    function _claimGifts(
        address _token,
        address _from,
        uint _tokens,
        bytes _data
    ) private returns (bool success) {

        // FIXME Perform random selection
        address erc20Token = 0x0;
        uint erc20TokenAmount = 0;

        /* Transfer the ERC-20 token(s) to owner. */
        InfinityWellInterface(erc20Token).transferERC20(
            erc20Token, _from, erc20TokenAmount);

        // FIXME Perform random selection
        address erc721token = 0x0;
        uint256 erc721TokenId = 0;

        /* Transfer ERC-721 token to owner. */
        InfinityWellInterface(erc721token).transferERC721(
            erc721token, _from, erc721TokenId);

        /* Return success. */
        return true;
    }

    /**
     * Forge NEW InfinityStone(s)
     *
     * NOTE: restricted to a MAX of once per 1000 blocks.
     */
    function forgeStones() external liveStaek returns (uint tokens) {
        /* Retrieve forge share. */
        tokens = getOwnerForgeShare(msg.sender);

        /* Set hash. */
        bytes32 hash = keccak256(
            abi.encodePacked('infinitywell.', msg.sender, '.has.forged.', getEpoch()));

        /* Set value in Zer0net Db. */
        zer0netDb.setBool(hash, true);

        /* Forge stones. */
        infinityWell.forgeStones(msg.sender, tokens);
    }

    /**
     * Destroy InfinityStone(s)
     *
     * NOTE: restricted to a MAX of once per 1000 blocks.
     */
    function _destroyStones(
        address _owner,
        uint _tokens
    ) private liveStaek returns (bool success) {
        /* Forge stones. */
        infinityWell.destroyStones(_owner, _tokens);
    }

    /**
     * Re-calculate Difficulty
     *
     * Token owner(s) can "manually" trigger the re-calculation of their token,
     * based on the parameters that have been set.
     *
     * NOTE: This will help deter malicious miners from gaming the difficulty
     *       parameter, to the detriment of the token's community.
     */
    function reCalculateDifficulty(
        address _token
    ) external onlyTokenOwner(_token) returns (bool success) {
        /* Re-calculate difficulty. */
        _reAdjustDifficulty(_token);
    }

    /**
     * Re-adjust Difficulty
     *
     * Re-adjust the target by 5 percent.
     * (source: https://en.bitcoin.it/wiki/Difficulty#What_is_the_formula_for_difficulty.3F)
     *
     * NOTE: Assume 240 ethereum blocks per hour (approx. 15/sec)
     *
     * NOTE: As of 2017 the bitcoin difficulty was up to 17 zeroes,
     *       it was only 8 in the early days.
     */
    function _reAdjustDifficulty(address _token) private {
        /* Set hash. */
        bytes32 lastAdjustmentHash = keccak256(
            abi.encodePacked('infinitypool.', _token, '.last.adjustment'));

        /* Retrieve value from Zer0net Db. */
        uint lastAdjustment = zer0netDb.getUint(lastAdjustmentHash);

        /* Retrieve value from Zer0net Db. */
        uint blocksSinceLastAdjustment = block.number - lastAdjustment;

        /**
         * Epoch Mined
         *
         * NOTE: We want miners to spend 10 minutes to mine each 'block'.
         *       (about 40 Ethereum blocks for every 1 Bitcoin block)
         */
        uint ethBlockPerBtc = 40;

        /* Set hash. */
        bytes32 adjustmentHash = keccak256(
            abi.encodePacked('infinitypool.', _token, '.blocks.per.adjustment'));

        /* Retrieve value from Zer0net Db. */
        uint blocksPerAdjustment = zer0netDb.getUint(adjustmentHash);

        /**
         * Expected ETH Blocks (Per Adjustment Period)
         *
         * NOTE: To match Bitcoin, this should be 40 times slower than Ethereum.
         *       eg. 144 x 40 = 5,760
         */
        uint expectedBlocks = blocksPerAdjustment * ethBlockPerBtc;

        /* Retrieve mining target. */
        uint miningTarget = getMiningTarget(_token);

        // if there were less eth blocks passed in time than expected
        // NOTE: Miners are excavating too quickly.
        if (blocksSinceLastAdjustment < expectedBlocks) {
            // NOTE: This number will be an integer greater than 100.
            uint excess_block_pct = expectedBlocks.mul(100)
                .div(blocksSinceLastAdjustment);

            /**
             * Excess Block Percentage Extra
             *
             * For example:
             *     If there were 5% more blocks mined than expected, then this is 5.
             *     If there were 100% more blocks mined than expected, then this is 100.
             */
            uint excess_block_pct_extra = excess_block_pct.sub(100);

            /* Set a maximum difficulty change of 100%. */
            // NOTE: By default, this is within a 24hr period.
            if (excess_block_pct_extra > 100) {
                excess_block_pct_extra = 100;
            }

            /**
             * Reset the Mining Target
             *
             * Calculate the difficulty difference, then SUBTRACT
             * that value from the current difficulty.
             */
            miningTarget = miningTarget.sub(
                /* Calculate difficulty difference. */
                miningTarget
                    .mul(excess_block_pct_extra)
                    .div(100)
            );
        } else {
            // NOTE: This number will be an integer greater than 100.
            uint shortage_block_pct = (blocksSinceLastAdjustment.mul(100))
                .div(expectedBlocks);

            /**
             * Extended Epoch Mining Percentage Extra
             *
             * For example:
             *     If it took 5% longer to mine than expected, then this is 5.
             *     If it took 25% longer to mine than expected, then this is 25.
             */
            uint ext_epoch_mining_pct_extra = shortage_block_pct.sub(100);

            /**
             * Reset the Mining Target
             *
             * Calculate the difficulty difference, then ADD
             * that value to the current difficulty.
             */
            miningTarget = miningTarget.add(
                miningTarget
                    .mul(ext_epoch_mining_pct_extra)
                    .div(100)
            );
        }

        /* Set current adjustment time in Zer0net Db. */
        zer0netDb.setUint(lastAdjustmentHash, block.number);

        /* Validate TOO SMALL mining target. */
        // NOTE: This is very difficult to guess.
        if (miningTarget < _SMALL_CPU_TARGET) { //
            miningTarget = _SMALL_CPU_TARGET;
        }

        /* Validate TOO LARGE mining target. */
        // NOTE: This is very easy to guess.
        if (miningTarget > _LARGE_TARGET) {
            miningTarget = _LARGE_TARGET;
        }

        /* Set mining target in Zer0net Db. */
        _setMiningTarget(_token, block.number);
    }

    /**
     * Begin NEW Mining Epoch
     *
     * A new 'block' to be mined.
     */
    function _beginMiningEpoch(
        address _token
    ) private returns (bool success) {
        /* Set hash. */
        bytes32 epochHash = keccak256(
            abi.encodePacked('infinitypool.', _token, '.epoch'));

        /* Retrieve value from Zer0net Db. */
        uint epoch = zer0netDb.getUint(epochHash);

        /* Set value in Zer0net Db. */
        zer0netDb.setUint(epochHash, epoch.add(1));

        /* Set hash. */
        bytes32 adjustmentHash = keccak256(
            abi.encodePacked('infinitypool.', _token, '.blocks.per.adjustment'));

        /* Retrieve value from Zer0net Db. */
        uint blocksPerAdjustment = zer0netDb.getUint(adjustmentHash);

        /**
         * Difficulty Re-adjustment
         *
         * Every so often, re-adjust the difficulty to the maintain the
         * expected minting distribution as desired by the token owner(s).
         */
        if (epoch % blocksPerAdjustment == 0) {
            _reAdjustDifficulty(_token);
        }

        /**
         * Set Challenge Number
         *
         * This is the hash of the last mined block on the blockchain.
         *
         * We make the latest ethereum block hash a part of the next challenge
         * for PoW to prevent pre-mining future blocks.
         *
         * NOTE: Do this last since this is a protection mechanism
         *       in the mint() function.
         */
        _setMiningChallenge(_token, blockhash(block.number - 1));

        /* Return success. */
        return true;
    }

    // help debug mining software
    function checkMintSolution(
        uint nonce,
        bytes32 challenge_digest,
        bytes32 challenge_number,
        uint testTarget
    ) external view returns (bool success) {
        bytes32 digest = keccak256(
            abi.encodePacked(challenge_number, msg.sender, nonce));

        if(uint(digest) > testTarget) revert();

        return (digest == challenge_digest);
    }

    /**
     * Mint (Mineable) Token
     */
    function mint(
        address _token,
        uint _nonce,
        bytes32 _challengeDigest
    ) external returns (bool success) {
        /* Retrieve challenge number. */
        bytes32 challengeNumber = getChallengeNumber(_token);

        /* Retrieve mining target. */
        uint miningTarget = getMiningTarget(_token);

        /**
         * Challenge Digest
         *
         * NOTE: The PoW must contain work that includes a recent ethereum
         * block hash (challenge number) and the msg.sender's address
         * to prevent MITM attacks.
         */
        bytes32 digest = keccak256(
            abi.encodePacked(challengeNumber, msg.sender, _nonce));

        // the challenge digest must match the expected
        require(digest == _challengeDigest,
            'Challenge digest is incorrect!');

        /* Validate the digest. */
        require(uint(digest) <= miningTarget,
            'The digest must be smaller than the target.');

        /**
         * Solution Validation
         *
         * Only allow one minting for each challenge.
         */

        /* Set hash. */
        bytes32 solutionHash = keccak256(
            abi.encodePacked(
                'infinitypool.',
                _token,
                '.solution.for.',
                challengeNumber
            ));

        /* Retrieve value from Zer0net Db. */
        bytes32 solution = _bytesToBytes32(
            zer0netDb.getBytes(solutionHash));

        /* Validate UNSOLVED solution. */
        // NOTE: Prevent the same answer from awarding twice.
        require(solution == 0x0,
            'This solution has already been mined.');

        /* Set value in Zer0net Db. */
        zer0netDb.setBytes(solutionHash, _bytes32ToBytes(digest));

        /* Retrieve mint amount. */
        uint mintAmount = getMintAmount(_token);

        /* Transfer tokens from InfinityPool to owner. */
        InfinityPoolInterface(getInfinityPool())
            .transfer(_token, msg.sender, mintAmount);

        // set readonly diagnostics data
        // lastMintTo = msg.sender;
        // lastMintAmount = mintAmount;
        // lastMintEthBlockNumber = block.number;

        /* Begin a new mining epoch. */
         _beginMiningEpoch(_token);

        /* Broadcast event. */
        emit Mint(
            msg.sender,
            mintAmount,
            getEpoch(),
            challengeNumber
        );

        /* Return success. */
        return true;
    }

    /**
     * Increase Staek
     */
    function _increaseStaek(
        address _owner,
        uint _tokens
    ) private returns (uint staek) {
        /* Set hash. */
        bytes32 hash = keccak256(
            abi.encodePacked('infinitywell.', _owner, '.staek'));

        /* Retrieve value from Zer0net Db. */
        staek = zer0netDb.getUint(hash);

        /* Re-calculate staek. */
        staek = staek.add(_tokens);

        /* Set value to Zer0net Db. */
        zer0netDb.setUint(hash, staek);
    }

    /**
     * Decrease Staek
     */
    function _descreaseStaek(
        address _owner,
        uint _tokens
    ) private returns (uint staek) {
        /* Set hash. */
        bytes32 hash = keccak256(
            abi.encodePacked('infinitywell.', _owner, '.staek'));

        /* Retrieve value from Zer0net Db. */
        staek = zer0netDb.getUint(hash);

        /* Re-calculate staek. */
        staek = staek.sub(_tokens);

        /* Set value to Zer0net Db. */
        zer0netDb.setUint(hash, staek);
    }

    /***************************************************************************
     *
     * GETTERS
     *
     */

    function getInfinityPool() public view returns (address infinityPool) {
        /* Set hash. */
        bytes32 poolHash = keccak256('infinitypool');

        /* Retrieve value from Zer0net Db. */
        infinityPool = zer0netDb.getAddress(poolHash);
    }

    /**
     * Get Owner (Current) Forge Share
     */
    function getOwnerForgeShare(
        address _owner
    ) public returns (uint share) {
        /* Set hash. */
        bytes32 hasForgedHash = keccak256(
            abi.encodePacked('infinitywell.', _owner, '.has.forged.', getEpoch()));

        /* Validate forging ability. */
        if (zer0netDb.getBool(hasForgedHash) == true) {
            return 0;
        }

        /* Retrieve owner staek. */
        uint ownerStaek = staekOf(_owner);

        /* Set hash. */
        bytes32 staekHash = keccak256(
            abi.encodePacked('infinitywell.', _owner, '.total.staek'));

        /* Retrieve value from Zer0net Db. */
        uint totalStaek = zer0netDb.getUint(staekHash);

        /* Calculate owner rate. */
        // NOTE: basis-point multiplier, 10,000 == 100.00%
        uint ownerRate = ownerStaek.mul(_BP_MUL).div(totalStaek);

        /* Calculate owner (basis) points. */
        // NOTE: basis-point multiplier, 1 == 10,000
        uint ownerPoints = (1 * 10**_TOKEN_DECIMALS) * ownerRate;

        /* Calculate owner share. */
        share = ownerPoints.div(_BP_MUL);
    }

    /**
     * Get Time-To-Live
     *
     * Block number to re-enable owner's access to execute on-chain,
     * staek'd Minado commands.
     */
    function getTTL() public returns (uint ttl) {
        /* Set hash. */
        bytes32 hash = keccak256(
            abi.encodePacked('infinitywell.', msg.sender, '.ttl'));

        /* Retrieve value from Zer0net Db. */
        ttl = zer0netDb.getUint(hash);
    }

    /**
     * Get Epoch (Number)
     *
     * Returns the current epoch (forging cycle); used primarily to
     * manage claims from the InfinityWell.
     *
     * Starting Blocks
     * ---------------
     *
     * First blocks honoring the start of Miss Piggy's celebration year:
     *     - Mainnet: 7,175,716
     *     - Ropsten: 4,956,268
     */
    function getEpoch() public returns (uint epoch) {
        /* Initialize starting block. */
        // uint startingBlock = 7175716; // MAINNET
        uint startingBlock = 4956268; // ROPSTEN

        /* Calculate number of elapsed blocks. */
        uint blocksElapsed = block.number.sub(startingBlock);

        /* Calculate current epoch. */
        epoch = uint(blocksElapsed.div(_BLOCKS_PER_EPOCH));
    }

    /**
     * Get Challenge Number
     *
     * This is a recent ethereum block hash, used to prevent
     * pre-mining future blocks.
     */
    function getChallengeNumber(
        address _token
    ) public view returns (bytes32 challengeNumber) {
        /* Return value from Zer0net Db. */
        return _bytesToBytes32(zer0netDb.getBytes(
            keccak256(abi.encodePacked(
                'infinitypool.', _token, '.challenge.number'))));
    }

    /**
     * Get Mint Amount
     *
     * Calculate the current mint value.
     */
    function getMintAmount(
        address _token
    ) public view returns (uint mintTotal) {
        /* Initialize mint total. */
        mintTotal = 0;

        /* Retrieve InfinityPool token balance. */
        uint infinityBalance = ERC20Interface(_token)
            .balanceOf(getInfinityPool());

        /* Set hash. */
        bytes32 fixedHash = keccak256(
            abi.encodePacked('infinitypool.', _token, '.mint.fixed'));

        /* Return value from Zer0net Db. */
        uint dbMintFixed = zer0netDb.getUint(fixedHash);

        /* Validate mint amount (does NOT exceed balance). */
        if (dbMintFixed > infinityBalance) {
            /* Set mint total to MAX balance. */
            mintTotal = infinityBalance;
        } else {
            /* Set mint total to fixed amount. */
            mintTotal = dbMintFixed;
        }

        /* Set hash. */
        bytes32 pctHash = keccak256(
            abi.encodePacked('infinitypool.', _token, '.mint.pct'));

        /* Return value from Zer0net Db. */
        uint dbMintPct = zer0netDb.getUint(pctHash);

        /* Calculate dynamic mint amount. */
        uint dynamicMintAmount = infinityBalance
            .mul(100)
            .div(dbMintPct);

        /* Validate mint amount (does NOT exceed balance). */
        if ((mintTotal + dynamicMintAmount) > infinityBalance) {
            mintTotal = infinityBalance;
        }
    }

    /**
     * Get Mining Difficulty
     *
     * The number of zeroes the digest of the PoW solution requires.
     * (auto adjusts)
     */
     function getMiningDifficulty(
         address _token
    ) public view returns (uint difficulty) {
        /* Retrieve mining target. */
        uint miningTarget = getMiningTarget(_token);

        /* Return difficulty. */
        return _LARGE_TARGET.div(miningTarget);
    }

    function getMiningTarget(
        address _token
    ) public constant returns (uint miningTarget) {
        /* Set hash. */
        bytes32 hash = keccak256(
            abi.encodePacked('infinitypool.', _token, '.mining.target'));

        /* Return value from Zer0net Db. */
        miningTarget = zer0netDb.getUint(hash);
   }

    /**
     * Get Mint Digest
     *
     * Help debug mining software.
     */
    function getMintDigest(
        uint _nonce,
        bytes32 _challengeNumber
    ) external view returns (bytes32 digest) {
        digest = keccak256(abi.encodePacked(
            _challengeNumber,
            msg.sender,
            _nonce
        ));
    }

    /***************************************************************************
     *
     * SETTERS
     *
     */

    /**
     * Set Time-To-Live
     *
     * Set the block number for the owner's next TTL.
     */
    function _setTTL() private returns (uint ttl) {
        /* Set hash. */
        bytes32 hash = keccak256(
            abi.encodePacked('infinitywell.', msg.sender, '.ttl'));

        /* Set TTL. */
        ttl = block.number + _BLOCKS_PER_EPOCH;

        /* Set value in Zer0net Db. */
        zer0netDb.setUint(hash, ttl);
    }

    /**
     * Set Blocks Per (Difficulty) Adjustment
     *
     * Token owner(s) can adjust the number of blocks per difficulty re-calculation.
     *
     * NOTE: This will help deter malicious miners from gaming the difficulty
     *       parameter, to the detriment of the token's community.
     */
    function setBlocksPerAdjustment(
        address _token,
        uint _numBlocks
    ) external onlyTokenOwner(_token) returns (bool success) {
        /* Set hash. */
        bytes32 hash = keccak256(
            abi.encodePacked('infinitypool.', _token, '.blocks.per.adjustment'));

        /* Set value in Zer0net Db. */
        zer0netDb.setUint(hash, _numBlocks);
    }

    /**
     * Set Mining Challenge
     *
     * Block hash used for calculating the mining (solution) digest.
     */
    function _setMiningChallenge(
        address _token,
        bytes32 _hash
    ) private returns (bool success) {
        /* Set hash. */
        bytes32 hash = keccak256(
            abi.encodePacked('infinitypool.', _token, '.mining.challenge'));

        /* Set value in Zer0net Db. */
        zer0netDb.setBytes(hash, _bytes32ToBytes(_hash));

        /* Return success. */
        return true;
    }

    /**
     * Set Mining Target
     */
    function _setMiningTarget(
        address _token,
        uint _target
    ) private returns (bool success) {
        /* Set hash. */
        bytes32 hash = keccak256(
            abi.encodePacked('infinitypool.', _token, '.mining.target'));

        /* Set value in Zer0net Db. */
        zer0netDb.setUint(hash, _target);

        /* Return success. */
        return true;
    }

    /**
     * Set (Fixed) Mint Amount
     */
    function setMintFixed(
        address _token,
        uint _amount
    ) external onlyTokenOwner(_token) returns (bool success) {
        /* Set hash. */
        bytes32 hash = keccak256(
            abi.encodePacked('infinitypool.', _token, '.mint.fixed'));

        /* Set value in Zer0net Db. */
        zer0netDb.setUint(hash, _amount);

        /* Return success. */
        return true;
    }

    /**
     * Set (Dynamic) Mint Percentage
     */
    function setMintPct(
        address _token,
        uint _pct
    ) external onlyOwner returns (bool success) {
        /* Set hash. */
        bytes32 hash = keccak256(
            abi.encodePacked('infinitypool.', _token, '.mint.pct'));

        /* Set value in Zer0net Db. */
        zer0netDb.setUint(hash, _pct);
    }

    /**
     * THIS CONTRACT DOES NOT ACCEPT DIRECT ETHER
     */
    function () public payable {
        /* Cancel this transaction. */
        revert('Oops! Direct payments are NOT permitted here.');
    }

    /**
     * Transfer Any ERC20 Token
     *
     * @notice Owner can transfer out any accidentally sent ERC20 tokens.
     *
     * @dev Provides an ERC20 interface, which allows for the recover
     *      of any accidentally sent ERC20 tokens.
     */
    function transferAnyERC20Token(
        address tokenAddress, uint tokens
    ) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

    /**
     * Convert Bytes to Bytes32
     */
    function _bytesToBytes32(
        bytes _data
    ) private pure returns (bytes32 result) {
        /* Loop through each byte. */
        for (uint i = 0; i < 32; i++) {
            /* Shift bytes onto result. */
            result |= bytes32(_data[i] & 0xFF) >> (i * 8);
        }
    }

    /**
     * Convert Bytes32 to Bytes
     *
     * NOTE: Since solidity v0.4.22, you can use `abi.encodePacked()` for this,
     *       which returns bytes. (https://ethereum.stackexchange.com/a/55963)
     */
    function _bytes32ToBytes(
        bytes32 _data
    ) private pure returns (bytes result) {
        /* Pack the data. */
        return abi.encodePacked(_data);
    }
}
