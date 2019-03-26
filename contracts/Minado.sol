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
 *
 *          InfinityPool Mining
 *          -------------------
 *
 *          A better model than ICOs and Airdrops, POW mining is accepted as
 *          the MOST democratic distribution system available in crypto today.
 *
 *          Learn more below:
 *
 *          Official : https://infinitypool.info
 *
 *
 *          InfinityWell Forging
 *          --------------------
 *
 *          Minado makes it simple and fun for STAEKers to manage their
 *          InfinityStone forging activities in the InfinityWell.
 *
 *          0STONEs can be used to claim instant rewards towards ANY ERC-20
 *          and/or ERC-721 token(s) currently owned by the InfinityWell.
 *
 *          Learn more below:
 *
 *          Official : https://infinitywell.info
 *
 * Version 19.3.26
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
    function transfer(address _token, address _to, uint _tokens) external returns (bool success);
}


/*******************************************************************************
 *
 * InfinityWell Interface
 */
contract InfinityWellInterface {
    function forgeStones(address _owner, uint _tokens) external returns (bool success);
    function destroyStones(address _owner, uint _tokens) external returns (bool success);
    function transferERC20(address _token, address _to, uint _tokens) external returns (bool success);
    function transferERC721(address _token, address _to, uint256 _tokenId) external returns (bool success);
}


/*******************************************************************************
 *
 * Staek(house) Factory Interface
 */
contract StaekFactoryInterface {
    function balanceOf(bytes32 _staekhouseId) public view returns (uint balance);
    function getStaekhouse(bytes32 _staekhouseId) external view returns (address factory, address token, address owner, uint ownerLockTime, uint providerLockTime, uint debtLimit, uint lockInterval, uint balance);
}


/*******************************************************************************
 *
 * @notice Minado - Token Mining Contract
 *
 * @dev This is a multi-token mining contract, which manages the proof-of-work
 *      verifications before authorizing the movement of tokens from the
 *      InfinityPool and InfinityWell.
 */
contract Minado is Owned {
    using SafeMath for uint;

    /* Initialize predecessor contract. */
    address private _predecessor;

    /* Initialize successor contract. */
    address private _successor;

    /* Initialize revision number. */
    uint private _revision;

    /* Initialize Zer0net Db contract. */
    Zer0netDbInterface private _zer0netDb;

    /**
     * Set Namespace
     *
     * Provides a "unique" name for generating "unique" data identifiers,
     * most commonly used as database "key-value" keys.
     *
     * NOTE: Use of `namespace` is REQUIRED when generating ANY & ALL
     *       Zer0netDb keys; in order to prevent ANY accidental or
     *       malicious SQL-injection vulnerabilities / attacks.
     */
    string private _namespace = 'minado';

    /**
     * Generations Per Re-adjustment
     *
     * By default, we automatically trigger a difficulty adjustment
     * after 144 generations (approx 24hrs).
     *
     *        ~4 ETH blocks per min
     *        1,440 minutes per day (mul)
     *       ~40 ETH blocks per BTC (div)
     * ----------------------------
     *      144 generations per day
     *
     * Frequent adjustments are especially important with low-liquidity
     * tokens, which are more susceptible to mining manipulation.
     *
     * For additional control, token owners retain the ability to trigger
     * a difficulty re-calculation at any time.
     *
     * NOTE: Bitcoin re-adjusts its difficulty every 2016 blocks,
     *       which occurs approx. every 14 days.
     */
    uint private _INITIAL_GENERATIONS_PER_ADJUSTMENT = 144; // approx. 24hrs

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
     * (Ethereum) Blocks Per Generation
     *
     * NOTE: Ethereum blocks take approx 15 seconds each.
     *       1,000 blocks takes approx 4 hours.
     */
    uint private _BLOCKS_PER_GENERATION = 1000;

    /**
     * Epoch Conversion (Ethereum => Bitcoin)
     *
     * NOTE: We want miners to spend 10 minutes to mine each 'block'.
     *       (about 40 Ethereum blocks for every 1 Bitcoin block)
     */
    uint _ETH_BLOCKS_PER_BTC = 40;

    /**
     * Set basis-point multiplier.
     *
     * NOTE: Used for (integer-based) fractional calculations.
     */
    uint private _BP_MULTI = 10000;

    /**
     * Set InfinityStone Decimals
     */
    uint private _STONE_DECIMALS = 18;

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
        bytes32 newChallenge
    );

    event Mint(
        address indexed from,
        uint rewardAmount,
        uint epochCount,
        bytes32 newChallenge
    );

    event ReCalculate(
        address token,
        uint newDifficulty
    );

    event Solution(
        address indexed token,
        address indexed miner,
        uint difficulty,
        uint nonce,
        bytes32 challenge,
        bytes32 newChallenge
    );

    /* Constructor. */
    constructor() public {
        /* Initialize Zer0netDb (eternal) storage database contract. */
        // NOTE We hard-code the address here, since it should never change.
        // _zer0netDb = Zer0netDbInterface(0xE865Fe1A1A3b342bF0E2fcB11fF4E3BCe58263af);
        _zer0netDb = Zer0netDbInterface(0x4C2f68bCdEEB88764b1031eC330aD4DF8d6F64D6); // ROPSTEN

        /* Initialize (aname) hash. */
        bytes32 hash = keccak256(abi.encodePacked('aname.', _namespace));

        /* Set predecessor address. */
        _predecessor = _zer0netDb.getAddress(hash);

        /* Verify predecessor address. */
        if (_predecessor != 0x0) {
            /* Retrieve the last revision number (if available). */
            uint lastRevision = Minado(_predecessor).getRevision();

            /* Set (current) revision number. */
            _revision = lastRevision + 1;
        }
    }

    /**
     * @dev Only allow access to an authorized Zer0net administrator.
     */
    modifier onlyAuthBy0Admin() {
        /* Verify write access is only permitted to authorized accounts. */
        require(_zer0netDb.getBool(keccak256(
            abi.encodePacked(msg.sender, '.has.auth.for.', _namespace))) == true);

        _;      // function code is inserted here
    }

    /**
     * @dev Only allow access to "registered" staekhouse authorized user/contract.
     */
    modifier onlyTokenProvider(
        address _token
    ) {
        /* Validate authorized token manager. */
        require(_zer0netDb.getBool(keccak256(abi.encodePacked(
            _namespace, '.',
            msg.sender,
            '.has.auth.for.',
            _token
        ))) == true);

        _;      // function code is inserted here
    }

    /**
     * THIS CONTRACT DOES NOT ACCEPT DIRECT ETHER
     */
    function () public payable {
        /* Cancel this transaction. */
        revert('Oops! Direct payments are NOT permitted here.');
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
        bytes32 adjustmentHash = keccak256(abi.encodePacked(
            _namespace, '.',
            _token,
            '.blocks.per.adjustment'
        ));

        /* Set value in Zer0net Db. */
        _zer0netDb.setUint(
            adjustmentHash, _INITIAL_GENERATIONS_PER_ADJUSTMENT);

        // TODO Run all initial procedures.

        /* Return success. */
        return true;
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
     * InfinityStone HODLers can claim their ERC token rewards.
     *
     * Up to 5% for ERC-20 tokens; and a single ERC-721 collectible.
     *
     * # 0STONES    REWARD
     * -------------------
     *     1        5% of TOP100 token
     *     3        5% of TOP30 token
     *    10        5% of TOP10 token
     *
     * NOTE: InfinityStone redemptions other than (1, 3, 10)
     *       will be automatically rejected by this contract.
     */
    function _claimGifts(
        address _token,
        address _from,
        uint _tokens,
        bytes _data
    ) private returns (bool success) {
        /* Destroy stones claimed for gifts. */
        _destroyStones(_from, _tokens);

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
     */
    function forgeStones(
        bytes32 _staekhouseId,
        uint _generation
    ) external returns (uint tokens) {
        /* Forge stone(s). */
        return _forgeStones(_staekhouseId, _generation);
    }

    // TODO Add relayer option

    /**
     * Forge NEW InfinityStone(s)
     *
     * NOTE: restricted to a MAX of once per 1000 blocks.
     */
    function _forgeStones(
        bytes32 _staekhouseId,
        uint _generation
    ) private returns (uint tokens) {
        /* Set hash. */
        bytes32 hash = keccak256(
            abi.encodePacked(
                _namespace, '.',
                msg.sender,
                '.has.forged.',
                _generation
            ));

        /* Set value in Zer0net Db. */
        bool hasAlreadyForged = _zer0netDb.getBool(hash);

        /* Validate forging. */
        if (hasAlreadyForged) {
            revert('Oops! You have ALREADY forged from that generation.');
        }

        /* Set value in Zer0net Db. */
        // NOTE: Set flag here to prevent re-entry attack.
        _zer0netDb.setBool(hash, true);

        /* Retrieve forge share. */
        tokens = getOwnerForgeShare(msg.sender, _staekhouseId, _generation);

        // FIXME Add some validation here??

        /* Forge stones. */
        _infinityWell().forgeStones(msg.sender, tokens);
    }

    /**
     * Destroy InfinityStone(s)
     */
    function destroyStones(
        uint _tokens
    ) private returns (bool success) {
        /* Destroy stones. */
        return _destroyStones(msg.sender, _tokens);
    }

    // TODO Add relayer option

    /**
     * Destroy InfinityStone(s)
     */
    function _destroyStones(
        address _owner,
        uint _tokens
    ) private returns (bool success) {
        /* Destroy stones. */
        return _infinityWell()
            .destroyStones(_owner, _tokens);
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
    ) external onlyTokenProvider(_token) returns (bool success) {
        /* Re-calculate difficulty. */
        return _reAdjustDifficulty(_token);
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
    function _reAdjustDifficulty(
        address _token
    ) private returns (bool success) {
        /* Set hash. */
        bytes32 lastAdjustmentHash = keccak256(abi.encodePacked(
            _namespace, '.',
            _token,
            '.last.adjustment'
        ));

        /* Retrieve value from Zer0net Db. */
        uint lastAdjustment = _zer0netDb.getUint(lastAdjustmentHash);

        /* Retrieve value from Zer0net Db. */
        uint blocksSinceLastAdjustment = block.number - lastAdjustment;

        /* Set hash. */
        bytes32 adjustmentHash = keccak256(abi.encodePacked(
            _namespace, '.',
            _token,
            '.blocks.per.adjustment'
        ));

        /* Retrieve value from Zer0net Db. */
        uint blocksPerAdjustment = _zer0netDb.getUint(adjustmentHash);

        /**
         * Expected ETH Blocks (Per Adjustment Period)
         *
         * NOTE: To match Bitcoin, this should be 40 times slower than Ethereum.
         *       eg. 144 x 40 = 5,760
         */
        uint expectedBlocks = blocksPerAdjustment * _ETH_BLOCKS_PER_BTC;

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
        _zer0netDb.setUint(lastAdjustmentHash, block.number);

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
        _setMiningTarget(
            _token,
            block.number
        );

        /* Return success. */
        return true;
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
        bytes32 epochHash = keccak256(abi.encodePacked(
            _namespace, '.',
            _token,
            '.epoch'
        ));

        /* Retrieve value from Zer0net Db. */
        uint epoch = _zer0netDb.getUint(epochHash);

        /* Set value in Zer0net Db. */
        _zer0netDb.setUint(epochHash, epoch.add(1));

        /* Set hash. */
        bytes32 adjustmentHash = keccak256(abi.encodePacked(
            _namespace, '.',
            _token,
            '.blocks.per.adjustment'
        ));

        /* Retrieve value from Zer0net Db. */
        uint blocksPerAdjustment = _zer0netDb.getUint(adjustmentHash);

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
        _setMiningChallenge(
            _token,
            blockhash(block.number - 1)
        );

        /* Return success. */
        return true;
    }

    /**
     * Check Mint Solution
     *
     * NOTE: help debug mining software
     */
    function checkMintSolution(
        uint _nonce,
        bytes32 _challengeDigest,
        bytes32 _challengeNumber,
        uint _testTarget
    ) external view returns (bool success) {
        /* Calculate challenge digest. */
        bytes32 digest = keccak256(abi.encodePacked(
            _challengeNumber,
            msg.sender,
            _nonce
        ));

        /* Validate digest. */
        if (uint(digest) > _testTarget) {
            revert('Oops! Your mint solution is INCORRECT.');
        }

        /* Test digest. */
        return (digest == _challengeDigest);
    }

    /**
     * Mint (Mineable) Token
     *
     * Token owner(s) have the option of setting up to 3 parents to
     * offer "qualifying" merge minting difficulty for their own
     * minting solution.
     *
     * NOTE: Allowing multiple "Mining Kings" should hopefully encourage
     *       children to adopt more parents and promote a more "diverse"
     *       group of merged mining options for miners.
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
        bytes32 digest = keccak256(abi.encodePacked(
            challengeNumber,
            msg.sender,
            _nonce
        ));

        /* The challenge digest must match the expected. */
        if (digest != _challengeDigest) {
            revert('Challenge digest is incorrect!');
        }

        /* Validate the digest. */
        if (uint(digest) > miningTarget) {
            revert('The digest CANNOT be greater than the target.');
        }

        /**
         * Solution Validation
         *
         * Only allow one minting for each challenge.
         */

        /* Set hash. */
        bytes32 solutionHash = keccak256(abi.encodePacked(
            _namespace, '.',
            _token,
            '.solution.for.',
            challengeNumber
        ));

        /* Validate UNSOLVED solution. */
        // NOTE: Prevent the same answer from awarding twice.
        if (_zer0netDb.getBytes(solutionHash).length > 0) {
            revert('This solution has already been mined.');
        }

        /* Set value in Zer0net Db. */
        _zer0netDb.setBytes(solutionHash, _bytes32ToBytes(digest));

        /* Retrieve mint amount. */
        uint mintAmount = getMintAmount(_token);

        /* Transfer tokens from InfinityPool to owner. */
        _infinityPool().transfer(
            _token,
            msg.sender,
            mintAmount
        );

        /* Begin a new mining epoch. */
         _beginMiningEpoch(_token);

        /* Broadcast event. */
        emit Mint(
            msg.sender,
            mintAmount,
            getForgingGen(),
            challengeNumber
        );

        /* Return success. */
        return true;
    }


    /***************************************************************************
     *
     * GETTERS
     *
     */

    /**
     * (Get) Staek Of (Owner)
     *
     * Current balance of ZeroGold staeked to this contract.
     */
    // function staekOf(
    //     bytes32 _staekhouseId,
    //     address _owner
    // ) public view returns (uint staek) {
    //     /* Retreive balance from staekhouse. */
    //     return _staekFactory().balanceOf(_staekhouseId, _owner);
    // }

    /**
     * Get Starting Block
     *
     * Starting Blocks
     * ---------------
     *
     * First blocks honoring the start of Miss Piggy's celebration year:
     *     - Mainnet: 7,175,716
     *     - Ropsten: 4,956,268
     *
     * NOTE: Pulls value from db `minado.starting.block` using the
     *       repspective networks.
     */
    function getStartingBlock() public view returns (uint startingBlock) {
        /* Set hash. */
        bytes32 hash = keccak256(abi.encodePacked(
            _namespace,
            '.starting.block'
        ));

        /* Retrieve value from Zer0net Db. */
        startingBlock = _zer0netDb.getUint(hash);
    }

    /**
     * Get Forging Generation
     *
     * Returns the current generation (in the forging cycle).
     */
    function getForgingGen() public view returns (uint generation) {
        /* Calculate number of elapsed blocks. */
        uint blocksElapsed = block.number.sub(getStartingBlock());

        /* Calculate current generation. */
        generation = uint(blocksElapsed.div(_BLOCKS_PER_GENERATION));
    }

    function _getStaekhouseOwner(
        bytes32 _staekhouseId
    ) private view returns (address _owner) {
        /* Retrieve staekhouse values. */
        (
            address factory,
            address token,
            address owner,
            uint ownerLockTime,
            uint providerLockTime,
            uint debtLimit,
            uint lockInterval,
            uint balance
        ) = _staekFactory().getStaekhouse(_staekhouseId);

        /* Return owner. */
        return owner;
    }

    /**
     * Get Owner (Current) Forge Share
     */
    function getOwnerForgeShare(
        address _owner,
        bytes32 _staekhouseId,
        uint _generation
    ) public returns (uint share) {
        /* Set hash. */
        bytes32 hasForgedHash = keccak256(
            abi.encodePacked(
                _namespace, '.',
                _owner,
                '.has.forged.',
                _generation
            ));

        /* Validate forging ability. */
        if (_zer0netDb.getBool(hasForgedHash) == true) {
            return 0;
        }

        /* Retrieve staekhouse owner. */
        address staekhouseOwner = _getStaekhouseOwner(_staekhouseId);

        /* Validate staekhouse owner. */
        if (staekhouseOwner != _owner) {
            return 0;
        }

        /* Retrieve owner staek amount. */
        uint staek = _staekFactory().balanceOf(_staekhouseId);

        /* Set hash. */
        bytes32 staekHash = keccak256(abi.encodePacked(
            _staekhouseId, '.total.staek'));

        /* Retrieve value from Zer0net Db. */
        uint totalStaek = _zer0netDb.getUint(staekHash);

        /* Calculate owner rate. */
        // NOTE: basis-point multiplier, 10,000 == 100.00%
        uint ownerRate = staek.mul(_BP_MULTI).div(totalStaek);

        /* Calculate owner (basis) points. */
        // NOTE: basis-point multiplier, 1 == 10,000
        uint ownerPoints = (1 * 10**_STONE_DECIMALS) * ownerRate;

        /* Calculate owner share. */
        share = ownerPoints.div(_BP_MULTI);
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
        /* Retrieve value from Zer0net Db. */
        challengeNumber = _bytesToBytes32(_zer0netDb.getBytes(
            keccak256(abi.encodePacked(
                _namespace, '.',
                _token,
                '.challenge.number'
            ))
        ));
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
            .balanceOf(address(_infinityPool()));

        /* Set hash. */
        bytes32 fixedHash = keccak256(abi.encodePacked(
            _namespace, '.',
            _token,
            '.mint.fixed'
        ));

        /* Return value from Zer0net Db. */
        uint dbMintFixed = _zer0netDb.getUint(fixedHash);

        /* Validate mint amount (does NOT exceed balance). */
        if (dbMintFixed > infinityBalance) {
            /* Set mint total to MAX balance. */
            mintTotal = infinityBalance;
        } else {
            /* Set mint total to fixed amount. */
            mintTotal = dbMintFixed;
        }

        /* Set hash. */
        bytes32 pctHash = keccak256(abi.encodePacked(
            _namespace, '.',
            _token,
            '.mint.pct'
        ));

        /* Return value from Zer0net Db. */
        uint dbMintPct = _zer0netDb.getUint(pctHash);

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
        bytes32 hash = keccak256(abi.encodePacked(
            _namespace, '.',
            _token,
            '.mining.target'
        ));

        /* Return value from Zer0net Db. */
        miningTarget = _zer0netDb.getUint(hash);
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

    /**
     * Get Token Master
     *
     * DEPRECATED -- use dynamic parent/child assignments
     *
     * This is the token with the highest difficulty in the
     * Infinity Pool community. (reads from `challengeNumber`)
     *
     * NOTE: This is currently set to 0xBitcoin:
     *       - Address: 0xB6eD7644C69416d67B522e20bC294A9a9B405B31
     *       - Difficulty: 1,151,621,296
     */
    function getTokenMaster() public view returns (address tokenMaster) {
        /* Set hash. */
        bytes32 hash = keccak256(abi.encodePacked(
            _namespace,
            '.token.master'
        ));

        /* Return value from Zer0net Db. */
        tokenMaster = _zer0netDb.getAddress(hash);
    }

    /**
     * Get Revision (Number)
     */
    function getRevision() public view returns (uint) {
        return _revision;
    }


    /***************************************************************************
     *
     * SETTERS
     *
     */

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
    ) external onlyTokenProvider(_token) returns (bool success) {
        /* Set hash. */
        bytes32 hash = keccak256(abi.encodePacked(
            _namespace, '.',
            _token,
            '.blocks.per.adjustment'
        ));

        /* Set value in Zer0net Db. */
        _zer0netDb.setUint(hash, _numBlocks);

        /* Return success. */
        return true;
    }

    /**
     * Set Last Generation
     */
    function _setLastGen() private returns (bool success) {
        /* Set hash. */
        bytes32 hash = keccak256(abi.encodePacked(
            _namespace,
            '.generation'
        ));

        /* Set value in Zer0net Db. */
        _zer0netDb.setUint(hash, getForgingGen());

        /* Return success. */
        return true;
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
        bytes32 hash = keccak256(abi.encodePacked(
            _namespace, '.',
            _token,
            '.mining.challenge'
        ));

        /* Set value in Zer0net Db. */
        _zer0netDb.setBytes(hash, _bytes32ToBytes(_hash));

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
        bytes32 hash = keccak256(abi.encodePacked(
            _namespace, '.',
            _token,
            '.mining.target'
        ));

        /* Set value in Zer0net Db. */
        _zer0netDb.setUint(hash, _target);

        /* Return success. */
        return true;
    }

    /**
     * Set (Fixed) Mint Amount
     */
    function setMintFixed(
        address _token,
        uint _amount
    ) external onlyTokenProvider(_token) returns (bool success) {
        /* Set hash. */
        bytes32 hash = keccak256(abi.encodePacked(
            _namespace, '.',
            _token,
            '.mint.fixed'
        ));

        /* Set value in Zer0net Db. */
        _zer0netDb.setUint(hash, _amount);

        /* Return success. */
        return true;
    }

    /**
     * Set (Dynamic) Mint Percentage
     */
    function setMintPct(
        address _token,
        uint _pct
    ) external onlyTokenProvider(_token) returns (bool success) {
        /* Set hash. */
        bytes32 hash = keccak256(abi.encodePacked(
            _namespace, '.',
            _token,
            '.mint.pct'
        ));

        /* Set value in Zer0net Db. */
        _zer0netDb.setUint(hash, _pct);

        /* Return success. */
        return true;
    }

    /**
     * Set Token Parent(s)
     *
     * Enables the use of merged mining by specifying (parent) tokens
     * that offer an acceptibly HIGH difficulty for the child's own
     * mining challenge.
     *
     * NOTE: Up to 3 parents can be set to 1 of 3 priority levels.
     *       1 - Strictest parent
     *       2 - 2nd strictest parent
     *       3 - Least strict parent
     */
    function setTokenParent(
        address _token,
        address _parent,
        uint _priority
    ) external onlyAuthBy0Admin returns (bool success) {
        /* Set hash. */
        bytes32 hash = keccak256(abi.encodePacked(
            _namespace, '.',
            _token,
            '.parent.',
            _priority
        ));

        /* Set value in Zer0net Db. */
        _zer0netDb.setAddress(hash, _parent);

        /* Return success. */
        return true;
    }


    /***************************************************************************
     *
     * INTERFACES
     *
     */

    /**
     * ZeroGold Interface
     *
     * Retrieves the current ZeroGold interface,
     * using the aname record from Zer0netDb.
     */
    function _zeroGold() private view returns (
        ERC20Interface zeroGold
    ) {
        /* Initailze hash. */
        // NOTE: ERC tokens are case-sensitive.
        bytes32 hash = keccak256('aname.0GOLD');

        /* Retrieve value from Zer0net Db. */
        address aname = _zer0netDb.getAddress(hash);

        /* Initialize interface. */
        zeroGold = ERC20Interface(aname);
    }

    /**
     * InfinityPool Interface
     *
     * Retrieves the current InfinityPool interface,
     * using the aname record from Zer0netDb.
     */
    function _infinityPool() private view returns (
        InfinityPoolInterface infinityPool
    ) {
        /* Initailze hash. */
        bytes32 hash = keccak256('aname.infinitypool');

        /* Retrieve value from Zer0net Db. */
        address aname = _zer0netDb.getAddress(hash);

        /* Initialize interface. */
        infinityPool = InfinityPoolInterface(aname);
    }

    /**
     * InfinityWell Interface
     *
     * Retrieves the current InfinityWell interface,
     * using the aname record from Zer0netDb.
     */
    function _infinityWell() private view returns (
        InfinityWellInterface infinityWell
    ) {
        /* Initailze hash. */
        bytes32 hash = keccak256('aname.infinitywell');

        /* Retrieve value from Zer0net Db. */
        address aname = _zer0netDb.getAddress(hash);

        /* Initialize interface. */
        infinityWell = InfinityWellInterface(aname);
    }

    /**
     * Staek(house) Factory Interface
     *
     * Retrieves the current Staek(house) Factory interface,
     * using the aname record from Zer0netDb.
     */
    function _staekFactory() private view returns (
        StaekFactoryInterface staekhouse
    ) {
        /* Initailze hash. */
        bytes32 hash = keccak256('aname.staek.factory');

        /* Retrieve value from Zer0net Db. */
        address aname = _zer0netDb.getAddress(hash);

        /* Initialize interface. */
        staekhouse = StaekFactoryInterface(aname);
    }


    /***************************************************************************
     *
     * UTILITIES
     *
     */

    /**
     * Is (Owner) Contract
     *
     * Tests if a specified account / address is a contract.
     */
    function _ownerIsContract(
        address _owner
    ) private view returns (bool isContract) {
        /* Initialize code length. */
        uint codeLength;

        /* Run assembly. */
        assembly {
            /* Retrieve the size of the code on target address. */
            codeLength := extcodesize(_owner)
        }

        /* Set test result. */
        isContract = (codeLength > 0);
    }

    /**
     * Bytes-to-Address
     *
     * Converts bytes into type address.
     */
    function _bytesToAddress(bytes _address) private pure returns (address) {
        uint160 m = 0;
        uint160 b = 0;

        for (uint8 i = 0; i < 20; i++) {
            m *= 256;
            b = uint160(_address[i]);
            m += (b);
        }

        return address(m);
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

    /**
     * Transfer Any ERC20 Token
     *
     * @notice Owner can transfer out any accidentally sent ERC20 tokens.
     *
     * @dev Provides an ERC20 interface, which allows for the recover
     *      of any accidentally sent ERC20 tokens.
     */
    function transferAnyERC20Token(
        address _tokenAddress,
        uint _tokens
    ) public onlyOwner returns (bool success) {
        return ERC20Interface(_tokenAddress).transfer(owner, _tokens);
    }
}
