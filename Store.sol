// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract Basics {

    Data[] public products;

    mapping(address => uint256) public mapBuyProduct; 

    modifier noElement(uint256 _element) {
        require(_element < products.length, "There is no such element");
        _;
    }

    struct Data {
        address ownerProduct;
        string name;
        uint256 price;
        bool state;
    }

    function pushProduct(address _ownerProduct, string memory _name, uint256 _price, bool _state) public {
        products.push(Data(_ownerProduct,_name, _price, _state));
    }
 
    function delProduct(uint256 _element) public noElement(_element) {

        require(msg.sender == products[_element].ownerProduct, "Only owner can delete");
   
        products[_element] = products[products.length -1];
        products.pop();
    }

    function getProduct(uint256 _numProduct) public view returns(
        address ownerProduct,
        string memory name,
        uint256 price,
        bool state
    ) {
        return (products[_numProduct].ownerProduct, products[_numProduct].name, products[_numProduct].price, products[_numProduct].state);
    }

    function getProduct1(uint256 _numProduct) public view returns(Data memory) {
        return products[_numProduct];
    }

    function funcBuyProduct(uint256 _product) public payable noElement(_product) {
        require(products[_product].state == true, "net atogo product");
        require(msg.value >= products[_product].price, "not enough eth sent");

        uint256 productPrice = products[_product].price;

        if(msg.value > productPrice) {
            payable(msg.sender).transfer(msg.value - productPrice);
        }

        payable(products[_product].ownerProduct).transfer(productPrice);
        
        mapBuyProduct[msg.sender] = _product;
        products[_product].state = false;

        }
}
