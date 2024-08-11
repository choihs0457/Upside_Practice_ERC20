// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../lib/forge-std/src/Test.sol";
import "../src/ERC20.sol";

contract UpsideTokenTest is Test {
    address internal alice;
    address internal bob;

    uint256 internal alicePK;
    uint256 internal bobPK;

    ERC20 upside_token;

    function setUp() public {
        upside_token = new ERC20("UPSIDE", "UPS");

        alicePK = 0xa11ce;
        alice = vm.addr(alicePK);

        bobPK = 0xb0b;
        bob = vm.addr(bobPK);
        emit log_address(alice);
        emit log_address(bob);

        upside_token.transfer(alice, 50 ether);
        upside_token.transfer(bob, 50 ether);
    }
    
    function testPermit() public {
        bytes32 structHash = keccak256(abi.encode(
            keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"), 
            alice, 
            address(this), 
            10 ether, 
            0, 
            1 days
            ));
        bytes32 hash = upside_token._toTypedDataHash(structHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePK, hash);

        assertEq(upside_token.nonces(alice), 0);
        upside_token.permit(alice, address(this), 10 ether, 1 days, v, r, s);

        assertEq(upside_token.allowance(alice, address(this)), 10 ether);
        assertEq(upside_token.nonces(alice), 1);
    }

    function testFailExpiredPermit() public {
        bytes32 hash = keccak256(abi.encode(
            keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"), 
            alice, 
            address(this), 
            10 ether, 
            0, 
            1 days
            ));
        bytes32 digest = upside_token._toTypedDataHash(hash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePK, digest);

        vm.warp(1 days + 1 seconds);

        upside_token.permit(alice, address(this), 10 ether, 1 days, v, r, s);
    }

    function testFailInvalidSigner() public {
        bytes32 hash = keccak256(abi.encode(
            keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"), 
            alice, 
            address(this), 
            10 ether, 
            0, 
            1 days
            ));
        bytes32 digest = upside_token._toTypedDataHash(hash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(bobPK, digest);

        upside_token.permit(alice, address(this), 10 ether, 1 days, v, r, s);
    }

    function testFailInvalidNonce() public {
        bytes32 hash = keccak256(abi.encode(
            keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"), 
            alice, 
            address(this), 
            10 ether, 
            1, 
            1 days
            ));
        bytes32 digest = upside_token._toTypedDataHash(hash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePK, digest);

        upside_token.permit(alice, address(this), 10 ether, 1 days, v, r, s);
    }

    function testReplay() public {
        bytes32 hash = keccak256(abi.encode(
            keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"), 
            alice, 
            address(this), 
            10 ether, 
            0, 
            1 days
            ));
        bytes32 digest = upside_token._toTypedDataHash(hash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePK, digest);

        upside_token.permit(alice, address(this), 10 ether, 1 days, v, r, s);
        vm.expectRevert("INVALID_SIGNER");
        upside_token.permit(alice, address(this), 10 ether, 1 days, v, r, s);
    }


}