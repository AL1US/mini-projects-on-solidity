// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract Xcoin is ERC20, ERC1155 {

    //  Переменные
    address Owner;
    
    uint256 public unicueElement;

    string[] public allBaseElement=["water --> 0", "fire --> 1", "ground --> 2", "air -->3"];

    string[][] public arrayBaseElement=[
        ["water", "100", "common"], 
        ["fire", "100", "common"],
        ["ground", "100", "common"],
        ["air", "100", "common"]
        ];

    structStoreUsers[] public store;

    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 10**18;

    // Структуры
    struct structElement {
        string name;
        uint256 price; 
        string rarity; // на самом деле редкость тут чисто по приколу
        uint256 amount;
    }

    struct structStoreUsers {
        address ownerToken;
        string name;
        uint256 price;
        string rarity;
        uint256 amount;
    }


    // Мапинги
    mapping (address => structElement[]) public userElements;

    // mapping (uint256 => structStoreUsers[]) public store;
    


    // Модификаторы
    modifier onlyOwner {
        require(msg.sender == Owner, "You are not owner");
        _;
    }

    // Сеттеры
    function setElement(
        uint256 _index,
        uint256 amount) public payable {
            require(_index <= 3, "Not found element"); //   Всего есть 4 базовых элемента от 0 до 3
            uint256 price = 10;
            // Проверка на то есть ли уже этот токен у юзера, если есть, то нужно просто добавить к нему количество
            require(balanceOf(msg.sender) >= price * amount, "you dont have enough money" );

            ERC1155._mint( 
                msg.sender,
                unicueElement,
                amount,
                ""
            );

            transfer(address(this), price * amount);


        // Если бы мы просто старались запушить по [_index], то у нас выдалобы ошибку, которая связана с тем, что
        // мы по сути просто передадим массив строк, что передасться только в 1 поле структуры, а не по все другие, да и тип данных 
        // там не правильный, поэтому оно впринципе нормально не передасться
        // Сохраняем мы это всё для удобства, чтобы потом можно было нормально и красиво отабразить, хотя не знаю пригодится ли оно мне
        userElements[msg.sender].push(
            structElement(             
                // Сначала обращаемся к массиву, затем к элементу массива
                arrayBaseElement[_index][0], // Имя
                price,
                arrayBaseElement[_index][2], // Редкость
                amount
            )
        );

        unicueElement = _index; // Равно тому индексу, по которому мы добавили элемент

    }

    // Кликер для получения Xcoin
    function setToken() public payable {

        _transfer(address(this), msg.sender, 10);
    }

    function addTokenInStore(uint256 _price, uint256 _amount, uint256 _index) public {

        require(balanceOf(msg.sender, _index) > 0, "Not found this token"); // Если токен не найден, то оно просто вернёт 0

        store.push(structStoreUsers(
            msg.sender,
            arrayBaseElement[_index][0], // имя
            _price,
            arrayBaseElement[_index][2], // редкость
            _amount
        ));
        
    }

    function buyTokenInStore(uint256 _index, uint256 _amount) public payable {
        // Вытаскиваем значения, чтобы с ними можно было удобно работать
        uint256 priceToken = store[_index].price * _amount; 
        address addressOwnerToken = store[_index].ownerToken;
        bytes memory data = "";

        require(balanceOf(addressOwnerToken, _index) >= _amount);
        require(balanceOf(msg.sender) >= priceToken, "Not enough Xcoin"); 

        transfer(addressOwnerToken, priceToken);

        safeTransferFrom(addressOwnerToken, msg.sender, _index, _amount, data);

        store[_index].amount -= _amount;

        if (store[_index].amount == 0) {
            store[_index] = store[store.length -1];
            store.pop();
        }
    }

    // Геттеры
    function getAllElements() public view returns(string[] memory){
        return allBaseElement;
    }

    function getTokenInStore(uint256 _index) public view returns (structStoreUsers memory) {
        return store[_index];
    }
    

    // Консруктор
    constructor() ERC20("Xcoin", "X") ERC1155("./Element/") {
        Owner = msg.sender;
        _mint(address(this), INITIAL_SUPPLY); // Указывается то кому будут переведены токены и то сколько будет токенов

    }

}
