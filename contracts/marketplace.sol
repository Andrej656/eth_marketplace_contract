// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Marketplace {
    // Struct to hold product details
    struct Product {
        uint256 id;
        address payable seller;
        address buyer;
        string name;
        string description;
        string category;
        uint256 price;  // Price in wei (smallest denomination of Ether)
        uint256 timestamp;
        bool sold;
    }

    // State variables
    uint256 public productCount = 0;  // Track the total number of products listed
    mapping(uint256 => Product) public products;  // Mapping of product IDs to Product struct

    // Events to notify when important actions are performed
    event ProductCreated(
        uint256 id,
        string name,
        string description,
        string category,
        uint256 price,
        address indexed seller,
        uint256 timestamp
    );
    
    event ProductPurchased(
        uint256 id,
        address indexed buyer,
        uint256 price
    );
    
    event ProductUpdated(
        uint256 id,
        string name,
        string description,
        string category,
        uint256 price,
        uint256 timestamp
    );

    // Function to create a new product
    function createProduct(
        string memory _name,
        string memory _description,
        string memory _category,
        uint256 _price
    ) public {
        // Ensure product details are valid
        require(bytes(_name).length > 0, "Product name required");
        require(bytes(_description).length > 0, "Product description required");
        require(bytes(_category).length > 0, "Product category required");
        require(_price > 0, "Product price must be greater than zero");

        // Increment product count
        productCount++;

        // Create the new product and store it in the products mapping
        products[productCount] = Product(
            productCount,
            payable(msg.sender),
            address(0),  // No buyer initially
            _name,
            _description,
            _category,
            _price,
            block.timestamp,  // Set timestamp to the current block time
            false  // Product initially not sold
        );

        // Emit the event that a product was created
        emit ProductCreated(
            productCount,
            _name,
            _description,
            _category,
            _price,
            msg.sender,
            block.timestamp
        );
    }

    // Function to purchase a product
    function purchaseProduct(uint256 _id) public payable {
        // Fetch the product using the provided ID
        Product memory _product = products[_id];

        // Ensure the product exists
        require(_product.id > 0 && _product.id <= productCount, "Invalid product ID");
        // Ensure the product is still available for sale
        require(!_product.sold, "Product already sold");
        // Ensure the buyer is not the seller
        require(_product.seller != msg.sender, "Seller cannot buy their own product");
        // Ensure the sent Ether is at least the price of the product
        require(msg.value >= _product.price, "Not enough Ether sent");

        // Transfer the Ether to the seller
        _product.seller.transfer(msg.value);

        // Mark the product as sold and set the buyer
        _product.sold = true;
        _product.buyer = msg.sender;

        // Update the product in the mapping
        products[_id] = _product;

        // Emit the event that the product was purchased
        emit ProductPurchased(_id, msg.sender, _product.price);
    }

    // Function to update product details (only by the seller)
    function updateProduct(
        uint256 _id,
        string memory _name,
        string memory _description,
        string memory _category,
        uint256 _price
    ) public {
        // Fetch the product using the provided ID
        Product storage _product = products[_id];

        // Ensure the product exists and is not sold
        require(_product.id > 0 && _product.id <= productCount, "Invalid product ID");
        require(!_product.sold, "Cannot update a sold product");
        // Ensure that only the seller can update the product
        require(msg.sender == _product.seller, "Only the seller can update this product");

        // Update product details
        _product.name = _name;
        _product.description = _description;
        _product.category = _category;
        _product.price = _price;
        _product.timestamp = block.timestamp;

        // Emit the event that the product was updated
        emit ProductUpdated(
            _id,
            _name,
            _description,
            _category,
            _price,
            block.timestamp
        );
    }

    // Function to retrieve a product's details
    function getProduct(uint256 _id) public view returns (
        uint256 id,
        string memory name,
        string memory description,
        string memory category,
        uint256 price,
        address seller,
        address buyer,
        uint256 timestamp,
        bool sold
    ) {
        // Fetch the product using the provided ID
        Product memory _product = products[_id];

        // Return product details
        return (
            _product.id,
            _product.name,
            _product.description,
            _product.category,
            _product.price,
            _product.seller,
            _product.buyer,
            _product.timestamp,
            _product.sold
        );
    }
}
