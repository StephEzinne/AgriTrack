---

# AgriTrack - Agriculture Supply Chain Management Smart Contract

This smart contract is designed to manage and track the entire lifecycle of agricultural products in a supply chain, from production to delivery. It ensures transparent, tamper-proof record-keeping, including product status, ownership, quality control, and stakeholder involvement.

## Features

- **Stakeholder Management**: Allows adding and updating stakeholders (e.g., producers, inspectors, distributors).
- **Product Management**: Registers products, tracks their phases, and transfers ownership between stakeholders.
- **Quality Control**: Tracks the quality score of each product and verifies if it meets the required threshold.
- **Transaction History**: Logs all product-related transactions (e.g., ownership transfer, phase changes, quality updates, and position updates).
- **Role-based Access**: Only authorized stakeholders can perform certain actions on the products.

## Table of Contents

- [Installation](#installation)
- [Smart Contract Functions](#smart-contract-functions)
  - [Stakeholder Management](#stakeholder-management)
  - [Product Management](#product-management)
  - [Quality Control](#quality-control)
  - [Transaction History](#transaction-history)
- [Usage Examples](#usage-examples)
- [Security Considerations](#security-considerations)
- [License](#license)

## Installation

To deploy this contract, you will need the Stacks blockchain environment, which supports Clarity smart contracts. You can follow these steps to set up your environment:

1. **Install Stacks CLI**:
   You can find the installation guide for the Stacks CLI [here](https://github.com/blockstack/stacks.js/blob/master/README.md).

2. **Deploy the Contract**:
   After setting up your Stacks environment, deploy this contract to your desired Stacks network (testnet/mainnet) using the Stacks CLI.

## Smart Contract Functions

### Stakeholder Management

1. **Register Stakeholder**
   Registers a new stakeholder (e.g., producer, distributor) in the system.
   - `register-stakeholder(stakeholder-address: principal, stakeholder-type: string-ascii)`

2. **Update Stakeholder Status**
   Update the activity status (active/inactive) of a stakeholder.
   - `update-stakeholder-status(stakeholder-address: principal, is-active: bool)`

### Product Management

1. **Register Product**
   Registers a new product in the supply chain with details like title, position, and price.
   - `register-product(product-id: uint, product-title: string-ascii, product-position: string-ascii, product-price: uint)`

2. **Update Product Phase**
   Updates the current phase of the product (e.g., "manufactured", "shipped", etc.) and logs the transaction.
   - `update-product-phase(product-id: uint, new-phase: string-ascii, phase-notes: string-ascii)`

3. **Transfer Ownership**
   Transfers the ownership of a product to another stakeholder and logs the transaction.
   - `transfer-ownership(product-id: uint, new-owner: principal, transfer-details: string-ascii)`

4. **Update Product Position**
   Updates the current position of the product (e.g., warehouse, transportation status) and logs the transaction.
   - `update-position(product-id: uint, new-position: string-ascii, position-notes: string-ascii)`

### Quality Control

1. **Update Quality Score**
   Updates the quality score of a product based on an inspection. If the score meets the required threshold, it verifies the product quality.
   - `update-quality(product-id: uint, new-quality-score: uint, quality-details: string-ascii)`

### Transaction History

1. **Get Product Details**
   Retrieves the details of a specific product.
   - `get-product-details(product-id: uint)`

2. **Get Stakeholder Info**
   Retrieves information about a specific stakeholder.
   - `get-stakeholder-info(stakeholder-address: principal)`

3. **Get Transaction Details**
   Retrieves the details of a specific transaction for a product.
   - `get-transaction-details(product-id: uint, transaction-id: uint)`

## Usage Examples

### 1. Register a Stakeholder

To register a new stakeholder, use the `register-stakeholder` function. The contract owner must initiate this action:

```clarity
(register-stakeholder tx-sender "producer")
```

### 2. Register a Product

A stakeholder can register a product by providing details such as product ID, title, price, and position:

```clarity
(register-product 1 "Organic Tomato" "Warehouse A" 100)
```

### 3. Update Product Phase

When a product enters a new phase (e.g., "shipped"), the stakeholder can update the phase:

```clarity
(update-product-phase 1 "shipped" "Product shipped to distributor")
```

### 4. Transfer Ownership

A product's ownership can be transferred from one stakeholder to another:

```clarity
(transfer-ownership 1 new-owner "Product sold to distributor")
```

### 5. Update Product Quality

A quality inspector can update the product's quality score after inspection:

```clarity
(update-quality 1 85 "Quality verified by inspector")
```

### 6. Update Product Position

Stakeholders can update the product's current position (e.g., from warehouse to transportation):

```clarity
(update-position 1 "In Transit" "Product is now being shipped")
```

## Security Considerations

- **Authorization**: Only authorized stakeholders can perform certain actions like updating the product phase, ownership, and quality. Only the contract owner can register or update stakeholders.
- **Input Validation**: All inputs (e.g., strings and numbers) are validated to ensure they meet required constraints, such as length and value range.
- **Transaction Logging**: All significant actions (e.g., ownership transfer, quality updates) are logged to maintain a transparent and immutable record.

