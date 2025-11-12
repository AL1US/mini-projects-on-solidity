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

    // Структуры
    struct structElement {
        string name;
        string price; //Строка потому-что в массиве arrayBaseElement - у нас массив строк
        string rarity;
    }


    // Мапинги
    mapping (address => structElement[]) public userElements;

    // mapping (address => uint256) public user_amount_unicue_nft;
    


    // Модификаторы
    modifier onlyOwner {
        require(msg.sender == Owner, "You are not owner");
        _;
    }

    // Сеттеры
    function setElement(
        uint256 _index,
        uint256 amount) public payable {

            require(balanceOf(msg.sender) >= 100, "you dont have enough money" );

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

        userElements[msg.sender].push(
            structElement(             
                arrayBaseElement[_index][0], // Сначала обращаемся к массиву, затем к элементу массива
                arrayBaseElement[_index][1],
                arrayBaseElement[_index][2]
            )
        );

        unicueElement ++;

        // user_amount_unicue_nft[msg.sender] ++;
    }

    function setToken() public payable {

        _transfer(address(this), msg.sender, 10);
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
