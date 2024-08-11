// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERC20 {
    mapping(address account => uint256) private _balances;
    mapping(address account => mapping(address spender => uint256)) private _allowances;
    mapping(address => uint256) private _nonces;

    uint256 private _totalSupply;
    address private _owner;

    string private _name;
    string private _symbol;
    bool private _paused;

    bytes32 private constant _PERMIT_TYPEHASH = keccak256(
        "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    );
    bytes32 private _DOMAIN_SEPARATOR;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _owner = msg.sender;

        _DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name_)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );

        mint(msg.sender, 2000000000 ether);

    }
    
    function mint(address account_, uint256 amount_) internal {
        _totalSupply += amount_;
        _balances[account_] += amount_;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not Owner");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused, "Contract Paused");
        _;
    }
    modifier ballanceCheck(uint256 value_) {
        require(_balances[msg.sender] >= value_, "Balance Error");
        _;
    }

    function pause() external onlyOwner {
        _paused = true;
    }

    function unpause() external onlyOwner {
        _paused = false;
    }


    function transfer(address to_, uint256 value_) external whenNotPaused ballanceCheck(value_) returns (bool) {

        _balances[msg.sender] -= value_;
        _balances[to_] += value_;

        return true;
    }

    function transferFrom(address from_, address to_, uint256 value_) external whenNotPaused ballanceCheck(value_) returns (bool) {
        require(_allowances[from_][msg.sender] >= value_, "Allowance Ballance Error");
        _balances[from_] -= value_;
        _balances[to_] += value_;
        _allowances[from_][msg.sender] -= value_;
        return true;
    }

    function approve(address spender_, uint256 value_) external whenNotPaused returns (bool) {
        _allowances[msg.sender][spender_] = value_;
        return true;
    }

    function allowance(address owner_, address spender_) external view returns (uint256) {
        return _allowances[owner_][spender_];
    }

    function _toTypedDataHash(bytes32 structHash_) external view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _DOMAIN_SEPARATOR, structHash_));
    }

    function permit(
        address owner_,
        address spender_,
        uint256 value_,
        uint256 deadline_,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external whenNotPaused {
        require(deadline_ >= block.timestamp, "Deadline Expired");

        bytes32 _structHash = keccak256(
            abi.encode(
                _PERMIT_TYPEHASH,
                owner_,
                spender_,
                value_,
                _nonces[owner_],
                deadline_
            )
        );

        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", _DOMAIN_SEPARATOR, _structHash));
        address _signer = ecrecover(hash, v, r, s);
        require(_signer == owner_, "INVALID_SIGNER");

        _nonces[owner_]++;
        _allowances[owner_][spender_] = value_;
    }

    function nonces(address owner_) external view returns (uint256) {
        return _nonces[owner_];
    }

}