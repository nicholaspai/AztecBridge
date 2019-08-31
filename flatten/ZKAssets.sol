pragma solidity >= 0.5.0 <0.7.0;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://eips.ethereum.org/EIPS/eip-20
 * Originally based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return A uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
     * @dev Transfer token to a specified address
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Transfer token for a specified addresses
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Approve an address to spend another addresses' tokens.
     * @param owner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * Emits an Approval event (reflecting the reduced allowance).
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}

contract IAZTEC {
    enum ProofCategory {
        NULL,
        BALANCED,
        MINT,
        BURN,
        UTILITY
    }

    enum NoteStatus {
        DOES_NOT_EXIST,
        UNSPENT,
        SPENT
    }
    // proofEpoch = 1 | proofCategory = 1 | proofId = 1
    // 1 * 256**(2) + 1 * 256**(1) ++ 1 * 256**(0)
    uint24 public constant JOIN_SPLIT_PROOF = 65793;

    // proofEpoch = 1 | proofCategory = 2 | proofId = 1
    // (1 * 256**(2)) + (2 * 256**(1)) + (1 * 256**(0))
    uint24 public constant MINT_PROOF = 66049;

    // proofEpoch = 1 | proofCategory = 3 | proofId = 1
    // (1 * 256**(2)) + (3 * 256**(1)) + (1 * 256**(0))
    uint24 public constant BURN_PROOF = 66305;

    // proofEpoch = 1 | proofCategory = 4 | proofId = 2
    // (1 * 256**(2)) + (4 * 256**(1)) + (2 * 256**(0))
    uint24 public constant PRIVATE_RANGE_PROOF = 66562;

    // proofEpoch = 1 | proofCategory = 4 | proofId = 1
    // (1 * 256**(2)) + (4 * 256**(1)) + (2 * 256**(0))
    uint24 public constant DIVIDEND_PROOF = 66561;


    // Hash of a dummy AZTEC note with k = 0 and a = 1
    bytes32 public constant ZERO_VALUE_NOTE_HASH = 0xcbc417524e52b95c42a4c42d357938497e3d199eb9b4a0139c92551d4000bc3c;
}

/**
 * @title NoteUtils
 * @author AZTEC
 * @dev NoteUtils is a utility library that extracts user-readable information from AZTEC proof outputs.
 *      Specifically, `bytes proofOutput` objects can be extracted from `bytes proofOutputs`,
 *      `bytes proofOutput` and `bytes note` can be extracted into their constituent components,
 **/
library NoteUtils {

    /**
    * @dev Get the number of entries in an AZTEC-ABI array (bytes proofOutputs, bytes inputNotes, bytes outputNotes)
    *      All 3 are rolled into a single function to eliminate 'wet' code - the implementations are identical
    * @param _proofOutputsOrNotes `proofOutputs`, `inputNotes` or `outputNotes`
    * @return number of entries in the pseudo dynamic array
    */
    function getLength(bytes memory _proofOutputsOrNotes) internal pure returns (
        uint len
    ) {
        assembly {
            // first word = the raw byte length
            // second word = the actual number of entries (hence the 0x20 offset)
            len := mload(add(_proofOutputsOrNotes, 0x20))
        }
    }

    /**
    * @dev Get a bytes object out of a dynamic AZTEC-ABI array
    * @param _proofOutputsOrNotes `proofOutputs`, `inputNotes` or `outputNotes`
    * @param _i the desired entry
    * @return number of entries in the pseudo dynamic array
    */
    function get(bytes memory _proofOutputsOrNotes, uint _i) internal pure returns (
        bytes memory out
    ) {
        bool valid;
        assembly {
            // check that i < the number of entries
            valid := lt(
                _i,
                mload(add(_proofOutputsOrNotes, 0x20))
            )
            // memory map of the array is as follows:
            // 0x00 - 0x20 : byte length of array
            // 0x20 - 0x40 : n, the number of entries
            // 0x40 - 0x40 + (0x20 * i) : relative memory offset to start of i'th entry (i <= n)

            // Step 1: compute location of relative memory offset: _proofOutputsOrNotes + 0x40 + (0x20 * i) 
            // Step 2: loaded relative offset and add to _proofOutputsOrNotes to get absolute memory location
            out := add(
                mload(
                    add(
                        add(_proofOutputsOrNotes, 0x40),
                        mul(_i, 0x20)
                    )
                ),
                _proofOutputsOrNotes
            )
        }
        require(valid, "AZTEC array index is out of bounds");
    }

    /**
    * @dev Extract constituent elements of a `bytes _proofOutput` object
    * @param _proofOutput an AZTEC proof output
    * @return inputNotes, AZTEC-ABI dynamic array of input AZTEC notes
    * @return outputNotes, AZTEC-ABI dynamic array of output AZTEC notes
    * @return publicOwner, the Ethereum address of the owner of any public tokens involved in the proof
    * @return publicValue, the amount of public tokens involved in the proof
    *         if (publicValue > 0), this represents a transfer of tokens from ACE to publicOwner
    *         if (publicValue < 0), this represents a transfer of tokens from publicOwner to ACE
    */
    function extractProofOutput(bytes memory _proofOutput) internal pure returns (
        bytes memory inputNotes,
        bytes memory outputNotes,
        address publicOwner,
        int256 publicValue
    ) {
        assembly {
            // memory map of a proofOutput:
            // 0x00 - 0x20 : byte length of proofOutput
            // 0x20 - 0x40 : relative offset to inputNotes
            // 0x40 - 0x60 : relative offset to outputNotes
            // 0x60 - 0x80 : publicOwner
            // 0x80 - 0xa0 : publicValue
            // 0xa0 - 0xc0 : challenge
            inputNotes := add(_proofOutput, mload(add(_proofOutput, 0x20)))
            outputNotes := add(_proofOutput, mload(add(_proofOutput, 0x40)))
            publicOwner := and(
                mload(add(_proofOutput, 0x60)),
                0xffffffffffffffffffffffffffffffffffffffff
            )
            publicValue := mload(add(_proofOutput, 0x80))
        }
    }

    /**
    * @dev Extract the challenge from a bytes proofOutput variable
    * @param _proofOutput bytes proofOutput, outputted from a proof validation smart contract
    * @return bytes32 challenge - cryptographic variable that is part of the sigma protocol
    */
    function extractChallenge(bytes memory _proofOutput) internal pure returns (
        bytes32 challenge
    ) {
        assembly {
            challenge := mload(add(_proofOutput, 0xa0))
        }
    }

    /**
    * @dev Extract constituent elements of an AZTEC note
    * @param _note an AZTEC note
    * @return owner, Ethereum address of note owner
    * @return noteHash, the hash of the note's public key
    * @return metadata, note-specific metadata (contains public key and any extra data needed by note owner)
    */
    function extractNote(bytes memory _note) internal pure returns (
            address owner,
            bytes32 noteHash,
            bytes memory metadata
    ) {
        assembly {
            // memory map of a note:
            // 0x00 - 0x20 : byte length of note
            // 0x20 - 0x40 : note type
            // 0x40 - 0x60 : owner
            // 0x60 - 0x80 : noteHash
            // 0x80 - 0xa0 : start of metadata byte array
            owner := and(
                mload(add(_note, 0x40)),
                0xffffffffffffffffffffffffffffffffffffffff
            )
            noteHash := mload(add(_note, 0x60))
            metadata := add(_note, 0x80)
        }
    }
    
    /**
    * @dev Get the note type
    * @param _note an AZTEC note
    * @return noteType
    */
    function getNoteType(bytes memory _note) internal pure returns (
        uint256 noteType
    ) {
        assembly {
            noteType := mload(add(_note, 0x20))
        }
    }
}

/**
 * @title Library of proof utility functions
 * @author AZTEC
 * Copyright Spilsbury Holdings Ltd 2019. All rights reserved.
 **/
library ProofUtils {

    /**
     * @dev We compress three uint8 numbers into only one uint24 to save gas.
     * Reverts if the category is not one of [1, 2, 3, 4].
     * @param proof The compressed uint24 number.
     * @return A tuple (uint8, uint8, uint8) representing the epoch, category and proofId.
     */
    function getProofComponents(uint24 proof) internal pure returns (uint8 epoch, uint8 category, uint8 id) {
        assembly {
            id := and(proof, 0xff)
            category := and(div(proof, 0x100), 0xff)
            epoch := and(div(proof, 0x10000), 0xff)
        }
        return (epoch, category, id);
    }
}

/**
 * @title NoteRegistry contract which contains the storage variables that define the set of valid
 * AZTEC notes for a particular address
 * @author AZTEC
 * @dev The NoteRegistry defines the state of valid AZTEC notes. It enacts instructions to update the 
 * state, given to it by the ACE and only the note registry owner can enact a state update.  
 * Copyright Spilsbury Holdings Ltd 2019. All rights reserved.
 **/
contract NoteRegistry is IAZTEC {
    using NoteUtils for bytes;
    using SafeMath for uint256;
    using ProofUtils for uint24;

    // registry address is same as ACE address
    event CreateNoteRegistry(
        address registryOwner,
        address registryAddress,
        uint256 scalingFactor,
        address linkedTokenAddress,
        bool canAdjustSupply,
        bool canConvert
    );

    /**
    * Note struct. This is the data that we store when we log AZTEC notes inside a NoteRegistry
    *
    * Data structured so that the entire struct fits in 1 storage word.
    *
    * @notice Yul is used to pack and unpack Note structs in storage for efficiency reasons,
    *   see `NoteRegistry.updateInputNotes` and `NoteRegistry.updateOutputNotes` for more details
    **/
    struct Note {
        // `status` uses the IAZTEC.NoteStatus enum to track the lifecycle of a note.
        uint8 status;

        // `createdOn` logs the timestamp of the block that created this note. There are a few
        // use cases that require measuring the age of a note, (e.g. interest rate computations).
        // These lifetime are relevant on timescales of days/months, the 900-ish seconds that a miner
        // can manipulate a timestamp has little effect, but should be considered when utilizing this parameter.
        // We store `createdOn` in 5 bytes of data - just in case this contract is still around in 2038 :)
        // This kicks the 'year 2038' problem down the road by about 400 years
        uint40 createdOn;

        // `destroyedOn` logs the timestamp of the block that destroys this note in a transaction.
        // Default value is 0x0000000000 for notes that have not been spent.
        uint40 destroyedOn;

        // The owner of the note
        address owner;
    }

    struct Flags {
        bool active;
        bool canAdjustSupply;
        bool canConvert;
    }

    struct Registry {
        IERC20 linkedToken;
        uint256 scalingFactor;
        uint256 totalSupply;
        bytes32 confidentialTotalMinted;
        bytes32 confidentialTotalBurned;
        uint256 supplementTotal;
        Flags flags;
        mapping(bytes32 => Note) notes;
        mapping(address => mapping(bytes32 => uint256)) publicApprovals;
    }

    // Every user has their own note registry
    mapping(address => Registry) internal registries;

    mapping(bytes32 => bool) public validatedProofs;

    /**
    * @dev Call transferFrom on a linked ERC20 token. Used in cases where the ACE's mint
    * function is called but the token balance of the note registry in question is
    * insufficient
    *
    * @param _value the value to be transferred
    */
    function supplementTokens(uint256 _value) external {
        Registry storage registry = registries[msg.sender];
        require(registry.flags.active == true, "note registry does not exist for the given address");
        require(registry.flags.canConvert == true, "note registry does not have conversion rights");
        
        // Only scenario where supplementTokens() should be called is when a mint/burn operation has been executed
        require(registry.flags.canAdjustSupply == true, "note registry does not have mint and burn rights");
        
        registry.linkedToken.transferFrom(msg.sender, address(this), _value.mul(registry.scalingFactor));

        registry.totalSupply = registry.totalSupply.add(_value);
    }

    /**
    * @dev Query the ACE for a previously validated proof
    * @notice This is a virtual function, that must be overwritten by the contract that inherits from NoteRegistr
    *
    * @param _proof - unique identifier for the proof in question and being validated
    * @param _proofHash - keccak256 hash of a bytes proofOutput argument. Used to identify the proof in question
    * @param _sender - address of the entity that originally validated the proof
    * @return boolean - true if the proof has previously been validated, false if not
    */
    function validateProofByHash(uint24 _proof, bytes32 _proofHash, address _sender) public view returns (bool);

    function createNoteRegistry(
        address _linkedTokenAddress,
        uint256 _scalingFactor,
        bool _canAdjustSupply,
        bool _canConvert
    ) public {
        require(registries[msg.sender].flags.active == false, "address already has a linked note registry");
        if (_canConvert) {
            require(_linkedTokenAddress != address(0x0), "expected the linked token address to exist");
        }
        Registry memory registry = Registry({
            linkedToken: IERC20(_linkedTokenAddress),
            scalingFactor: _scalingFactor,
            totalSupply: 0,
            confidentialTotalMinted: ZERO_VALUE_NOTE_HASH,
            confidentialTotalBurned: ZERO_VALUE_NOTE_HASH,
            supplementTotal: 0,
            flags: Flags({
                active: true,
                canAdjustSupply: _canAdjustSupply,
                canConvert: _canConvert
            })
        });
        registries[msg.sender] = registry;

        emit CreateNoteRegistry(
            msg.sender,
            address(this),
            _scalingFactor,
            _linkedTokenAddress,
            _canAdjustSupply,
            _canConvert
        );
    }

    /**
    * @dev Update the state of the note registry according to transfer instructions issued by a 
    * zero-knowledge proof
    *
    * @param _proof - unique identifier for a proof
    * @param _proofOutput - transfer instructions issued by a zero-knowledge proof
    * @param _proofSender - address of the entity sending the proof
    */
    function updateNoteRegistry(
        uint24 _proof,
        bytes memory _proofOutput,
        address _proofSender
    ) public {
        Registry storage registry = registries[msg.sender];
        Flags memory flags = registry.flags;
        require(flags.active == true, "note registry does not exist for the given address");
        bytes32 proofHash = keccak256(_proofOutput);
        require(
            validateProofByHash(_proof, proofHash, _proofSender) == true,
            "ACE has not validated a matching proof"
        );
        
        // clear record of valid proof - stops re-entrancy attacks and saves some gas
        validatedProofs[proofHash] = false;
        
        (bytes memory inputNotes,
        bytes memory outputNotes,
        address publicOwner,
        int256 publicValue) = _proofOutput.extractProofOutput();

        updateInputNotes(inputNotes);
        updateOutputNotes(outputNotes);

        // If publicValue != 0, enact a token transfer
        // (publicValue < 0) => transfer from publicOwner to ACE
        // (publicValue > 0) => transfer from ACE to publicOwner

        if (publicValue != 0) {
            require(flags.canConvert == true, "asset cannot be converted into public tokens");

            if (publicValue < 0) {
                uint256 publicApprovals = registry.publicApprovals[publicOwner][proofHash];
                registry.totalSupply = registry.totalSupply.add(uint256(-publicValue));
                require(
                    publicApprovals >= uint256(-publicValue),
                    "public owner has not validated a transfer of tokens"
                );
                // TODO: redundant step
                registry.publicApprovals[publicOwner][proofHash] = publicApprovals.sub(uint256(-publicValue));
                registry.linkedToken.transferFrom(
                    publicOwner,
                    address(this),
                    uint256(-publicValue).mul(registry.scalingFactor));
            } else {
                registry.totalSupply = registry.totalSupply.sub(uint256(publicValue));
                registry.linkedToken.transfer(publicOwner, uint256(publicValue).mul(registry.scalingFactor));
            }
        }
    }

    /** 
    * @dev This should be called from an asset contract.
    */
    function publicApprove(address _registryOwner, bytes32 _proofHash, uint256 _value) public {
        Registry storage registry = registries[_registryOwner];
        require(registry.flags.active == true, "note registry does not exist");
        registry.publicApprovals[msg.sender][_proofHash] = _value;
    }

    /**
     * @dev Returns the registry for a given address.
     *
     * @param _owner - address of the registry owner in question
     * @return linkedTokenAddress - public ERC20 token that is linked to the NoteRegistry. This is used to
     * transfer public value into and out of the system     
     * @return scalingFactor - defines how many ERC20 tokens are represented by one AZTEC note
     * @return totalSupply - TODO
     * @return confidentialTotalMinted - keccak256 hash of the note representing the total minted supply
     * @return confidentialTotalBurned - keccak256 hash of the note representing the total burned supply
     * @return canConvert - flag set by the owner to decide whether the registry has public to private, and 
     * vice versa, conversion privilege
     * @return canAdjustSupply - determines whether the registry has minting and burning privileges 
     */
    function getRegistry(address _owner) public view returns (
        address linkedToken,
        uint256 scalingFactor,
        uint256 totalSupply,
        bytes32 confidentialTotalMinted,
        bytes32 confidentialTotalBurned,
        bool canConvert,
        bool canAdjustSupply
    ) {
        require(registries[_owner].flags.active == true, "expected registry to be created");
        Registry memory registry = registries[_owner];
        return (
            address(registry.linkedToken),
            registry.scalingFactor,
            registry.totalSupply,
            registry.confidentialTotalMinted,
            registry.confidentialTotalBurned,
            registry.flags.canConvert,
            registry.flags.canAdjustSupply
        );
    }

    /**
     * @dev Returns the note for a given address and note hash.
     *
     * @param _registryOwner - address of the registry owner
     * @param _noteHash - keccak256 hash of the note coordiantes (gamma and sigma)
     * @return status - status of the note, details whether the note is in a note registry
     * or has been destroyed
     * @return createdOn - time the note was created
     * @return destroyedOn - time the note was destroyed
     * @return noteOwner - address of the note owner
     */
    function getNote(address _registryOwner, bytes32 _noteHash) public view returns (
        uint8 status,
        uint40 createdOn,
        uint40 destroyedOn,
        address noteOwner
    ) {
        require(
            registries[_registryOwner].notes[_noteHash].status != uint8(NoteStatus.DOES_NOT_EXIST), 
            "expected note to exist"
        );
        // Load out a note for a given registry owner. Struct unpacking is done in Yul to improve efficiency
        // solhint-disable-next-line no-unused-vars
        Note storage notePtr = registries[_registryOwner].notes[_noteHash];
        assembly {
            let note := sload(notePtr_slot)
            status := and(note, 0xff)
            createdOn := and(shr(8, note), 0xffffffffff)
            destroyedOn := and(shr(48, note), 0xffffffffff)
            noteOwner := and(shr(88, note), 0xffffffffffffffffffffffffffffffffffffffff)
        }
    }

    /**
     * @dev Removes input notes from the note registry
     *
     * @param inputNotes - an array of input notes from a zero-knowledge proof, that are to be
     * removed and destroyed from a note registry
     */
    function updateInputNotes(bytes memory inputNotes) internal {
        // set up some temporary variables we'll need
        // N.B. the status flags are NoteStatus enums, but written as uint8's.
        // We represent them as uint256 vars because it is the enum values that enforce type safety.
        // i.e. if we include enums that range beyond 256,
        // casting to uint8 won't help because we'll still be writing/reading the wrong note status
        // To summarise the summary - validate enum bounds in tests, use uint256 to save some gas vs uint8
        uint256 inputNoteStatusNew = uint256(NoteStatus.SPENT);
        uint256 inputNoteStatusOld;
        address inputNoteOwner;

        // Update the status of each `note` `inputNotes` to the following:
        // 1. set the note status to SPENT
        // 2. update the `destroyedOn` timestamp to the current timestamp
        // We also must check the following:
        // 1. the note has an existing status of UNSPENT
        // 2. the note owner matches the provided input
        uint256 length = inputNotes.getLength();
        for (uint256 i = 0; i < length; i += 1) {
            (address noteOwner, bytes32 noteHash,) = inputNotes.get(i).extractNote();

            // Get the storage location of the input note
            // solhint-disable-next-line no-unused-vars
            Note storage inputNotePtr = registries[msg.sender].notes[noteHash];

            // We update the note using Yul, as Solidity can be a bit inefficient when performing struct packing.
            // The compiler also invokes redundant sload opcodes that we can remove in Yul
            assembly {
                // load up our note from storage
                let note := sload(inputNotePtr_slot)

                // extract the status of this note (we'll check that it is UNSPENT outside the asm block)
                inputNoteStatusOld := and(note, 0xff)

                // extract the owner of this note (we'll check that it is _owner outside the asm block)
                inputNoteOwner := and(shr(88, note), 0xffffffffffffffffffffffffffffffffffffffff)

                // update the input note and write it into storage.
                // We need to change its `status` from UNSPENT to SPENT, and update `destroyedOn`
                sstore(
                    inputNotePtr_slot,
                    or(
                        // zero out the bits used to store `status` and `destroyedOn`
                        // `status` occupies byte index 1, `destroyedOn` occupies byte indices 6 - 11.
                        // We create bit mask with a NOT opcode to reduce contract bytecode size.
                        // We then perform logical AND with the bit mask to zero out relevant bits
                        and(
                            note,
                            not(0xffffffffff0000000000ff)
                        ),
                        // Now that we have zeroed out storage locations of `status` and `destroyedOn`, update them
                        or(
                            // Create 5-byte timestamp and shift into byte positions 6-11 with a bit shift
                            shl(48, and(timestamp, 0xffffffffff)),
                            // Combine with the new note status (masked to a uint8)
                            and(inputNoteStatusNew, 0xff)
                        )
                    )
                )
            }
            // Check that the note status is UNSPENT
            require(inputNoteStatusOld == uint256(NoteStatus.UNSPENT), "input note status is not UNSPENT");
            // Check that the note owner is the expected owner
            require(inputNoteOwner == noteOwner, "input note owner does not match");
        }
    }

    /**
     * @dev Adds output notes to the note registry
     *
     * @param outputNotes - an array of output notes from a zero-knowledge proof, that are to be
     * added to the note registry
     */
    function updateOutputNotes(bytes memory outputNotes) internal {
        // set up some temporary variables we'll need
        uint256 outputNoteStatusNew = uint256(NoteStatus.UNSPENT);
        uint256 outputNoteStatusOld;
        uint256 length = outputNotes.getLength();

        for (uint256 i = 0; i < length; i += 1) {
            (address noteOwner, bytes32 noteHash,) = outputNotes.get(i).extractNote();
            require(noteOwner != address(0x0), "output note owner cannot be address(0x0)");

            // Create a record in the note registry for this output note
            // solhint-disable-next-line no-unused-vars
            Note storage outputNotePtr = registries[msg.sender].notes[noteHash];

            // We manually pack our note struct in Yul, because Solidity can be a bit liberal with gas when doing this
            assembly {
                // Load the status flag for this note - we check this equals DOES_NOT_EXIST outside asm block
                outputNoteStatusOld := and(sload(outputNotePtr_slot), 0xff)

                // Write a new note into storage
                sstore(
                    outputNotePtr_slot,
                    // combine `status`, `createdOn` and `owner` via logical OR opcodes
                    or(
                        or(
                            // `status` occupies byte position 0
                            and(outputNoteStatusNew, 0xff), // mask to 1 byte (uint8)
                            // `createdOn` occupies byte positions 1-5 => shift by 8 bits
                            shl(8, and(timestamp, 0xffffffffff)) // mask timestamp to 40 bits
                        ),
                        // `owner` occupies byte positions 11-31 => shift by 88 bits
                        shl(88, noteOwner) // noteOwner already of address type, no need to mask
                    )
                )
            }
            require(outputNoteStatusOld == uint256(NoteStatus.DOES_NOT_EXIST), "output note exists");
        }
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title Library of SafeMath arithmetic operations
 * @author AZTEC
 * Copyright Spilsbury Holdings Ltd 2019. All rights reserved.
 **/

library SafeMath8 {
    
    /**
    * @dev SafeMath multiplication
    * @param a - uint8 multiplier
    * @param b - uint8 multiplicand
    * @return uint8 result of multiplying a and b
    */
    function mul(uint8 a, uint8 b) internal pure returns (uint8) {
        uint256 c = uint256(a) * uint256(b);
        require(c < 256, "uint8 mul triggered integer overflow");
        return uint8(c);
    }

    /**
    * @dev SafeMath division
    * @param a - uint8 dividend
    * @param b - uint8 divisor
    * @return uint8 result of dividing a by b
    */
    function div(uint8 a, uint8 b) internal pure returns (uint8) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // assert(a == b * c + a % b); // There is no case in which this doesn’t hold
        return a / b;
    }

    /**
    * @dev SafeMath subtraction
    * @param a - uint8 minuend
    * @param b - uint8 subtrahend
    * @return uint8 result of subtracting b from a
    */
    function sub(uint8 a, uint8 b) internal pure returns (uint8) {
        require(b <= a, "uint8 sub triggered integer underflow");
        return a - b;
    }

    /**
    * @dev SafeMath addition
    * @param a - uint8 addend
    * @param b - uint8 addend
    * @return uint8 result of adding a and b
    */
    function add(uint8 a, uint8 b) internal pure returns (uint8) {
        uint8 c = a + b;
        require(c >= a, "uint8 add triggered integer overflow");
        return c;
    }
}

/**
 * @title The AZTEC Cryptography Engine
 * @author AZTEC
 * @dev ACE validates the AZTEC protocol's family of zero-knowledge proofs, which enables
 *      digital asset builders to construct fungible confidential digital assets according to the AZTEC token standard.
 * Copyright Spilsbury Holdings Ltd 2019. All rights reserved.
 **/
contract ACE is IAZTEC, Ownable, NoteRegistry {
    using NoteUtils for bytes;
    using ProofUtils for uint24;
    using SafeMath for uint256;
    using SafeMath8 for uint8;

    // keccak256 hash of "JoinSplitSignature(uint24 proof,bytes32 noteHash,uint256 challenge,address sender)"
    bytes32 constant internal JOIN_SPLIT_SIGNATURE_TYPE_HASH =
        0xf671f176821d4c6f81e66f9704cdf2c5c12d34bd23561179229c9fe7a9e85462;
    event SetCommonReferenceString(bytes32[6] _commonReferenceString);
    event SetProof(
        uint8 indexed epoch, 
        uint8 indexed category, 
        uint8 indexed id, 
        address validatorAddress
    );
    event IncrementLatestEpoch(uint8 newLatestEpoch);

    // The commonReferenceString contains one G1 group element and one G2 group element,
    // that are created via the AZTEC protocol's trusted setup. All zero-knowledge proofs supported
    // by ACE use the same common reference string.
    bytes32[6] private commonReferenceString;

    // `validators`contains the addresses of the contracts that validate specific proof types
    address[0x100][0x100][0x10000] public validators;

    // a list of invalidated proof ids, used to blacklist proofs in the case of a vulnerability being discovered
    bool[0x100][0x100][0x10000] public disabledValidators;
    
    // latest proof epoch accepted by this contract
    uint8 public latestEpoch = 1;

    // keep track of validated balanced proofs
    mapping(bytes32 => bool) public validatedProofs;
    
    /**
    * @dev contract constructor. Sets the owner of ACE
    **/
    constructor() public Ownable() {}

    /**
    * @dev Mint AZTEC notes
    *      
    * @param _proof the AZTEC proof object
    * @param _proofData the mint proof construction data
    * @param _proofSender the Ethereum address of the original transaction sender. It is explicitly assumed that
    *        an asset using ACE supplies this field correctly - if they don't their asset is vulnerable to front-running
    * Unnamed param is the AZTEC zero-knowledge proof data
    * @return two `bytes` objects. The first contains the new confidentialTotalSupply note and the second contains the
    * notes that were created. Returned so that a zkAsset can emit the appropriate events
    */
    function mint(
        uint24 _proof,
        bytes calldata _proofData,
        address _proofSender
    ) external returns (bytes memory) {
        
        Registry storage registry = registries[msg.sender];
        require(registry.flags.active == true, "note registry does not exist for the given address");
        require(registry.flags.canAdjustSupply == true, "this asset is not mintable");
        
        // Check that it's a mintable proof
        (, uint8 category, ) = _proof.getProofComponents();

        require(category == uint8(ProofCategory.MINT), "this is not a mint proof");

        bytes memory _proofOutputs = this.validateProof(_proof, _proofSender, _proofData);
        require(_proofOutputs.getLength() > 0, "call to validateProof failed");

        // Dealing with notes representing totals
        (bytes memory oldTotal,  // inputNotesTotal
        bytes memory newTotal, // outputNotesTotal
        ,
        ) = _proofOutputs.get(0).extractProofOutput();

        // Check the previous confidentialTotalSupply, and then assign the new one
        (, bytes32 oldTotalNoteHash, ) = oldTotal.get(0).extractNote();        

        require(oldTotalNoteHash == registry.confidentialTotalMinted, "provided total minted note does not match");
        (, bytes32 newTotalNoteHash, ) = newTotal.get(0).extractNote();
        registry.confidentialTotalMinted = newTotalNoteHash;

        // Dealing with minted notes
        (,
        bytes memory mintedNotes, // output notes
        ,
        ) = _proofOutputs.get(1).extractProofOutput();

        updateOutputNotes(mintedNotes);
        return(_proofOutputs);
    }

    /**
    * @dev Burn AZTEC notes
    *      
    * @param _proof the AZTEC proof object
    * @param _proofData the burn proof construction data
    * @param _proofSender the Ethereum address of the original transaction sender. It is explicitly assumed that
    *        an asset using ACE supplies this field correctly - if they don't their asset is vulnerable to front-running
    * Unnamed param is the AZTEC zero-knowledge proof data
    * @return two `bytes` objects. The first contains the new confidentialTotalSupply note and the second contains the
    * notes that were created. Returned so that a zkAsset can emit the appropriate events
    */
    function burn(
        uint24 _proof,
        bytes calldata _proofData,
        address _proofSender
    ) external returns (bytes memory) {
        
        Registry storage registry = registries[msg.sender];
        require(registry.flags.active == true, "note registry does not exist for the given address");
        require(registry.flags.canAdjustSupply == true, "this asset is not burnable");
        
        // Check that it's a burnable proof
        (, uint8 category, ) = _proof.getProofComponents();

        require(category == uint8(ProofCategory.BURN), "this is not a burn proof");

        bytes memory _proofOutputs = this.validateProof(_proof, _proofSender, _proofData);
        
        // Dealing with notes representing totals
        (bytes memory oldTotal, // input notes
        bytes memory newTotal, // output notes
        ,
        ) = _proofOutputs.get(0).extractProofOutput();
    
        (, bytes32 oldTotalNoteHash, ) = oldTotal.get(0).extractNote();        
        require(oldTotalNoteHash == registry.confidentialTotalBurned, "provided total burned note does not match");
        (, bytes32 newTotalNoteHash, ) = newTotal.get(0).extractNote();
        registry.confidentialTotalBurned = newTotalNoteHash;

        // Dealing with burned notes
        (,
        bytes memory burnedNotes,
        ,) = _proofOutputs.get(1).extractProofOutput();

        // Although they are outputNotes, they are due to be destroyed - need removing from the note registry
        updateInputNotes(burnedNotes);
        return(_proofOutputs);
    }

    /**
    * @dev Validate an AZTEC zero-knowledge proof. ACE will issue a validation transaction to the smart contract
    *      linked to `_proof`. The validator smart contract will have the following interface:
    *      
    *      function validate(
    *          bytes _proofData, 
    *          address _sender, 
    *          bytes32[6] _commonReferenceString
    *      ) public returns (bytes)
    *
    * @param _proof the AZTEC proof object
    * @param _sender the Ethereum address of the original transaction sender. It is explicitly assumed that
    *        an asset using ACE supplies this field correctly - if they don't their asset is vulnerable to front-running
    * Unnamed param is the AZTEC zero-knowledge proof data
    * @return a `bytes proofOutputs` variable formatted according to the Cryptography Engine standard
    */
    function validateProof(uint24 _proof, address _sender, bytes calldata) external returns (bytes memory) {
        require(_proof != 0, "expected the proof to be valid");
        // validate that the provided _proof object maps to a corresponding validator and also that
        // the validator is not disabled
        address validatorAddress = getValidatorAddress(_proof);
        bytes memory proofOutputs;
        assembly {
            // the first evm word of the 3rd function param is the abi encoded location of proof data
            let proofDataLocation := add(0x04, calldataload(0x44))

            // manually construct validator calldata map
            let memPtr := mload(0x40)
            mstore(add(memPtr, 0x04), 0x100) // location in calldata of the start of `bytes _proofData` (0x100)
            mstore(add(memPtr, 0x24), _sender)
            mstore(add(memPtr, 0x44), sload(commonReferenceString_slot))
            mstore(add(memPtr, 0x64), sload(add(0x01, commonReferenceString_slot)))
            mstore(add(memPtr, 0x84), sload(add(0x02, commonReferenceString_slot)))
            mstore(add(memPtr, 0xa4), sload(add(0x03, commonReferenceString_slot)))
            mstore(add(memPtr, 0xc4), sload(add(0x04, commonReferenceString_slot)))
            mstore(add(memPtr, 0xe4), sload(add(0x05, commonReferenceString_slot)))

            // 0x104 because there's an address, the length 6 and the static array items
            let destination := add(memPtr, 0x104)
            // note that we offset by 0x20 because the first word is the length of the dynamic bytes array
            let proofDataSize := add(calldataload(proofDataLocation), 0x20)
            // copy the calldata into memory so we can call the validator contract
            calldatacopy(destination, proofDataLocation, proofDataSize)
            // call our validator smart contract, and validate the call succeeded
            let callSize := add(proofDataSize, 0x104)
            switch staticcall(gas, validatorAddress, memPtr, callSize, 0x00, 0x00)
            case 0 {
                mstore(0x00, 400) revert(0x00, 0x20) // call failed because proof is invalid
            }

            // copy returndata to memory
            returndatacopy(memPtr, 0x00, returndatasize)
            // store the proof outputs in memory
            mstore(0x40, add(memPtr, returndatasize))
            // the first evm word in the memory pointer is the abi encoded location of the actual returned data
            proofOutputs := add(memPtr, mload(memPtr))
        }

        // if this proof satisfies a balancing relationship, we need to record the proof hash
        if (((_proof >> 8) & 0xff) == uint8(ProofCategory.BALANCED)) {
            uint256 length = proofOutputs.getLength();
            for (uint256 i = 0; i < length; i += 1) {
                bytes32 proofHash = keccak256(proofOutputs.get(i));
                bytes32 validatedProofHash = keccak256(abi.encode(proofHash, _proof, msg.sender));
                validatedProofs[validatedProofHash] = true;
            }
        }
        return proofOutputs;
    }

    /**
    * @dev Clear storage variables set when validating zero-knowledge proofs.
    *      The only address that can clear data from `validatedProofs` is the address that created the proof.
    *      Function is designed to utilize [EIP-1283](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1283.md)
    *      to reduce gas costs. It is highly likely that any storage variables set by `validateProof`
    *      are only required for the duration of a single transaction.
    *      E.g. a decentralized exchange validating a swap proof and sending transfer instructions to
    *      two confidential assets.
    *      This method allows the calling smart contract to recover most of the gas spent by setting `validatedProofs`
    * @param _proof the AZTEC proof object
    * @param _proofHashes dynamic array of proof hashes
    */
    function clearProofByHashes(uint24 _proof, bytes32[] calldata _proofHashes) external {
        uint256 length = _proofHashes.length;
        for (uint256 i = 0; i < length; i += 1) {
            bytes32 proofHash = _proofHashes[i];
            require(proofHash != bytes32(0x0), "expected no empty proof hash");
            bytes32 validatedProofHash = keccak256(abi.encode(proofHash, _proof, msg.sender));
            require(validatedProofs[validatedProofHash] == true, "can only clear previously validated proofs");
            validatedProofs[validatedProofHash] = false;
        }
    }

    /**
    * @dev Set the common reference string.
    *      If the trusted setup is re-run, we will need to be able to change the crs
    * @param _commonReferenceString the new commonReferenceString
    */
    function setCommonReferenceString(bytes32[6] memory _commonReferenceString) public {
        require(isOwner(), "only the owner can set the common reference string");
        commonReferenceString = _commonReferenceString;
        emit SetCommonReferenceString(_commonReferenceString);
    }

    /**
    * @dev Forever invalidate the given proof.
    * @param _proof the AZTEC proof object
    */
    function invalidateProof(uint24 _proof) public {
        require(isOwner(), "only the owner can invalidate a proof");
        (uint8 epoch, uint8 category, uint8 id) = _proof.getProofComponents();
        require(validators[epoch][category][id] != address(0x0), "can only invalidate proofs that exist");
        disabledValidators[epoch][category][id] = true;
    }

    /**
    * @dev Validate a previously validated AZTEC proof via its hash
    *      This enables confidential assets to receive transfer instructions from a dApp that
    *      has already validated an AZTEC proof that satisfies a balancing relationship.
    * @param _proof the AZTEC proof object
    * @param _proofHash the hash of the `proofOutput` received by the asset
    * @param _sender the Ethereum address of the contract issuing the transfer instruction
    * @return a boolean that signifies whether the corresponding AZTEC proof has been validated
    */
    function validateProofByHash(
        uint24 _proof,
        bytes32 _proofHash,
        address _sender
    ) public view returns (bool) {
        // We need create a unique encoding of _proof, _proofHash and _sender,
        // and use as a key to access validatedProofs
        // We do this by computing bytes32 validatedProofHash = keccak256(ABI.encode(_proof, _proofHash, _sender))
        // We also need to access disabledValidators[_proof.epoch][_proof.category][_proof.id]
        // This bit is implemented in Yul, as 3-dimensional array access chews through
        // a lot of gas in Solidity, as does ABI.encode
        bytes32 validatedProofHash;
        bool isValidatorDisabled;
        assembly {
            // inside _proof, we have 3 packed variables : [epoch, category, id]
            // each is a uint8.

            // We need to compute the storage key for `disabledValidators[epoch][category][id]`
            // Type of array is bool[0x100][0x100][0x100]
            // Solidity will only squish 32 boolean variables into a single storage slot, not 256
            // => result of disabledValidators[epoch][category] is stored in 0x08 storage slots
            // => result of disabledValidators[epoch] is stored in 0x08 * 0x100 = 0x800 storage slots

            // To compute the storage slot  disabledValidators[epoch][category][id], we do the following:
            // 1. get the disabledValidators slot 
            // 2. add (epoch * 0x800) to the slot (or epoch << 11)
            // 3. add (category * 0x08) to the slot (or category << 3)
            // 4. add (id / 0x20) to the slot (or id >> 5)

            // Once the storage slot has been loaded, we need to isolate the byte that contains our boolean
            // This will be equal to id % 0x20, which is also id & 0x1f

            // Putting this all together. The storage slot offset from '_proof' is...
            // epoch: ((_proof & 0xff0000) >> 16) << 11 = ((_proof & 0xff0000) >> 5)
            // category: ((_proof & 0xff00) >> 8) << 3 = ((_proof & 0xff00) >> 5)
            // id: (_proof & 0xff) >> 5
            // i.e. the storage slot offset = _proof >> 5

            // the byte index of the storage word that we require, is equal to (_proof & 0x1f)
            // to convert to a bit index, we multiply by 8
            // i.e. bit index = shl(3, and(_proof & 0x1f))
            // => result = shr(shl(3, and_proof & 0x1f), value)
            isValidatorDisabled := 
                shr(
                    shl(
                        0x03,
                        and(_proof, 0x1f)
                    ),
                    sload(add(shr(5, _proof), disabledValidators_slot))
                )

            // Next, compute validatedProofHash = keccak256(abi.encode(_proofHash, _proof, _sender))
            // cache free memory pointer - we will overwrite it when computing hash (cheaper than using free memory)
            let memPtr := mload(0x40)
            mstore(0x00, _proofHash)
            mstore(0x20, _proof)
            mstore(0x40, _sender)
            validatedProofHash := keccak256(0x00, 0x60)
            mstore(0x40, memPtr) // restore the free memory pointer
        }
        require(isValidatorDisabled == false, "proof id has been invalidated");
        return validatedProofs[validatedProofHash];
    }

    /**
    * @dev Adds or modifies a proof into the Cryptography Engine.
    *       This method links a given `_proof` to a smart contract validator.
    * @param _proof the AZTEC proof object
    * @param _validatorAddress the address of the smart contract validator
    */
    function setProof(
        uint24 _proof,
        address _validatorAddress
    ) public {
        require(isOwner(), "only the owner can set a proof");
        require(_validatorAddress != address(0x0), "expected the validator address to exist");
        (uint8 epoch, uint8 category, uint8 id) = _proof.getProofComponents();
        require(epoch <= latestEpoch, "the proof epoch cannot be bigger than the latest epoch");
        require(validators[epoch][category][id] == address(0x0), "existing proofs cannot be modified");
        validators[epoch][category][id] = _validatorAddress;
        emit SetProof(epoch, category, id, _validatorAddress);
    }

    /**
     * @dev Increments the `latestEpoch` storage variable.
     */
    function incrementLatestEpoch() public {
        require(isOwner(), "only the owner can update the latest epoch");
        latestEpoch = latestEpoch.add(1);
        emit IncrementLatestEpoch(latestEpoch);
    }

    /**
    * @dev Returns the common reference string.
    * We use a custom getter for `commonReferenceString` - the default getter created by making the storage
    * variable public indexes individual elements of the array, and we want to return the whole array
    */
    function getCommonReferenceString() public view returns (bytes32[6] memory) {
        return commonReferenceString;
    }

    function getValidatorAddress(uint24 _proof) public view returns (address validatorAddress) {
        bool isValidatorDisabled;
        bool queryInvalid;
        assembly {
            // To compute the storage key for validatorAddress[epoch][category][id], we do the following:
            // 1. get the validatorAddress slot 
            // 2. add (epoch * 0x10000) to the slot
            // 3. add (category * 0x100) to the slot
            // 4. add (id) to the slot
            // i.e. the range of storage pointers allocated to validatorAddress ranges from
            // validatorAddress_slot to (0xffff * 0x10000 + 0xff * 0x100 + 0xff = validatorAddress_slot 0xffffffff)

            // Conveniently, the multiplications we have to perform on epoch, category and id correspond
            // to their byte positions in _proof.
            // i.e. (epoch * 0x10000) = and(_proof, 0xffff0000)
            // and  (category * 0x100) = and(_proof, 0xff00)
            // and  (id) = and(_proof, 0xff)

            // Putting this all together. The storage slot offset from '_proof' is...
            // (_proof & 0xffff0000) + (_proof & 0xff00) + (_proof & 0xff)
            // i.e. the storage slot offset IS the value of _proof
            validatorAddress := sload(add(_proof, validators_slot))
            queryInvalid := or(iszero(validatorAddress), isValidatorDisabled)
        }

        // wrap both require checks in a single if test. This means the happy path only has 1 conditional jump
        if (queryInvalid) {
            require(validatorAddress != address(0x0), "expected the validator address to exist");
            require(isValidatorDisabled == false, "expected the validator address to not be disabled");
        }
    }
}

/**
 * @title ZkAsset Interface
 * @author AZTEC
 * @dev An interface defining the ZkAsset standard 
 * Copyright Spilsbury Holdings Ltd 2019. All rights reserved.
 **/

contract IZkAsset {

    event CreateZkAsset(
        address indexed aceAddress,
        address indexed linkedTokenAddress,
        uint256 scalingFactor,
        bool indexed _canAdjustSupply,
        bool _canConvert
    );
    event CreateNoteRegistry(uint256 noteRegistryId);
    event CreateNote(address indexed owner, bytes32 indexed noteHash, bytes metadata);
    event DestroyNote(address indexed owner, bytes32 indexed noteHash, bytes metadata);
    event ConvertTokens(address indexed owner, uint256 value);
    event RedeemTokens(address indexed owner, uint256 value);
    event UpdateNoteMetadata(address indexed owner, bytes32 indexed noteHash, bytes metadata);
    
    function confidentialApprove(
        bytes32 _noteHash,
        address _spender,
        bool _status,
        bytes calldata _signature
    ) external;

    function confidentialTransferFrom(uint24 _proof, bytes calldata _proofOutput) external;
    
    function confidentialTransfer(bytes memory _proofData, bytes memory _signatures) public;
}

/**
 * @title Library of EIP712 utility constants and functions
 * @author AZTEC
 * Copyright Spilsbury Holdings Ltd 2019. All rights reserved.
 **/
contract LibEIP712 {

    // EIP712 Domain Name value
    string constant internal EIP712_DOMAIN_NAME = "AZTEC_CRYPTOGRAPHY_ENGINE";

    // EIP712 Domain Version value
    string constant internal EIP712_DOMAIN_VERSION = "1";

    // Hash of the EIP712 Domain Separator Schema
    bytes32 constant internal EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH = keccak256(abi.encodePacked(
        "EIP712Domain(",
            "string name,",
            "string version,",
            "address verifyingContract",
        ")"
    ));

    // Hash of the EIP712 Domain Separator data
    // solhint-disable-next-line var-name-mixedcase
    bytes32 public EIP712_DOMAIN_HASH;

    constructor ()
        public
    {
        EIP712_DOMAIN_HASH = keccak256(abi.encode(
            EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH,
            keccak256(bytes(EIP712_DOMAIN_NAME)),
            keccak256(bytes(EIP712_DOMAIN_VERSION)),
            address(this)
        ));
    }

    /// @dev Calculates EIP712 encoding for a hash struct in this EIP712 Domain.
    /// @param _hashStruct The EIP712 hash struct.
    /// @return EIP712 hash applied to this EIP712 Domain.
    function hashEIP712Message(bytes32 _hashStruct)
        internal
        view
        returns (bytes32 _result)
    {
        bytes32 eip712DomainHash = EIP712_DOMAIN_HASH;

        // Assembly for more efficient computing:
        // keccak256(abi.encodePacked(
        //     EIP191_HEADER,
        //     EIP712_DOMAIN_HASH,
        //     hashStruct
        // ));

        assembly {
            // Load free memory pointer. We're not going to use it - we're going to overwrite it!
            // We need 0x60 bytes of memory for this hash,
            // cheaper to overwrite the free memory pointer at 0x40, and then replace it, than allocating free memory
            let memPtr := mload(0x40)
            mstore(0x00, 0x1901)               // EIP191 header
            mstore(0x20, eip712DomainHash)     // EIP712 domain hash
            mstore(0x40, _hashStruct)          // Hash of struct
            _result := keccak256(0x1e, 0x42)   // compute hash
            // replace memory pointer
            mstore(0x40, memPtr)
        }
    }

    /// @dev Extracts the address of the signer with ECDSA.
    /// @param _message The EIP712 message.
    /// @param _signature The ECDSA values, v, r and s.
    /// @return The address of the message signer.
    function recoverSignature(
        bytes32 _message,
        bytes memory _signature
    ) internal view returns (address _signer) {
        bool result;
        assembly {
            // Here's a little trick we can pull. We expect `_signature` to be a byte array, of length 0x60, with
            // 'v', 'r' and 's' located linearly in memory. Preceeding this is the length parameter of `_signature`.
            // We *replace* the length param with the signature msg to get a memory block formatted for the precompile

            // load length as a temporary variable
            let byteLength := mload(_signature)

            // store the signature message
            mstore(_signature, _message)

            // load 'v' - we need it for a condition check
            let v := mload(add(_signature, 0x20))

            result := and(
                and(
                    // validate signature length == 0x60 bytes
                    eq(byteLength, 0x60),
                    // validate v == 27 or v == 28
                    or(eq(v, 27), eq(v, 28))
                ),
                // validate call to precompile succeeds
                staticcall(gas, 0x01, _signature, 0x80, _signature, 0x20)
            )
            // save the _signer only if the first word in _signature is not `_message` anymore
            switch eq(_message, mload(_signature))
            case 0 {
                _signer := mload(_signature)
            }
            mstore(_signature, byteLength) // and put the byte length back where it belongs
        }
        // wrap Failure States in a single if test, so that happy path only has 1 conditional jump
        if (!(result && (_signer == address(0x0)))) {
            require(_signer != address(0x0), "signer address cannot be 0");
            require(result, "signature recovery failed");
        }
    }
}

/**
 * @title ZkAssetBase
 * @author AZTEC
 * @dev A contract defining the standard interface and behaviours of a confidential asset.
 * The ownership values and transfer values are encrypted.
 * Copyright Spilbury Holdings Ltd 2019. All rights reserved.
 **/
contract ZkAssetBase is IZkAsset, IAZTEC, LibEIP712 {
    using NoteUtils for bytes;
    using SafeMath for uint256;

    /**
    * Note struct. This is the data that we store when we log AZTEC notes inside a NoteRegistry
    *
    * Data structured so that the entire struct fits in 1 storage word.
    *
    * @notice Yul is used to pack and unpack Note structs in storage for efficiency reasons,
    *   see `NoteRegistry.updateInputNotes` and `NoteRegistry.updateOutputNotes` for more details
    **/
    struct Note {
        // `status` uses the IAZTEC.NoteStatus enum to track the lifecycle of a note.
        uint8 status;

        // `createdOn` logs the timestamp of the block that created this note. There are a few
        // use cases that require measuring the age of a note, (e.g. interest rate computations).
        // These lifetime are relevant on timescales of days/months, the 900-ish seconds that a miner
        // can manipulate a timestamp has little effect, but should be considered when utilizing this parameter.
        // We store `createdOn` in 5 bytes of data - just in case this contract is still around in 2038 :)
        // This kicks the 'year 2038' problem down the road by about 400 years
        uint40 createdOn;

        // `destroyedOn` logs the timestamp of the block that destroys this note in a transaction.
        // Default value is 0x0000000000 for notes that have not been spent.
        uint40 destroyedOn;

        // The owner of the note
        address owner;
    }

    // EIP712 Domain Name value
    string constant internal EIP712_DOMAIN_NAME = "ZK_ASSET";

    // EIP712 Domain Version value
    string constant internal EIP712_DOMAIN_VERSION = "1";

    bytes32 constant internal NOTE_SIGNATURE_TYPEHASH = keccak256(abi.encodePacked(
        "NoteSignature(",
            "bytes32 noteHash,",
            "address spender,",
            "bool status",
        ")"
    ));
    
    bytes32 constant internal JOIN_SPLIT_SIGNATURE_TYPE_HASH = keccak256(abi.encodePacked(
        "JoinSplitSignature(",
            "uint24 proof,",
            "bytes32 noteHash,",
            "uint256 challenge,",
            "address sender",
        ")"
    ));

    ACE public ace;
    IERC20 public linkedToken;

    uint256 public scalingFactor;
    mapping(bytes32 => mapping(address => bool)) public confidentialApproved;

    constructor(
        address _aceAddress,
        address _linkedTokenAddress,
        uint256 _scalingFactor,
        bool _canAdjustSupply
    ) public {
        bool canConvert = (_linkedTokenAddress == address(0x0)) ? false : true;
        EIP712_DOMAIN_HASH = keccak256(abi.encodePacked(
            EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH,
            keccak256(bytes(EIP712_DOMAIN_NAME)),
            keccak256(bytes(EIP712_DOMAIN_VERSION)),
            bytes32(uint256(address(this)))
        ));
        ace = ACE(_aceAddress);
        linkedToken = IERC20(_linkedTokenAddress);
        scalingFactor = _scalingFactor;
        ace.createNoteRegistry(
            _linkedTokenAddress,
            _scalingFactor,
            _canAdjustSupply,
            canConvert
        );
        emit CreateZkAsset(
            _aceAddress,
            _linkedTokenAddress,
            _scalingFactor,
            _canAdjustSupply,
            canConvert
        );
    }
    
    /**
    * @dev Executes a basic unilateral, confidential transfer of AZTEC notes
    * Will submit _proofData to the validateProof() function of the Cryptography Engine.
    *
    * Upon successfull verification, it will update note registry state - creating output notes and
    * destroying input notes.
    *
    * @param _proofData - bytes variable outputted from a proof verification contract, representing
    * transfer instructions for the ACE
    * @param _signatures - array of the ECDSA signatures over all inputNotes 
    */
    function confidentialTransfer(bytes memory _proofData, bytes memory _signatures) public {
        bytes memory proofOutputs = ace.validateProof(JOIN_SPLIT_PROOF, msg.sender, _proofData);
        confidentialTransferInternal(proofOutputs, _signatures, _proofData);
    }

    /**
    * @dev Note owner approving a third party, another address, to spend the note on
    * owner's behalf. This is necessary to allow the confidentialTransferFrom() method
    * to be called
    *
    * @param _noteHash - keccak256 hash of the note coordinates (gamma and sigma)
    * @param _spender - address being approved to spend the note
    * @param _status - defines whether the _spender address is being approved to spend the
    * note, or if permission is being revoked
    * @param _signature - ECDSA signature from the note owner that validates the
    * confidentialApprove() instruction
    */
    function confidentialApprove(
        bytes32 _noteHash,
        address _spender,
        bool _status,
        bytes memory _signature
    ) public {
        ( uint8 status, , , ) = ace.getNote(address(this), _noteHash);
        require(status == 1, "only unspent notes can be approved");
        bytes32 _hashStruct = keccak256(abi.encode(
                NOTE_SIGNATURE_TYPEHASH,
                _noteHash,
                _spender,
                status
        ));

        validateSignature(_hashStruct, _noteHash, _signature);
        confidentialApproved[_noteHash][_spender] = _status;
    }

    /**
    * @dev Perform ECDSA signature validation for a signature over an input note
    * 
    * @param _hashStruct - the data to sign in an EIP712 signature
    * @param _noteHash - keccak256 hash of the note coordinates (gamma and sigma)
    * @param _signature - ECDSA signature for a particular input note 
    */
    function validateSignature(
        bytes32 _hashStruct,
        bytes32 _noteHash,
        bytes memory _signature
    ) internal view {
        (, , , address noteOwner ) = ace.getNote(address(this), _noteHash);

        address signer;
        if (_signature.length != 0) {
            // validate EIP712 signature
            bytes32 msgHash = hashEIP712Message(_hashStruct);
            signer = recoverSignature(
                msgHash,
                _signature
            );
        } else {
            signer = msg.sender;
        }
        require(signer == noteOwner, "the note owner did not sign this message");
    }

    /**
    * @dev Extract the appropriate ECDSA signature from an array of signatures,
    * 
    * @param _signatures - array of ECDSA signatures over all inputNotes 
    * @param _i - index used to determine which signature element is desired
    */
    function extractSignature(bytes memory _signatures, uint _i) internal pure returns (
        bytes memory _signature
    ){
        bytes32 v;
        bytes32 r;
        bytes32 s;
        assembly {
            // memory map of signatures
            // 0x00 - 0x20 : length of signature array
            // 0x20 - 0x40 : first sig, v 
            // 0x40 - 0x60 : first sig, r 
            // 0x60 - 0x80 : first sig, s
            // 0x80 - 0xa0 : second sig, v
            // and so on...
            // Length of a signature = 0x60
            
            v := mload(add(add(_signatures, 0x20), mul(_i, 0x60)))
            r := mload(add(add(_signatures, 0x40), mul(_i, 0x60)))
            s := mload(add(add(_signatures, 0x60), mul(_i, 0x60)))
        }
        _signature = abi.encode(v, r, s);
    }

    /**
    * @dev Executes a value transfer mediated by smart contracts. The method is supplied with
    * transfer instructions represented by a bytes _proofOutput argument that was outputted
    * from a proof verification contract.
    *
    * @param _proof - uint24 variable which acts as a unique identifier for the proof which
    * _proofOutput is being submitted. _proof contains three concatenated uint8 variables:
    * 1) epoch number 2) category number 3) ID number for the proof
    * @param _proofOutput - output of a zero-knowledge proof validation contract. Represents
    * transfer instructions for the ACE
    */
    function confidentialTransferFrom(uint24 _proof, bytes memory _proofOutput) public {
        (bytes memory inputNotes,
        bytes memory outputNotes,
        address publicOwner,
        int256 publicValue) = _proofOutput.extractProofOutput();
        
        uint256 length = inputNotes.getLength();
        for (uint i = 0; i < length; i += 1) {
            (, bytes32 noteHash, ) = inputNotes.get(i).extractNote();
            require(
                confidentialApproved[noteHash][msg.sender] == true,
                "sender does not have approval to spend input note"
            );
        }

        ace.updateNoteRegistry(_proof, _proofOutput, msg.sender);

        logInputNotes(inputNotes);
        logOutputNotes(outputNotes);

        if (publicValue < 0) {
            emit ConvertTokens(publicOwner, uint256(-publicValue));
        }
        if (publicValue > 0) {
            emit RedeemTokens(publicOwner, uint256(publicValue));
        }
    }

    /**
    * @dev Internal method to act on transfer instructions from a successful proof validation. 
    * Specifically, it:
    * - extracts the relevant objects from the proofOutput object
    * - validates an EIP712 signature over each input note
    * - updates note registry state
    * - emits events for note creation/destruction
    * - converts or redeems tokens, according to the publicValue
    * 
    * @param proofOutputs - transfer instructions from a zero-knowledege proof validator 
    * contract
    * @param _signatures - ECDSA signatures over a set of input notes
    * @param _proofData - cryptographic proof data outputted from a proof construction 
    * operation
    */
    function confidentialTransferInternal(
        bytes memory proofOutputs,
        bytes memory _signatures,
        bytes memory _proofData
    ) internal {
        bytes32 _challenge;
        assembly {
            _challenge := mload(add(_proofData, 0x40))
        }

        for (uint i = 0; i < proofOutputs.getLength(); i += 1) {
            bytes memory proofOutput = proofOutputs.get(i);
            ace.updateNoteRegistry(JOIN_SPLIT_PROOF, proofOutput, address(this));
            
            (bytes memory inputNotes,
            bytes memory outputNotes,
            address publicOwner,
            int256 publicValue) = proofOutput.extractProofOutput();

 
            if (inputNotes.getLength() > uint(0)) {
                
                for (uint j = 0; j < inputNotes.getLength(); j += 1) {
                    bytes memory _signature = extractSignature(_signatures, j);

                    (, bytes32 noteHash, ) = inputNotes.get(j).extractNote();

                    bytes32 hashStruct = keccak256(abi.encode(
                        JOIN_SPLIT_SIGNATURE_TYPE_HASH,
                        JOIN_SPLIT_PROOF,
                        noteHash,
                        _challenge,
                        msg.sender
                    ));

                    validateSignature(hashStruct, noteHash, _signature);
                }
            }

            logInputNotes(inputNotes);
            logOutputNotes(outputNotes);
            if (publicValue < 0) {
                emit ConvertTokens(publicOwner, uint256(-publicValue));
            }
            if (publicValue > 0) {
                emit RedeemTokens(publicOwner, uint256(publicValue));
            }

        }
    }

    /**
    * @dev Update the metadata of a note that already exists in storage. 
    * @param noteHash - hash of a note, used as a unique identifier for the note
    * @param metadata - metadata to update the note with. This should be the length of
    * an IES encrypted viewing key, 0x177
    */
    function updateNoteMetaData(bytes32 noteHash, bytes calldata metadata) external {
        // Get the note from this assets registry
        ( uint8 status, , , address noteOwner ) = ace.getNote(address(this), noteHash);
        require(status == 1, "only unspent notes can be approved");

        // There should be a permission lock here requiring that only the noteOwner can call
        // this function. It has been deliberately removed on a short term basis
        emit UpdateNoteMetadata(noteOwner, noteHash, metadata);
    }

    /**
    * @dev Emit events for all input notes, which represent notes being destroyed
    * and removed from the note registry
    *
    * @param inputNotes - input notes being destroyed and removed from note registry state
    */
    function logInputNotes(bytes memory inputNotes) internal {
        for (uint i = 0; i < inputNotes.getLength(); i += 1) {
            (address noteOwner, bytes32 noteHash, bytes memory metadata) = inputNotes.get(i).extractNote();
            emit DestroyNote(noteOwner, noteHash, metadata);
        }
    }

    /**
    * @dev Emit events for all output notes, which represent notes being created and added
    * to the note registry
    *
    * @param outputNotes - outputNotes being created and added to note registry state
    */
    function logOutputNotes(bytes memory outputNotes) internal {
        for (uint i = 0; i < outputNotes.getLength(); i += 1) {
            (address noteOwner, bytes32 noteHash, bytes memory metadata) = outputNotes.get(i).extractNote();
            emit CreateNote(noteOwner, noteHash, metadata);
        }
    }
}

/**
 * @title ZkAsset
 * @author AZTEC
 * @dev A contract defining the standard interface and behaviours of a confidential asset.
 * The ownership values and transfer values are encrypted.
 * Copyright Spilsbury Holdings Ltd 2019. All rights reserved.
 **/
contract ZkAsset is ZkAssetBase {

    constructor(
        address _aceAddress,
        address _linkedTokenAddress,
        uint256 _scalingFactor
    ) public ZkAssetBase(
        _aceAddress,
        _linkedTokenAddress,
        _scalingFactor,
        false // Can adjust supply
    ) {
    }
}

contract TestZkAsset is ZkAsset {

}