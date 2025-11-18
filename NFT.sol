// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";


contract Xcoin is ERC20, ERC1155 {

    address owner;

    uint public unicueNFT; // Своего рода id для nft и коллекций на следующей строке
    uint public unicueCollectionNFT; 

    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 10**18; // количество всех токенов в системе

    structNFT[] public storeNFT; // Массив в который будет со временем помещать нфт, он выступает в роли магазина
    structCollectionNFT[] public storeCollectionNFT; // Такой же массив как и сверху


    struct structNFT {
        uint256 id;
        string name;
        string description;
        string imgPath;
        uint256 price;
        uint256 quanity;
        bool state; // Нужн для того чтобы понять на продаже он или нет
        uint256 creationDate;
    }

    struct structCollectionNFT {
        uint256 id;
        string name;
        string description;
        uint256 price;
        uint256[] NFTInCollection;
        uint256[] amountNFTInCollection;
        bool state;
        uint256 creationDate;
    }

    struct structUser {
        string nameUser;
        string referalCode;
        uint256 discont; // Процент скидки
    }

    // Структура для ставки на аукционе
    struct structBet {
        address ownerBet;
        uint256 priceBet;
    }

    // Структура на аукционе
    struct structAction {
        uint256 id;
        structCollectionNFT collection;
        uint256 minPrice;
        uint256 timeStart;
        uint256 timeEnd;
    }

    // Для отображения nft и коллекций по id(unicueNFT) 
    mapping (uint256 => structNFT) public NFT;
    mapping (uint256 => structCollectionNFT) public collectionNFTs;

    // Для того чтобы понять чем владеет юзер, ну вернее для утобного отображения
    mapping (address => structNFT[]) public userNFTs;
    mapping (address => structCollectionNFT[]) public userCollectionsNFTs;

    // Данные юзера
    mapping (address => structUser) public user;

    // Работа с коллекциями
    mapping (uint256 => address) public owner_collection;


    modifier onlyOwner() {
        require(msg.sender == owner, "You are not owner");
        _;
    }

    // Геттер на данные юзера
    function getProfile() public view returns(structUser memory _user, uint256 _balance) {
        _user = user[msg.sender];
        _balance = balanceOf(msg.sender);
    } 

    // Геттеры на NFT
    function getNFTUser(address _addressOwnerNFT, uint256 _index) public view returns(structNFT memory) {

        structNFT[] memory userTokens = userNFTs[_addressOwnerNFT];

        require(_index < userTokens.length, "Not found this NFT");

        return userTokens[_index];
    }

    function getMyAllNFT() public view returns(structNFT[] memory) {
        return userNFTs[msg.sender];
    }

    function getMyNFTForIndex(uint256 _index) public view returns(structNFT memory) {
        structNFT[] memory myNFT = userNFTs[msg.sender];

        require(_index < myNFT.length, "Not found this NFT");

        return myNFT[_index];
    }


    //  Геттеры на коллекции
    function getCollection(uint256 _id) public view returns(structCollectionNFT memory){
        structCollectionNFT memory collection = collectionNFTs[_id];

        return collection;

    
    }

    // Сеттер на NFT
    function setNFT(
        string memory _name,
        string memory _description,
        string memory _imgPath,
        uint256 _amount
        ) public onlyOwner {

        _mint(
            msg.sender,
            unicueNFT,
            _amount,
            ""
        );

        unicueNFT ++;

        userNFTs[msg.sender].push(structNFT(
            unicueNFT,
            _name,
            _description,
            _imgPath,
            0, // Цена указывается после того, как нфт идёт в продажу 
            _amount,
            false,
            block.timestamp
        ));
    }

    // Сеттер на коллекцию
    function setCollection(string memory _name, string memory _description) public {
        collectionNFTs[unicueCollectionNFT] = structCollectionNFT(
            unicueCollectionNFT,
            _name,
            _description,
            0,
            new uint[](0),
            new uint[](0),
            false,
            block.timestamp
        );

        owner_collection[unicueCollectionNFT] = msg.sender;

        unicueCollectionNFT ++;
    }

    constructor() ERC20("Xcoin", "X") ERC1155("./images/") {

        owner = msg.sender;
        ERC20._mint(owner, INITIAL_SUPPLY); // Адрес владельца токенов и количество токенов 
        user[owner] = structUser("Owner", "XCoinReferal31415", 0);

        // hardhat
        // user[0x70997970C51812dc3A010C7d01b50e0d17dc79C8] = structUser("Tom", "PROFI3C442024", 0);
        // ERC20._transfer(owner, 0x70997970C51812dc3A010C7d01b50e0d17dc79C8, 200_000);

        // user[0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC] = structUser("Max", "PROFI90F72024", 0);
        // ERC20._transfer(owner, 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC, 300_000);

        // user[0x90F79bf6EB2c4f870365E785982E1f101E93b906] = structUser("Jack", "PROFI15d32024", 0);
        // ERC20._transfer(owner, 0x90F79bf6EB2c4f870365E785982E1f101E93b906, 400_000);

        // remix
        user[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2] = structUser("Tom", "PROFI4B202024", 0);
        ERC20._transfer(owner, 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, 200_000);

        user[0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db] = structUser("Max", "PROFI78732024", 0);
        ERC20._transfer(owner, 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db, 300_000);

        user[0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB] = structUser("Jack", "PROFI617F2024", 0);
        ERC20._transfer(owner, 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB, 400_000);
    }

}
