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

    mapping (address => basketStruct[][]) public cheque;

    // mapping (address => chequeStruct[]) public cheque;

    // struct chequeStruct {
    //     uint256 id;
    //     address ownerCheque;
    //     basketStruct[] products;
    //     uint256 totalPrice;
    // }

    mapping (address => basketStruct[]) public basket;

    struct basketStruct {
        uint256 id;
        ProductType productType;
        string name;
        uint256 quantity;
        uint256 price;
    }

    enum ProductType {
        pizza,
        drinc
    }

    // Модификаторы
    modifier onlyAdmin(){
        require(roles[msg.sender] == Roles.admin, "Access is denied: only the administrator can perform this action.");
        _;
    }

    modifier onlyUser(){
        require(roles[msg.sender] != Roles.None, "Access is denied: only the user can perform this action.");
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

    // Функции с пиццей
    function buyPizza(uint256 _id) public payable onlyUser {
        require(msg.value >= pizza[_id].price, "not enough eth sent");
        require(_id < pizza.length, "There is no such pizza");

        uint pricePizza = pizza[_id].price;

        if (msg.value > pricePizza) {
            payable(msg.sender).transfer(msg.value - pricePizza);
        }

        payable(owner).transfer(pricePizza);
    
    }

    // Добавить пиццу в корзину
    function setPizzaInBasket(uint256 _index, uint256 _quanity ) public onlyUser {
        require(_index < pizza.length, "There is no such pizza");
        require(_quanity > 0, "Quantity of pizza must be greater than 0");
        require(_quanity < 100, "Quantity of pizza must be less than 100");

        bool alreadyInBasket = false;
        uint256 indexInBasket;

        for (uint256 i = 0; i < basket[msg.sender].length; i++) {
            if (basket[msg.sender][i].id == _index && basket[msg.sender][i].productType == ProductType.pizza) {
                alreadyInBasket = true;
                indexInBasket = i;
                break;
            }
        }

        if (alreadyInBasket) {
            basket[msg.sender][indexInBasket].quantity += _quanity;
        } else {
            basket[msg.sender].push(basketStruct(pizza[_index].id, ProductType.pizza, pizza[_index].name, _quanity, pizza[_index].price));
        }
    }

    // Функции с напитком
    function buyDrinc(uint256 _id) public payable onlyUser {
        require(msg.value >= drinc[_id].price, "not enough eth sent");
        require(_id < drinc.length, "There is no such drinc");

        uint priceDrinc = drinc[_id].price;

        if (msg.value > priceDrinc) {
            payable(msg.sender).transfer(msg.value - priceDrinc);
        }

        payable(owner).transfer(priceDrinc);
    
    }

    // Добавить напиток в корзину
    function setDrincInBasket(uint256 _index, uint256 _quanity ) public onlyUser {
        require(_index < drinc.length, "There is no such pizza");
        require(_quanity > 0, "Quantity of drinc must be greater than 0");
        require(_quanity < 100, "Quantity of drinc must be less than 100");

        bool alreadyInBasket = false;
        uint256 indexInBasket;

        for (uint256 i = 0; i < basket[msg.sender].length; i++) {
            if (basket[msg.sender][i].id == _index && basket[msg.sender][i].productType == ProductType.drinc) {
                alreadyInBasket = true;
                indexInBasket = i;
                break;
            }
        }

        if (alreadyInBasket) {
            basket[msg.sender][indexInBasket].quantity += _quanity;
        } else {

        basket[msg.sender].push(basketStruct(drinc[_index].id, ProductType.drinc, drinc[_index].name, _quanity, drinc[_index].price));
        }
    }

    // Покупка всей корзины
    function buyBasket() public payable onlyUser {
        require(basket[msg.sender].length > 0, "Basket is empty");

        uint256 totalPrice = 0;
    
        for (uint256 i = 0; i < basket[msg.sender].length; i++) {
            totalPrice += basket[msg.sender][i].price * basket[msg.sender][i].quantity;
        }

        require(msg.value >= totalPrice, "Not enough money");

        payable(owner).transfer(totalPrice);

        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }

        cheque[msg.sender].push(basket[msg.sender]);

        delete basket[msg.sender];
    }

    // Удаление продукта из корзины
    function delProduct(uint256 _element) public  onlyUser {
        require(_element < basket[msg.sender].length, "There is no such element");  
        require(basket[msg.sender].length > 0, "Basket is empty");

        basket[msg.sender][_element] = basket[msg.sender][basket[msg.sender].length -1];
        basket[msg.sender].pop();
    }

    // Очистка всей корзины
    function clearBasket() public onlyUser {
        delete basket[msg.sender];
    }

    // Функция показа корзины
    function showBasket() public view onlyUser returns (basketStruct[] memory) {
        return basket[msg.sender];
    }

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
