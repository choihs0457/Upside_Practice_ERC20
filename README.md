# 문제 1: QuizGame 컨트랙트 구현하기

## 접근

- 표준을 기준으로 공부하고 작성

## 후기

- 표준에 대한 공부가 좀 됐다 WEB3OJ의 ERC20부분과 ERC721부분을 풀고 있었어서 재밌고 공부가 많이 됐다.

## 코드

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERC20 {
    mapping(address account => uint256) private _balances;                                  // 해당 주소의 금액
    mapping(address account => mapping(address spender => uint256)) private _allowances;    // 특정 주소에서 특정 주소에게 사용이 허가된 금액
    mapping(address => uint256) private _nonces;                                            // 증가 될 nonce

    uint256 private _totalSupply;                                                           // 총 발핼된 토큰
    address private _owner;                                                                 // 토큰의 owner

    string private _name;                                                                   // 토큰 이름
    string private _symbol;                                                                 // 토큰 심볼
    bool private _paused;                                                                   // puase의 상태값

    bytes32 private constant _PERMIT_TYPEHASH = keccak256(
        "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    );                                                                                      // 표준에서 정의된 타입해시 값
    bytes32 private _DOMAIN_SEPARATOR;                                                      // 데이터가 어떤 스마트 컨트랙에 귀속되어 있는지 알려주는 값

    /*
    제공받은 name_과 symbol_을 가지고 토큰을 발행하고 가진 정보들을 가지고 _DOMAIN_SEPARATOR를 세팅
    function _buildDomainSeparator() private view returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, _hashedName, _hashedVersion, block.chainid, address(this)));
    }
    */
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
    
    /*
    토큰을 발행하는 함수 내부 호출만 가능하고 constructor에서만 호출하기에 한 번만 민팅가능(해당 토큰 내에서는)
    */
    function mint(address account_, uint256 amount_) internal {
        _totalSupply += amount_;
        _balances[account_] += amount_;
    }

    /*
    modifier
    onlyOwner = 토큰을 발행한 사람만이 실행 가능
    whenNotPaused = pause상태가 아닐 때 만 실행이 가능하도록 검증
    ballanceCheck = 요청자의 잔고가 요청값 이상 있는지 검증
    */
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

    /*
    pause기능을 수행 할 함수들
    */
    function pause() external onlyOwner {
        _paused = true;
    }
    function unpause() external onlyOwner {
        _paused = false;
    }


    /*
    전송을 담당하는 함수들 차이라면 From은 allowance가 있어야 가능하고 가스비의 부담을 호출자가 한다.
    */
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

    /*
    자신의 밸런스를 일정량 만큼 사용 가능 하도록 허용하는 함수(approve)와 해당 금액을 확인하는 함수(allowance)
    */
    function approve(address spender_, uint256 value_) external whenNotPaused returns (bool) {
        _allowances[msg.sender][spender_] = value_;
        return true;
    }
    function allowance(address owner_, address spender_) external view returns (uint256) {
        return _allowances[owner_][spender_];
    }

    /*
    hash를 구하는 부분이 기본은 bytes32 hash = _hashTypedDataV4(structHash); 이다
    _hashTypedDataV4 = MessageHashUtils.toTypedDataHash(_domainSeparatorV4(), structHash) 이기 때문에
    이렇게 압축됐다.
    */
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

    /*
    트랜잭션시 증가 될 nonce값
    */
    function nonces(address owner_) external view returns (uint256) {
        return _nonces[owner_];
    }

}