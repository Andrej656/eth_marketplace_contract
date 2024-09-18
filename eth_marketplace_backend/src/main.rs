use ethers::contract::abigen;
use ethers::providers::{Provider, Http};
use ethers::signers::{SignerMiddleware, Wallet, LocalWallet};
use ethers::core::types::{H160, U256};
use std::convert::TryFrom;
use std::sync::Arc;
use dotenv::dotenv;
use std::env;

abigen!(
    Marketplace,
    r#"[{
        "constant": false,
        "inputs": [{"name": "_name", "type": "string"}, {"name": "_price", "type": "uint256"}],
        "name": "createProduct",
        "outputs": [],
        "type": "function"
    }]"#
);

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    dotenv().ok();
    let provider_url = env::var("INFURA_URL").expect("Missing Infura URL");
    let provider = Provider::<Http>::try_from(provider_url.as_str())?;

    let private_key = env::var("PRIVATE_KEY").expect("Missing private key");
    let wallet: LocalWallet = private_key.parse()?;
    let client = Arc::new(SignerMiddleware::new(provider, wallet));

    let contract_address: H160 = "0xYourContractAddress".parse()?;
    let marketplace = Marketplace::new(contract_address, client.clone());

    let tx = marketplace.create_product("Old Phone", U256::from(1000000000)).send().await?;
    println!("Product created! Tx hash: {:?}", tx);

    Ok(())
}
