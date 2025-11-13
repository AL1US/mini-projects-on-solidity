// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract Xcoin is ERC20, ERC1155 {

    //  Переменные
    address Owner;
    
    uint256 public unicueElement;

    string[] public allBaseElement=["water --> 0", "fire --> 1", "ground --> 2","air -->3"];

    string[][] public arrayBaseElement=[
        ["water", "100", "common"], 
        ["fire", "100", "common"],
        ["ground", "100", "common"],
        ["air", "100", "common"]
        ];

    structStoreUsers[] public store;

    // Структуры
    struct structElement {
        string name;
        uint256 price; 
        string rarity;
        uint256 amount;
    }

    struct structStoreUsers {
        address ownerProduct;
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
            // Проверка на то есть ли уже этот токен у юзера, если есть, то нужно просто добавить к нему количество
            require(balanceOf(msg.sender) >= 100 * amount, "you dont have enough money" );

            uint256 price = 100;

            ERC1155._mint( 
                msg.sender,
                unicueElement,
                amount,
                ""
            );

            transfer(address(this), 100);


        // Если бы мы просто старались запушить по [_index], то у нас выдалобы ошибку, которая связана с тем, что
        // мы по сути просто передадим массив строк, что передасться только в 1 поле структуры, а не по все другие, да и тип данныых 
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

    function setToken() public payable {

        _transfer(address(this), msg.sender, 10);
    }

    function addTokenInStore(uint256 _price, uint256 _amount, uint256 _index) public {
        // Проверка на то хватает ли токенов

        store.push(structStoreUsers(
            msg.sender,
            arrayBaseElement[_index][0],
            _price,
            arrayBaseElement[_index][2],
            _amount
        ));
        
        // Счетчик amount для кода снизу
        // Код, который удаляет токен если всё раскупили
    }

    // Геттеры
    function getAllElements() public view returns(string[] memory){
        return allBaseElement;
    }
    

    // Консруктор
    constructor(uint256 initialSupply) ERC20("Xcoin", "X") ERC1155("./Element/") {
        _mint(msg.sender, initialSupply);
        Owner = msg.sender;
        // token = Erc20(address(this));
    }

}
