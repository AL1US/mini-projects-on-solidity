// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract Xcoin is ERC20, ERC1155 {
    address owner;

    uint public unicueNFT; // Своего рода id для nft и коллекций
    uint public unicueCollectionNFT;

    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 10 ** 18; // количество всех токенов в системе

    structNFTsInSomething[] public storeNFT; // Массив магазина
    structNFTsInSomething[] public storeCollectionNFT; // Такой же массив как и сверху

    struct structNFT {
        uint256 id;
        string name;
        string description;
        string imgPath;
        uint256 price;
        uint256 quanity;
        uint256 creationDate;
    }

    // Структура, для того чтобы можно было только по id и количеству помещать NFT в магазин, коллекцию или аукцион
    struct structNFTsInSomething {
        uint256 id;
        address owner;
        uint256 amount;
        uint256 price; // При добавлении в коллекцию не указывается, только если мы добавляем в магазин
    }

    struct structCollectionNFT {
        uint256 id;
        string name;
        string description;
        uint256 price;
        structNFTsInSomething[] NFTInCollection;
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
    mapping(uint256 => structNFT) public NFT;
    mapping(uint256 => structCollectionNFT) public collectionNFTs;

    // Для того чтобы понять чем владеет юзер, ну вернее для утобного отображения
    mapping(address => structNFT[]) public userNFTs;
    mapping(address => structCollectionNFT[]) public userCollectionsNFTs;

    // Данные юзера
    mapping(address => structUser) public user;

    // Работа с коллекциями
    mapping(uint256 => address) public owner_collection;

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not owner");
        _;
    }

    // Геттер на данные юзера
    function getProfile()
        public
        view
        returns (structUser memory _user, uint256 _balance)
    {
        _user = user[msg.sender];
        _balance = balanceOf(msg.sender);
    }

    // Геттеры на NFT
    // Геттер на NFT которые есть у юзера в массиве ( нужно для проверку того, что юзер действительно ими владеет)
    function getNFTUser(
        address _addressOwnerNFT,
        uint256 _index
    ) public view returns (structNFT memory) {
        require(
            _index <= userNFTs[_addressOwnerNFT].length,
            "Not found this NFT"
        );

        return userNFTs[_addressOwnerNFT][_index];
    }

    function getMyAllNFT() public view returns (structNFT[] memory) {
        return userNFTs[msg.sender];
    }

    // Просто геттер на NFT по id
    function getNFTForId(uint256 _id) public view returns (structNFT memory) {
        return NFT[_id];
    }

    //  Геттеры на коллекции
    function getCollection(
        uint256 _id
    ) public view returns (structCollectionNFT memory) {
        return collectionNFTs[_id];
    }

    // Геттер на то, что есть в магазине NFT
    function getStoreNFTForIndex(uint256 _index) public view returns (structNFTsInSomething memory) {
        require(_index <= storeNFT.length);
        return storeNFT[_index];
    }

    // Геттер на весь магазин NFT
    function getAllNFTInStore() public view returns (structNFTsInSomething[] memory) {
        return storeNFT;
    }

    // Геттер на коллекцию в магазине по индексу
    function getStoreCollectionForIndex(uint256 _index) public view returns (structNFTsInSomething memory) {
        require(_index < storeCollectionNFT.length, "Index out of bounds"); // < а не <= !
        return storeCollectionNFT[_index];
    }

    // Весь магазин коллекций
    function getAllCollectionsInStore() public view returns (structNFTsInSomething[] memory) {
        return storeCollectionNFT;
    }

   
    // Сеттер на NFT
    function setNFT(
        string memory _name,
        string memory _description,
        string memory _imgPath,
        uint256 _amount
    ) public {
        _mint(msg.sender, unicueNFT, _amount, "");

        // Пуш в мапинг нфт, которыми владеет юзер
        userNFTs[msg.sender].push(
            structNFT(
                unicueNFT,
                _name,
                _description,
                _imgPath,
                0, // Цена указывается после того, как нфт идёт в продажу
                _amount,
                block.timestamp
            )
        );

        // Добавление в мапинг всех нфт, просто чтобы можно было легко понять сколько их и тп
        NFT[unicueNFT] = structNFT(
            unicueNFT,
            _name,
            _description,
            _imgPath,
            0,
            _amount,
            block.timestamp
        );

        unicueNFT++;
    }

    // Сеттер на коллекцию
    function setCollection(
        string memory _name,
        string memory _description
    ) public {
        collectionNFTs[unicueCollectionNFT] = structCollectionNFT(
            unicueCollectionNFT,
            _name,
            _description,
            0,
            new structNFTsInSomething[](0),
            false,
            block.timestamp
        );

        owner_collection[unicueCollectionNFT] = msg.sender;

        unicueCollectionNFT++;
    }

    //  Сеттер на добавление NFT в коллекцию
    function setNFTInCollection(
        uint256 _unicueCollectionNFT,
        uint256 _unicueNFT,
        uint256 _amount
    ) public {
        require(
            owner_collection[_unicueCollectionNFT] == msg.sender,
            "You are not owner this collection"
        );
        require(_amount > 0, "Amount must be > 0");

        bool found = false;
        uint256 foundIndex = 0;

        for (uint256 i = 0; i < userNFTs[msg.sender].length; i++) {
            if (userNFTs[msg.sender][i].id == _unicueNFT) {
                if (userNFTs[msg.sender][i].quanity >= _amount) {
                    found = true;
                    foundIndex = i;
                    break; // нашли - выходим
                }
            }
        }

        require(found, "NFT not found");

        userNFTs[msg.sender][foundIndex].quanity -= _amount;

        collectionNFTs[_unicueCollectionNFT].NFTInCollection.push(
            structNFTsInSomething(_unicueNFT, msg.sender, _amount, 0)
        );
    }

    // Работа с магазином
    // По сути эта функция уже есть в контракте, но там нужно вводить адрес и всё такое, а тут сразу кнопка
    function approveForContract() public {
        setApprovalForAll(address(this), true);
    }

    function setNFTInStore(
        uint256 _id,
        uint256 _amount,
        uint256 _price
    ) public {
        bool found = false;
        uint256 foundIndex = 0;
        bytes memory data = "";


        for (uint256 i = 0; i < userNFTs[msg.sender].length; i++) {
            if (userNFTs[msg.sender][i].id == _id) {
                if (userNFTs[msg.sender][i].quanity >= _amount) {
                    found = true;
                    foundIndex = i;
                    break;
                }
            }
        }

        require(found, "NFT not found");

        safeTransferFrom(msg.sender, address(this), _id, _amount, data);

        userNFTs[msg.sender][foundIndex].quanity -= _amount;

        storeNFT.push(
            structNFTsInSomething(
                userNFTs[msg.sender][foundIndex].id,
                msg.sender,
                _amount,
                _price
            )
        );
    }

    function cancelNFTSale(uint256 _tokenId) public {
        for (uint256 i = 0; i < storeNFT.length; i++) {
            if (storeNFT[i].id == _tokenId && storeNFT[i].owner == msg.sender) {
                
                uint256 amount = storeNFT[i].amount;

                // Возвращаем NFT
                _safeTransferFrom(address(this), msg.sender, _tokenId, amount, "");

                // Возвращаем количество NFT юзеру
                for (uint256 j = 0; j < userNFTs[msg.sender].length; j++) {
                    if (userNFTs[msg.sender][j].id == _tokenId) {
                        userNFTs[msg.sender][j].quanity += amount;
                        break;
                    }
                }

                // Удаляем
                storeNFT[i] = storeNFT[storeNFT.length - 1];
                storeNFT.pop();
                break;
            }
        }
    }

    // Добавить коллекцию в магазин
    function setCollectionInStore(
        uint256 _id,
        uint256 _amount,
        uint256 _price
    ) public {
        require(collectionNFTs[_id].id == _id, "Collection not found");
        require(owner_collection[_id] == msg.sender, "You are not owner");
        require(_amount > 0, "Amount must be > 0");
        require(!collectionNFTs[_id].state, "Already in store");

        collectionNFTs[_id].state = true;
        collectionNFTs[_id].price = _price; 

        storeCollectionNFT.push(
            structNFTsInSomething(
                _id,
                msg.sender,
                _amount,
                _price
            )
        );
    }

    function cancelCollectionSale(uint256 _collectionId) public {
        for (uint256 i = 0; i < storeCollectionNFT.length; i++) {
            if (storeCollectionNFT[i].id == _collectionId && storeCollectionNFT[i].owner == msg.sender) {
                
                collectionNFTs[_collectionId].state = false; // true -> in store / false -> not in store. Можно сделать так
                                                             // потомучто у нас нет колличества на коллекциях                                            
                storeCollectionNFT[i] = storeCollectionNFT[storeCollectionNFT.length - 1];
                storeCollectionNFT.pop();
                break;
            }
        }
    }

    // Покупка NFT
    function buyNFT(uint256 _index, uint256 _amount) public payable {
        
        uint256 priceToken = storeNFT[_index].price * _amount;
        address ownerToken = storeNFT[_index].owner;
        uint256 amountNFT = storeNFT[_index].amount;
        bytes memory data = "";

        require(balanceOf(msg.sender) >= priceToken, "Not enough Xcoin");
        require(amountNFT >= _amount, "Incorect amount");
        require(ownerToken != msg.sender, "The token owner cannot buy his NFT");

        transfer(ownerToken, priceToken);

        safeTransferFrom(address(this), msg.sender, storeNFT[_index].id, _amount, data);

        storeNFT[_index].amount -= _amount;

        if (storeNFT[_index].amount == 0) {
            storeNFT[_index] = storeNFT[storeNFT.length - 1];
            storeNFT.pop();
        }
    }
    // Покупка коллекции
    function buyCollection(uint256 _collectionId) public {

        uint256 storeIndex = 0;
        for (uint256 i = 0; i < storeCollectionNFT.length; i++) {
            if (storeCollectionNFT[i].id == _collectionId) {
                storeIndex = i;
                break;
            }
        }
        require(storeIndex < storeCollectionNFT.length, "Collection not in store");

        address seller = storeCollectionNFT[storeIndex].owner;
        uint256 price = storeCollectionNFT[storeIndex].price;

        require(seller != msg.sender, "Cannot buy own collection");
        require(balanceOf(msg.sender) >= price, "Not enough Xcoin");


        _transfer(msg.sender, seller, price);

        structCollectionNFT storage col = collectionNFTs[_collectionId];

        // хренатень чтобы передать все нфт из коллекции
        for (uint256 j = 0; j < col.NFTInCollection.length; j++) {
            _safeTransferFrom(
                address(this),
                msg.sender,
                col.NFTInCollection[j].id,
                col.NFTInCollection[j].amount,
                ""
            );
        }

        // Так как продавец больше не владелец, надо удалить его коллекцию
        for (uint256 k = 0; k < userCollectionsNFTs[seller].length; k++) {
            if (userCollectionsNFTs[seller][k].id == _collectionId) {
                userCollectionsNFTs[seller][k] = userCollectionsNFTs[seller][userCollectionsNFTs[seller].length - 1];
                userCollectionsNFTs[seller].pop();
                break;
            }
        }
        // пушим юзеру его только что купленную коллекцию
        userCollectionsNFTs[msg.sender].push(col);

        // Обновляем владельца
        owner_collection[_collectionId] = msg.sender;
        col.state = false;
        col.price = 0;

        // Удаляем из магазина
        storeCollectionNFT[storeIndex] = storeCollectionNFT[storeCollectionNFT.length - 1];
        storeCollectionNFT.pop();
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


        user[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2] = structUser(
            "Tom",
            "PROFI4B202024",
            0
        );
        ERC20._transfer(
            owner,
            0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
            200_000
        );

        user[0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db] = structUser(
            "Max",
            "PROFI78732024",
            0
        );
        ERC20._transfer(
            owner,
            0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,
            300_000
        );

        user[0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB] = structUser(
            "Jack",
            "PROFI617F2024",
            0
        );
        ERC20._transfer(
            owner,
            0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB,
            400_000
        );
    }
}   
