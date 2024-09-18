// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Marketplace {
    uint256 public productCount = 0;

    struct Product {
        uint256 id;
        address payable seller;
        address buyer;
        string name;
        uint256 price;
        bool sold;
    }

    mapping(uint256 => Product) public products;

    event ProductCreated(uint256 id, string name, uint256 price, address seller);
    event ProductPurchased(uint256 id, address buyer, uint256 price);

    function createProduct(string memory _name, uint256 _price) public {
        require(bytes(_name).length > 0, "Product name required");
        require(_price > 0, "Product price must be greater than zero");

        productCount++;
        products[productCount] = Product(productCount, payable(msg.sender), address(0), _name, _price, false);
        
        emit ProductCreated(productCount, _name, _price, msg.sender);
    }

    function purchaseProduct(uint256 _id) public payable {
        Product memory _product = products[_id];
        require(_product.id > 0 && _product.id <= productCount, "Product doesn't exist");
        require(msg.value >= _product.price, "Not enough Ether");
        require(!_product.sold, "Product already sold");
        require(_product.seller != msg.sender, "Seller cannot buy their own product");

        _product.seller.transfer(msg.value);
        _product.buyer = msg.sender;
        _product.sold = true;
        products[_id] = _product;

        emit ProductPurchased(_id, msg.sender, _product.price);
    }
}

