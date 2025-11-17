// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";


contract Xcoin is ERC20, ERC1155 {

    address owner;

    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 10**18;

    structNFT[] public storeNFT;
    structCollection[] public storeCollectionNFT;

    struct structNFT {
        uint256 id;
        string name;
        string description;
        string imgPath;
        uint256 price;
        uint256 quanity;
        uint256 creationDate;
    }

    struct structCollection {
        uint256 id;
        string name;
        string description;
        uint256 price;
        structNFT[] NFTInCollection;
        uint256 creationDate;
    }

    struct structUser {
        string nameUser;
        string referalCode;
        uint256 discont;
    }

    struct structBet {
        address ownerBet;
        uint256 priceBet;
    }

    struct structAction {
        uint256 id;
        structCollection collection;
        uint256 minPrice;
        uint256 timeStart;
        uint256 timeEnd;
    }

    mapping (uint256 => structNFT) public NFT;
    mapping (uint256 => structCollection) public collectionNFT;

    mapping (address => structNFT[]) public userNFT;
    mapping (address => structCollection[]) public userCollection;

    mapping (address => structUser) public user;

  constructor() ERC20("Xcoin", "X") ERC1155("./images/") {

        ERC20._mint(owner, 1000000);

        user[owner] = structUser("Owner", "XCoinReferal31415", 0);

        // user[0x70997970C51812dc3A010C7d01b50e0d17dc79C8] = structUser("Tom", "PROFI3C442024", 0);
        // ERC20._transfer(owner, 0x70997970C51812dc3A010C7d01b50e0d17dc79C8, 200000);

        // user[0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC] = structUser("Max", "PROFI90F72024", 0);
        // ERC20._transfer(owner, 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC, 300000);

        // user[0x90F79bf6EB2c4f870365E785982E1f101E93b906] = structUser("Jack", "PROFI15d32024", 0);
        // ERC20._transfer(owner, 0x90F79bf6EB2c4f870365E785982E1f101E93b906, 400000);

        // remix
        user[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2] = structUser("Tom", "PROFI4B202024", 0);
        ERC20._transfer(owner, 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, 200_000);

        user[0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db] = structUser("Max", "PROFI78732024", 0);
        ERC20._transfer(owner, 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db, 300_000);

        user[0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB] = structUser("Jack", "PROFI617F2024", 0);
        ERC20._transfer(owner, 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB, 400_000);
    }

}
