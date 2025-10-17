// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract Pizzeria {

    address owner;

    mapping (address => Roles) public roles;

/** 
 *  Почему enum, а не struct?
 *  в enum операции намного дешевле чем в структуре
 *  Также проверки намного проще осуществляются
 */
    enum Roles {
        None, // Для проверки того, что пользователь не имеет роли
        user,
        admin,
        manager
    }

    pizzaStruct[] public pizza;

    struct pizzaStruct {
        uint256 id;
        string name;
        string description;
        uint256 price;
    }

    // basketPizza[] public basketPizza;

    drincStruct[] public drinc;

     struct drincStruct {
         uint256 id;
         string name;
         string description;
         uint256 price;
    }

    mapping (address => regStruct) public registration;

    struct regStruct {
        string login;
        string password;
    }



    // Модификаторы
    modifier onlyAdmin(){
        require(roles[msg.sender] == Roles.admin, "Access is denied: only the administrator can perform this action.");
        _;
    }

    modifier onlyUser(){
        require(roles[msg.sender] == Roles.user, "Access is denied: only the user can perform this action.");
        _;
    }
     
    modifier onlyManager(){
        require(roles[msg.sender] == Roles.manager, "Access is denied: only the manager can perform this action.");
        _;
    }
        modifier onlyNone(){
        require(roles[msg.sender] == Roles.None, "Access is denied: only an unregistered user can perform this action.");
        _;
    }

    constructor() {
        roles[msg.sender] = Roles.admin;
        owner = msg.sender;
    } 

    // функции менеджера 

    //Создание, удаление пицц и просмотр пицц
    function setPizza(string memory _name, string memory _description, uint256 _price) public onlyManager{
        uint ID = pizza.length + 1;

        pizza.push(pizzaStruct(ID, _name, _description, _price));
    }

    // function pushInBasketPizza (uint _IndexPizza) public onlyUser {
    //     basketPizza.push(pizza[_IndexPizza]);
    // }

    function getPizza(uint256 _index) public view returns(pizzaStruct memory) {
        return pizza[_index]; 
    }

    function delPizza(uint256 _element) public  onlyManager {
        require(_element < pizza.length, "There is no such element");  
        pizza[_element] = pizza[pizza.length -1];
        pizza.pop();
    }
    

    // Создание, удаление напитков и просмотр напитков
    function setDrinc(string memory _name, string memory _description, uint256 _price) public onlyManager{
        uint ID = drinc.length + 1;

        drinc.push(drincStruct(ID, _name, _description, _price));
    }    

    function getDrinc(uint256 _index) public view returns (drincStruct memory) {
        return drinc[_index];
    }

    function delDrinc(uint256 _element) public  onlyManager {
        require(_element < drinc.length, "There is no such element");  
        drinc[_element] = drinc[drinc.length -1];
        drinc.pop();
    }
        
    // Функции юзера

    // Покупка пиццы
    function buyPizza(uint256 _id) public payable onlyUser {
        require(msg.value >= pizza[_id].price, "not enough eth sent");
        require(_id < pizza.length, "There is no such pizza");

        uint pricePizza = pizza[_id].price;

        if (msg.value > pricePizza) {
            payable(msg.sender).transfer(msg.value - pricePizza);
        }

        payable(owner).transfer(pricePizza);
    
    }

    // Напитка
    function buyPizza(uint256 _id) public payable onlyUser {
        require(msg.value >= pizza[_id].price, "not enough eth sent");
        require(_id < drinc.length, "There is no such pizza");

        uint priceDrinc = drinc[_id].price;

        if (msg.value > priceDrinc) {
            payable(msg.sender).transfer(msg.value - priceDrinc);
        }

        payable(owner).transfer(priceDrinc);
    
    }

    // function setPizzaInBasket(uint256 _id) public {
    //     require(_id < pizza.length, "There is no such pizza");

    //     basket.push(pizzaStruct(pizza[_id].name, pizza[_id].price));
    // }  


    // Функции админа
    function setManager(address _address) public onlyAdmin {
        roles[_address] = Roles.manager;
    }

    // Регистрация
    function setReg(string memory _login, string memory _password) public onlyNone {
        registration[msg.sender] = regStruct(_login, _password);
        roles[msg.sender] = Roles.user;
    }


    // Выход из аккаунта
    function exit() public onlyUser {
        roles[msg.sender] = Roles.None;
    }

    // Просмотр роли
    function getRole() public view returns (Roles) {
        return roles[msg.sender];
    }

}
