// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract Xcoin is ERC20, ERC1155, ERC1155Holder{


    /*
    * ПЕРЕМЕННЫЕ
    */ 

    address owner;
    
    // Своего рода id для nft и коллекций
    uint public unicueNFT; 
    uint public unicueCollectionNFT;

    uint256 public indexNFTInStore;
    uint256 public unicueCollectionNFTInStore;

    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 10 ** 18; // количество всех токенов в системе

    /*
    * STRUCT
    */

    struct structUser {
        string nameUser;
        string referalCode;
        uint256 discont; // Процент скидки
    }

    // Для того чтобы можно было помещать nft в коллекцию
    struct structNFTsInCollection {
        uint256 id;
        uint256 amount; 
    }

    // Обычные nft
    struct structNFT {
        uint256 id;
        string name;
        string description;
        string imgPath;
        uint256 price; // Заполняется только после помещения в магазин
        uint256 amount; // Также выступает в роли проверки существования nft
        uint256 creationDate;
    }

    // Коллекции. По сути это просто метаданные, которые ни как не влияют на обычные nft, но благодоря коллекциями
    // nft можно объединять, опять же только по метаданным, на сами nft по токену это не как не влияет
    struct structCollectionNFT {
        uint256 id;
        string name;
        string description;
        uint256 price; // Заполняется только после помещения в магазин
        structNFTsInCollection[] NFTInCollection;
        bool state; // Нужно для того чтобы понять в магазине или нет
        bool existence; // Нужно для проверки того, есть ли такая коллекция у юзера
        uint256 creationDate;
    }

    /*
    * structSTORE
    */

    // Для того чтобы не засорять магазин ненужными данными, можно создать структуру только с теми данными
    // которые будет нам нужны

    struct structNFTsInStore {
        uint256 id;
        address owner;
        uint256 amount;
        uint256 price;
    }

    struct structCollectionInStore {
        uint256 id;
        address owner;
        uint256 price;
    }

    /*
    * MAPPING
    */ 

    // Используются именно мапинги, а не массивы, для того чтобы не нагружать контракт циклами,
    // для оптимизации использования газа, и легкости контрактка (кода соответсвтенно становится меньше)

    mapping(address => mapping(uint256 => structNFT)) public NFT;
    mapping(address => mapping(uint256 => structCollectionNFT)) public collectionNFTs;

    // Используется для того, чтобы понять какие вобще nft существют. Особенно помогает когда юзер
    // Покупает nft после чего, к нему в мапинг его nft можно просто и удобно добавить по id его куплленный. 
    mapping(uint256 => structNFT) public allNFT;
    mapping(uint256 => structCollectionNFT) public allCollection;

    mapping(address => structUser) public user;

    /*
    * mapping STORE
    */ 

    mapping(uint256 => structNFTsInStore) public storeNFT; // index => struct
    mapping(uint256 => structCollectionInStore) public storeCollectionNFT;


    /*
    * GET
    */

    // Геттер nft по id 
    function getNFT(uint256 _id) public view returns(structNFT memory) {
        return NFT[msg.sender][_id];
    }

    // Геттер коллекции по id
    function getCollection(uint256 _id) public view returns(structCollectionNFT memory) {
        return collectionNFTs[msg.sender][_id];
    }

    /*
    * GET STORE
    */ 

    // Геттер nft в магазине по индексу
    function getStoreNFT(uint256 _index) public view returns (structNFTsInStore memory) {
        return storeNFT[_index];
    }
    // get col in store
    function getColNFT(uint256 _index) public view returns (structCollectionInStore memory) {
        return storeCollectionNFT[_index];
    }
    
    // Создать nft
    function setNFT(
        string memory _name,
        string memory _description,
        string memory _imgPath,
        uint256 _amount
    ) public {

        _mint(msg.sender, unicueNFT, _amount, ""); // Создание nft в системе. Последний параметр принимает комментарий

        // Добавление в мапинг юзера
        NFT[msg.sender][unicueNFT] = structNFT(
            unicueNFT,
            _name,
            _description,
            _imgPath,
            0,
            _amount,
            block.timestamp
        );

        // Добавление в мапинг всех NFT
        allNFT[unicueNFT] = structNFT(
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

    // Создать коллекцию
    function setCollection(
        string memory _name,
        string memory _description
    ) public {
        collectionNFTs[msg.sender][unicueCollectionNFT] = structCollectionNFT(
            unicueCollectionNFT,
            _name,
            _description,
            0, // цена указывается после выставления её на продажу
            new structNFTsInCollection[](0), // нужно для id и количства
            false, // в магазине -> true / не в магазине -> false
            true, // Означет, что коллекция существует
            block.timestamp
        );

        // Добавление в мапинг всех коллекций
        allCollection[unicueCollectionNFT] = structCollectionNFT(
            unicueCollectionNFT,
            _name,
            _description,
            0,
            new structNFTsInCollection[](0),
            false, 
            true, 
            block.timestamp
        );

        unicueCollectionNFT++;
    }

    // Добавить nft в коллекцию
    function setNFTInCollection(
        uint256 _idCollection,
        uint256 _idNFT,
        uint256 _amount
    ) public {
        // Проверка на то есть ли NFT у юзера
        require(NFT[msg.sender][_idNFT].amount >= _amount, "You don't have this NFT");
        require(collectionNFTs[msg.sender][_idCollection].existence, "You don't have this collection");
        require(!collectionNFTs[msg.sender][_idCollection].state, "Collection already in store");

        require(_amount > 0, "Amount must be > 0");

        // Добавление выбраннх nft в коллекцию
        collectionNFTs[msg.sender][_idCollection].NFTInCollection.push(
            structNFTsInCollection(_idNFT, _amount)
        );

        // вычитаем все добавленные nft
        NFT[msg.sender][_idNFT].amount -= _amount;

        // Если nft у юзера закончились, то мы удаляем их
        if (NFT[msg.sender][_idNFT].amount == 0) {
            delete NFT[msg.sender][_idNFT];
        }
    }

    /*
    * SET STORE
    */

    // Добавить nft в магазин по id
    function setNFTInStore(uint256 _id, uint256 _amount, uint256 _price) public {
        require(NFT[msg.sender][_id].amount >= _amount, "You don't have this NFT");
        require(_amount > 0, "Amount must be > 0");
        require(isApprovedForAll(msg.sender, address(this)), "Please approve the marketplace");

        bytes memory data = "";

        // Добавлем в мапинг
        storeNFT[indexNFTInStore] = structNFTsInStore(
            _id,
            msg.sender,
            _amount,
            _price
        );

        // Переводим наши нфт контракту. Что-то типа листинга. Реализуется в main
        safeTransferFrom(msg.sender, address(this), _id, _amount, data);
        // safeTransferFrom(from, to, id, value, data);

        // вычитаем все добавленные nft
        NFT[msg.sender][_id].amount -= _amount;

        // Если nft у юзера закончились, то мы удаляем их
        if (NFT[msg.sender][_id].amount == 0) {
            delete NFT[msg.sender][_id];
        }

        indexNFTInStore ++;
    }

    // Покупка nft по id.                                                   
    function buyNFT(uint256 _index, uint256 _amount) public payable {

        uint256 _id = storeNFT[_index].id;

        structNFT memory myNewNFT = allNFT[_id];
        uint256 priceNFT = storeNFT[_index].price * _amount;
        uint256 amountNFT = storeNFT[_index].amount;
        address ownerNFT = storeNFT[_index].owner;
        bytes memory data = "";

        require(storeNFT[_index].owner != msg.sender, "The owner of the nft cannot buy it from himself");
        require(balanceOf(msg.sender) >= priceNFT, "You dot't have ehougn Xcoin");
        require(amountNFT >= _amount, "Your chosen amount increases the number of tokens in the store.");
        require(amountNFT != 0, "This nft does not exist");
        require(balanceOf(address(this), _id) >= _amount, "Contract don't have this NFTs");

        // перевод токенов овнеру nft
        transfer(ownerNFT, priceNFT);

        // перевод самих nft
        _safeTransferFrom(address(this), msg.sender, _id, _amount, data);

        // вычитание _amount из amount
        storeNFT[_index].amount -= _amount;

        // Если такой nft уже есть у юзера, то мы добавляем просто цифорки к количеству его nft
        if (NFT[msg.sender][_id].amount > 0) {
            NFT[msg.sender][_id].amount += _amount;
        } else {
            NFT[msg.sender][_id] = myNewNFT;
            NFT[msg.sender][_id].amount = _amount;
        }

        // if amount in store == 0 -> del this nft 
        if (storeNFT[_index].amount == 0) {
            delete storeNFT[_index];
        }

    }

    function setCollectionInStore(uint256 _id, uint256 _price) public {

        require(collectionNFTs[msg.sender][_id].existence, "You don't have this collection");
        require(!collectionNFTs[msg.sender][_id].state, "Collection already in store");
        require(isApprovedForAll(msg.sender, address(this)), "Please approve the marketplace");

        // Создаём объект для удобной работы с ним
        structNFTsInCollection[] storage col = collectionNFTs[msg.sender][_id].NFTInCollection;
        require(col.length > 0, "Collection is empty");

        // Собираем массивы для batch transfer
        uint256[] memory ids = new uint256[](col.length);
        uint256[] memory amounts = new uint256[](col.length);

        for (uint256 i = 0; i < col.length; i++) {
            ids[i] = col[i].id;
            amounts[i] = col[i].amount;
        }

        // Передаём всю коллекцию контракту
        safeBatchTransferFrom(msg.sender, address(this), ids, amounts, "");

        // Сохраняем коллекцию в магазин
        storeCollectionNFT[unicueCollectionNFTInStore] = structCollectionInStore(
            _id,
            msg.sender,
            _price
        );

        // Отмечаем что она в магазине
        collectionNFTs[msg.sender][_id].state = true;

        unicueCollectionNFTInStore++;
    }

    function buyCollection(uint256 _index) public payable {
        // Достаём данные из магазина
        structCollectionInStore memory colStore = storeCollectionNFT[_index];
        
        address ownerCol = colStore.owner;
        uint256 idCol = colStore.id;
        uint256 price = colStore.price;

        // Достаём данные о коллекции в мапинге всех коллекций
        structCollectionNFT memory myNewCollection = allCollection[idCol];
        
        require(ownerCol != address(0), "Collection does not exist");
        require(ownerCol != msg.sender, "Owner cannot buy own collection");
        require(balanceOf(msg.sender) >= price, "Not enough Xcoin");

        // Перевод денег владельцу
        transfer(ownerCol, price);

        // Достаём nft внутри коллекции
        structNFTsInCollection[] storage col = collectionNFTs[ownerCol][idCol].NFTInCollection;

        uint256[] memory ids = new uint256[](col.length);
        uint256[] memory amounts = new uint256[](col.length);

        for (uint256 i = 0; i < col.length; i++) {
            ids[i] = col[i].id;
            amounts[i] = col[i].amount;
        }

        // Перевод NFT с контракта покупателю
        safeBatchTransferFrom(address(this), msg.sender, ids, amounts, "");

        // Передаём коллекцию покупателю
        collectionNFTs[msg.sender][idCol] = myNewCollection;

        // Удаляем коллекцию у прошлого владельца
        delete collectionNFTs[ownerCol][idCol];

        // Удаляем коллекцию из магазина
        delete storeCollectionNFT[_index];
    }

    // Эта штука как то решает проблему с тем, что этот контракт не может принимать nft
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC1155Holder)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
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

        setNFT("myNFT0", "desc", "imgPath", 10);
        setNFT("myNFT1", "desc", "imgPath", 10);
        setNFT("myNFT2", "desc", "imgPath", 10);
        setNFT("myNFT3", "desc", "imgPath", 10);

        setCollection("myCol0", "description");
        setCollection("myCol1", "description");
        setNFTInCollection(0, 2, 5); // id col, id nft, amount
        setNFTInCollection(1, 3, 3);

        setApprovalForAll(address(this), true); // берём душу овнера в рабство без его согласия
        setNFTInStore(1, 5, 50); // id, amount, price

        setCollectionInStore(0, 15); // id коллекции, price
    }
}
