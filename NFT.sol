// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract Contract is ERC20, ERC1155, ERC1155Holder{

    /*
    * ПЕРЕМЕННЫЕ
    */ 

    address owner;
    
    // Своего рода id для nft и коллекций
    uint256 public unicueNFT; 
    uint256 public unicueCollectionNFT;

    uint256 public indexNFTInStore;
    uint256 public unicueCollectionNFTInStore;

    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 10 ** 18; // количество всех токенов в системе

    uint256 public indexNFTAuction;
    uint256 public indexCollectionAuction;

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
    * structSTORE and AUCTION
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
        structNFTsInCollection[] NFTInCollection;
        uint256 price;
    }

    // Струкутры аукциона
    struct structAuctionNFT {
        uint256 id;
        address ownerAuction;
        uint256 idNFT;
        uint256 amount;
        uint256 timeStart;
        uint256 timeEND;
        uint256 minBet;
    }

    struct structAuctionCollection {
        uint256 id;
        address ownerAuction;
        uint256 idCollection;
        uint256 amount;
        uint256 timeStart;
        uint256 timeEND;
        uint256 minBet;
    }


    struct structBet {
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
    // mapping(uint256 => structCollectionNFT) public allCollection;

    mapping(address => structUser) public user;

    /*
    * mapping STORE and AUCTION
    */ 

    mapping(uint256 => structNFTsInStore) public storeNFT; // index => struct
    mapping(uint256 => structCollectionInStore) public storeCollectionNFT;

    // аукцион со ставкой
    mapping(uint256 => structAuctionNFT) public auctionNFT;
    mapping(uint256 => structBet) public betNFT;

    mapping(uint256 => structAuctionCollection) public auctionCollection;
    mapping(uint256 => structBet) public betCollection;


    /*
    * GET
    */

    // получить информацию о моём профиле
    function getUser() public view returns(structUser memory) {
        return user[msg.sender];
    }
    
    // Геттер nft по id 
    function getNFT(uint256 _id) public view returns(structNFT memory) {
        return NFT[msg.sender][_id];
    }

    // Получить все nft юзера
    function getMyAllNFTs() public view returns(structNFT[] memory) {
        uint256 count = 0;
        
        // Запоминаем сколько всего nft у юзера
        for (uint256 i = 0; i < unicueNFT; i++) {
            if (NFT[msg.sender][i].amount > 0) {
                count++;
            }
        }
        // Создаём массив с тем количеством ячеек сколько всего нфт у юзера, в который будем класть нфт
        structNFT[] memory NFTs = new structNFT[](count);

        // По этому индексу кладём в массив найденные нфт
        uint256 index = 0;

        for (uint256 i = 0; i < unicueNFT; i++) {
            if (NFT[msg.sender][i].amount > 0) {
                NFTs[index] = NFT[msg.sender][i]; // Кладём нфт в массив, если они существуют
                index++;
            }
        }

        return NFTs;
    }

    // Геттер коллекции по id
    function getCollection(uint256 _id) public view returns(structCollectionNFT memory) {
        return collectionNFTs[msg.sender][_id];
    }

    // Все коллекции
    function getMyCollections() public view returns (structCollectionNFT[] memory) {
        uint256 count = 0;

        for (uint256 i = 0; i < unicueCollectionNFT; i++) {
            if (collectionNFTs[msg.sender][i].existence) {
                count++;
            }
        }

        structCollectionNFT[] memory result = new structCollectionNFT[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < unicueCollectionNFT; i++) {
            if (collectionNFTs[msg.sender][i].existence) {
                result[index] = collectionNFTs[msg.sender][i];
                index++;
            }
        }

        return result;
    }

    /*
    * GET STORE
    */ 

    // Геттер nft в магазине по индексу
    function getStoreNFT(uint256 _index) public view returns (structNFTsInStore memory) {
        return storeNFT[_index];
    }

    function getAllStoreNFTs() public view returns (structNFTsInStore[] memory) {
        uint256 count = 0;

        for (uint256 i = 0; i < indexNFTInStore; i++) {
            if (storeNFT[i].amount > 0) {
                count++;
            }
        }

        structNFTsInStore[] memory result = new structNFTsInStore[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < indexNFTInStore; i++) {
            if (storeNFT[i].amount > 0) {
                result[index] = storeNFT[i];
                index++;
            }
        }

        return result;
    }

    // get col in store
    function getCollectionInStore(uint256 _index) public view returns (structCollectionInStore memory) {
        return storeCollectionNFT[_index];
    }

    // Все коллекции в магазине
    function getAllStoreCollections() public view returns (structCollectionInStore[] memory) {
        uint256 count = 0;

        for (uint256 i = 0; i < unicueCollectionNFTInStore; i++) {
            if (storeCollectionNFT[i].owner != address(0)) {
                count++;
            }
        }

        structCollectionInStore[] memory result = new structCollectionInStore[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < unicueCollectionNFTInStore; i++) {
            if (storeCollectionNFT[i].owner != address(0)) {
                result[index] = storeCollectionNFT[i];
                index++;
            }
        }

        return result;
    }

    // get auction NFT
    function getAuctionNFT(uint256 _index) public view returns(structAuctionNFT memory) {
        return auctionNFT[_index];
    }

    // Получить все активные аукционы NFT
    function getAllAuctionNFTs() public view returns (structAuctionNFT[] memory) {
        uint256 count = 0;

        // Считаем, сколько аукционов существует
        for (uint256 i = 0; i < indexNFTAuction; i++) {
            if (auctionNFT[i].ownerAuction != address(0)) {
                count++;
            }
        }

        // Создаём массив нужного размера
        structAuctionNFT[] memory auctions = new structAuctionNFT[](count);
        uint256 index = 0;

        // Заполняем массив
        for (uint256 i = 0; i < indexNFTAuction; i++) {
            if (auctionNFT[i].ownerAuction != address(0)) {
                auctions[index] = auctionNFT[i];
                index++;
            }
        }

        return auctions;
    }


    // get auction collection
    function getAuctionCollection(uint256 _index) public view returns(structAuctionCollection memory) {
        return auctionCollection[_index];
    }

    // Получить все аукционы коллекций
    function getAllAuctionCollections() public view returns (structAuctionCollection[] memory) {
        uint256 count = 0;

        // Считаем, сколько аукционов коллекций существует
        for (uint256 i = 0; i < indexCollectionAuction; i++) {
            if (auctionCollection[i].ownerAuction != address(0)) {
                count++;
            }
        }

        // Создаём массив нужного размера
        structAuctionCollection[] memory auctions = new structAuctionCollection[](count);
        uint256 index = 0;

        // Заполняем массив
        for (uint256 i = 0; i < indexCollectionAuction; i++) {
            if (auctionCollection[i].ownerAuction != address(0)) {
                auctions[index] = auctionCollection[i];
                index++;
            }
        }

        return auctions;
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

        structNFTsInCollection[] storage col = collectionNFTs[msg.sender][_id].NFTInCollection;
        require(col.length > 0, "Collection is empty");

        uint256[] memory ids = new uint256[](col.length);
        uint256[] memory amounts = new uint256[](col.length);

        for (uint256 i = 0; i < col.length; i++) {
            ids[i] = col[i].id;
            amounts[i] = col[i].amount;
        }

        safeBatchTransferFrom(msg.sender, address(this), ids, amounts, "");

        // Сохраняем коллекцию в магазин
        structCollectionInStore storage s = storeCollectionNFT[unicueCollectionNFTInStore];
        s.id = _id;
        s.owner = msg.sender;
        s.price = _price;

        for (uint256 i = 0; i < col.length; i++) {
            s.NFTInCollection.push(col[i]);
        }

        collectionNFTs[msg.sender][_id].state = true;
        unicueCollectionNFTInStore++;
    }

    function buyCollection(uint256 _index) public payable {
        // Достаём данные из магазина
        structCollectionInStore storage colStore = storeCollectionNFT[_index];

        address ownerCol = colStore.owner;
        uint256 idCol = colStore.id;
        uint256 price = colStore.price;

        require(ownerCol != address(0), "Collection does not exist");
        require(ownerCol != msg.sender, "Owner cannot buy own collection");
        require(balanceOf(msg.sender) >= price, "Not enough Xcoin");

        // Перевод денег владельцу
        transfer(ownerCol, price);

        // Берём NFT из магазина
        structNFTsInCollection[] storage col = colStore.NFTInCollection;

        uint256[] memory ids = new uint256[](col.length);
        uint256[] memory amounts = new uint256[](col.length);

        for (uint256 i = 0; i < col.length; i++) {
            ids[i] = col[i].id;
            amounts[i] = col[i].amount;
        }

        // Перевод NFT с контракта покупателю
        _safeBatchTransferFrom(address(this), msg.sender, ids, amounts, "");

        // Передаём коллекцию покупателю, копируя структуру владельца
        structCollectionNFT storage newCol = collectionNFTs[ownerCol][idCol];
        collectionNFTs[msg.sender][idCol] = newCol;
        collectionNFTs[msg.sender][idCol].state = false;      // больше не в магазине
        collectionNFTs[msg.sender][idCol].existence = true;   // у нового владельца существует

        // Удаляем коллекцию у прошлого владельца
        delete collectionNFTs[ownerCol][idCol];

        // Удаляем коллекцию из магазина
        delete storeCollectionNFT[_index];
    }

    /*
    * SET AUCTION
    */

    function setAuctionNFT(uint256 _idNFT, uint256 _minBet, uint256 _endAuction, uint256 _amount) public {
        require(NFT[msg.sender][_idNFT].amount >= _amount, "You don't have this NFT");
        require(_amount > 0, "Amount must be > 0");
        require(isApprovedForAll(msg.sender, address(this)), "Please approve the marketplace");

        bytes memory data = "";

        // Добавлем в мапинг
        auctionNFT[indexNFTAuction] = structAuctionNFT(
            indexNFTAuction,
            msg.sender,
            _idNFT,
            _amount,
            block.timestamp,
            block.timestamp + _endAuction,
            _minBet
        );

        // Переводим наши нфт контракту. Что-то типа листинга. Реализуется в main
        safeTransferFrom(msg.sender, address(this), _idNFT, _amount, data);
        // safeTransferFrom(from, to, id, value, data);

        // вычитаем все добавленные nft
        NFT[msg.sender][_idNFT].amount -= _amount;

        // Если nft у юзера закончились, то мы удаляем их
        if (NFT[msg.sender][_idNFT].amount == 0) {
            delete NFT[msg.sender][_idNFT];
        }

        indexNFTAuction ++;

    }

    // Ставка аукциона по id                                               
    function setBetNFT(uint256 _index, uint256 _betAmount) public payable {

        structAuctionNFT storage auc = auctionNFT[_index];

        require(auc.ownerAuction != address(0), "Auction does not exist");
        require(block.timestamp < auc.timeEND, "Auction has ended");
        require(msg.sender != auc.ownerAuction, "You cannot bid on your own auction");
        require(_betAmount >= auc.minBet, "Bet is below min bet");
        require(balanceOf(msg.sender) >= _betAmount, "Not enough Xcoin");

        structBet storage bet = betNFT[_index];

        // Ставка должна быть выше
        require(_betAmount > bet.price, "Your bid must be higher than current bid");

        // Возврат предыдущей ставки (если она была)
        if (bet.price > 0) {
            transfer(bet.owner, bet.price);
        }

        // Снимаем деньги с нового юзера
        _transfer(msg.sender, address(this), _betAmount);

        // Записываем новую ставку
        betNFT[_index] = structBet(
            msg.sender,
            _betAmount
        );
    }

    function finishAuctionNFT(uint256 _index) public {
        structAuctionNFT storage auc = auctionNFT[_index];
        structBet storage lastBet = betNFT[_index];

        require(block.timestamp >= auc.timeEND, "Auction is not finished");
        require(auc.ownerAuction != address(0), "Auction does not exist");
        
        // Получатель
        address recipient;
        if (lastBet.price == 0) {
            // Нет ставок, возвращаем NFT владельцу
            _safeTransferFrom(address(this), auc.ownerAuction, auc.idNFT, auc.amount, "");
            recipient = auc.ownerAuction;
        } else {
            // Покупатель получает NFT
            _safeTransferFrom(address(this), lastBet.owner, auc.idNFT, auc.amount, "");
            transfer(auc.ownerAuction, lastBet.price);
            recipient = lastBet.owner;
        }

        // Обновляем мапинг у получателя
        structNFT memory nftData = allNFT[auc.idNFT];
        if (NFT[recipient][auc.idNFT].amount > 0) {
            NFT[recipient][auc.idNFT].amount += auc.amount;
        } else {
            NFT[recipient][auc.idNFT] = nftData;
            NFT[recipient][auc.idNFT].amount = auc.amount;
        }

        // Чистим данные
        delete auctionNFT[_index];
        delete betNFT[_index];
    }

    /*
    * Отмена продажи нфт и коллекций
    */

    // Отмена продажи NFT
    function cancelNFTSale(uint256 _index) public {
        structNFTsInStore storage item = storeNFT[_index];

        require(item.amount > 0, "NFT not in store");
        require(item.owner == msg.sender, "Not your NFT");

        // Возврат NFT владельцу
        bytes memory data = "";
        _safeTransferFrom(address(this), msg.sender, item.id, item.amount, data);

        // Удаляем из магазина
        delete storeNFT[_index];
    }

    // Отмена продажи коллекции
    function cancelCollectionSale(uint256 _index) public {
        structCollectionInStore storage colStore = storeCollectionNFT[_index];

        require(colStore.NFTInCollection.length > 0, "Collection not in store");
        require(colStore.owner == msg.sender, "Not your collection");

        // Возврат всех NFT из коллекции владельцу
        uint256[] memory ids = new uint256[](colStore.NFTInCollection.length);
        uint256[] memory amounts = new uint256[](colStore.NFTInCollection.length);

        for (uint256 i = 0; i < colStore.NFTInCollection.length; i++) {
            ids[i] = colStore.NFTInCollection[i].id;
            amounts[i] = colStore.NFTInCollection[i].amount;
        }

        safeBatchTransferFrom(address(this), msg.sender, ids, amounts, "");

        // Обновляем состояние коллекции
        collectionNFTs[msg.sender][colStore.id].state = false;

        // Удаляем из магазина
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
        user[0x70997970C51812dc3A010C7d01b50e0d17dc79C8] = structUser("Tom", "PROFI3C442024", 0);
        ERC20._transfer(owner, 0x70997970C51812dc3A010C7d01b50e0d17dc79C8, 200_000);

        user[0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC] = structUser("Max", "PROFI90F72024", 0);
        ERC20._transfer(owner, 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC, 300_000);

        user[0x90F79bf6EB2c4f870365E785982E1f101E93b906] = structUser("Jack", "PROFI15d32024", 0);
        ERC20._transfer(owner, 0x90F79bf6EB2c4f870365E785982E1f101E93b906, 400_000);

        // remix
        // user[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2] = structUser(
        //     "Tom",
        //     "PROFI4B202024",
        //     0
        // );
        // ERC20._transfer(
        //     owner,
        //     0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
        //     200_000
        // );

        // user[0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db] = structUser(
        //     "Max",
        //     "PROFI78732024",
        //     0
        // );
        // ERC20._transfer(
        //     owner,
        //     0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,
        //     300_000
        // );

        // user[0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB] = structUser(
        //     "Jack",
        //     "PROFI617F2024",
        //     0
        // );
        // ERC20._transfer(
        //     owner,
        //     0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB,
        //     400_000
        // );

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

        setAuctionNFT(3, 100, 10000, 4); // id, startPrice, timeEnd, amount
    }
}
