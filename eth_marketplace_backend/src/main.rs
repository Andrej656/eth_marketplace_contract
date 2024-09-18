use ethers::contract::abigen;
use ethers::providers::{Provider, Http, Middleware};
use ethers::signers::{SignerMiddleware, Wallet, LocalWallet};
use ethers::core::types::{H160, U256};
use ethers::utils::parse_ether;
use std::convert::TryFrom;
use std::sync::Arc;
use dotenv::dotenv;
use std::env;
use tokio;
use anyhow::{Result, Context};
use log::{info, error};

// Abigen to generate contract bindings
abigen!(
    Marketplace,
    r#"[{
        "constant": false,
        "inputs": [{"name": "_name", "type": "string"}, {"name": "_price", "type": "uint256"}],
        "name": "createProduct",
        "outputs": [],
        "type": "function"
    }, {
        "constant": true,
        "inputs": [{"name": "_id", "type": "uint256"}],
        "name": "getProduct",
        "outputs": [
            {"name": "id", "type": "uint256"},
            {"name": "name", "type": "string"},
            {"name": "description", "type": "string"},
            {"name": "category", "type": "string"},
            {"name": "price", "type": "uint256"},
            {"name": "seller", "type": "address"},
            {"name": "buyer", "type": "address"},
            {"name": "timestamp", "type": "uint256"},
            {"name": "sold", "type": "bool"}
        ],
        "type": "function"
    }]"#
);

#[tokio::main]
async fn main() -> Result<()> {
    // Initialize logger and environment variables
    env_logger::init();
    dotenv().ok();
    
    let infura_url = env::var("INFURA_URL").context("INFURA_URL not found")?;
    let private_key = env::var("PRIVATE_KEY").context("PRIVATE_KEY not found")?;

    // Initialize provider with the Infura URL
    let provider = Provider::<Http>::try_from(infura_url.as_str())
        .context("Failed to create provider")?;

    // Load wallet and signer middleware
    let wallet: LocalWallet = private_key.parse().context("Failed to parse private key")?;
    let client = Arc::new(SignerMiddleware::new(provider, wallet));

    // Replace with your deployed contract address
    let contract_address: H160 = "0xYourContractAddress".parse().context("Invalid contract address")?;
    let marketplace = Marketplace::new(contract_address, client.clone());

    // Test creating a product and fetching its details
    let product_name = "Old Phone".to_string();
    let product_price = parse_ether(1)?; // Convert 1 ETH to wei
    create_product(&marketplace, product_name, product_price).await?;
    get_product_details(&marketplace, 1).await?;

    Ok(())
}

// Function to create a new product
async fn create_product(
    marketplace: &Marketplace<SignerMiddleware<Provider<Http>, LocalWallet>>, 
    name: String, 
    price: U256
) -> Result<()> {
    info!("Creating product: {}, price: {:?}", name, price);

    let tx = marketplace
        .create_product(name, price)
        .send()
        .await
        .context("Failed to send transaction")?;
    
    info!("Transaction submitted. Tx Hash: {:?}", tx);
    Ok(())
}

// Function to retrieve product details
async fn get_product_details(
    marketplace: &Marketplace<SignerMiddleware<Provider<Http>, LocalWallet>>, 
    product_id: u64
) -> Result<()> {
    info!("Fetching details for product ID: {}", product_id);

    let product = marketplace
        .get_product(U256::from(product_id))
        .call()
        .await
        .context("Failed to fetch product details")?;

    info!(
        "Product details - ID: {}, Name: {}, Price: {:?}, Seller: {:?}, Sold: {}",
        product.0, product.1, product.4, product.5, product.8
    );
    Ok(())
}
