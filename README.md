# 📝 On-Chain Script Marketplace

> A decentralized marketplace where writers can tokenize their scripts and sell limited reading rights to producers! 🎬✨

## 🚀 Overview

The On-Chain Script Marketplace enables content creators to monetize their scripts by selling time-limited access to buyers. Writers maintain full ownership while generating revenue from their intellectual property.

## ✨ Key Features

- 📖 **Script Registration**: Writers can tokenize their scripts with metadata and pricing
- 💰 **Access Sales**: Sell time-limited reading rights to producers and buyers
- ⏰ **Expiring Access**: Automatic access control with configurable duration
- 💎 **Earnings Management**: Transparent revenue tracking and withdrawal system
- 🛡️ **Content Protection**: Scripts are stored as content hashes for security
- 📊 **Analytics**: Track sales, access counts, and performance metrics

## 🔧 Core Functions

### For Writers 📝

- `register-script` - Register a new script with title, description, content hash, and price
- `deactivate-script` - Temporarily disable script sales
- `reactivate-script` - Re-enable script for purchase
- `update-script-price` - Modify pricing for existing scripts
- `withdraw-earnings` - Claim accumulated revenue from script sales

### For Buyers 🛒

- `purchase-access` - Buy time-limited access to a script
- `access-script` - Read script content (requires valid access)

### Public Queries 🔍

- `get-script` - View script metadata and details
- `get-script-access` - Check access status for specific buyer
- `has-active-access` - Verify if buyer has current access
- `get-script-stats` - View sales and performance data
- `calculate-purchase-cost` - Preview costs before buying

## 💡 Usage Examples

### Register a Script
```clarity
(contract-call? .On-Chain-Script-Marketplace register-script 
  "Amazing Thriller Script" 
  "A gripping story about..." 
  0x1234567890abcdef1234567890abcdef12345678 
  u1000000)
```

### Purchase 30-Day Access
```clarity
(contract-call? .On-Chain-Script-Marketplace purchase-access u1 u4320)
```

### Access Your Script
```clarity
(contract-call? .On-Chain-Script-Marketplace access-script u1)
```

## 🏗️ Contract Architecture

The marketplace uses several key data structures:

- **Scripts Map**: Stores script metadata, pricing, and stats
- **Script Access Map**: Tracks buyer access permissions and expiration
- **Writer Earnings**: Accumulated revenue per writer
- **Buyer Purchases**: Purchase history per buyer

## 💸 Economics

- Platform fee: 5% (configurable by contract owner)
- Writer earnings: 95% of each sale
- Flexible pricing set by script writers
- Access duration measured in Stacks blocks

## 🛠️ Development

### Prerequisites
- Clarinet CLI installed
- Stacks blockchain development environment

### Testing
```bash
clarinet check
clarinet test
```

### Deployment
```bash
clarinet deploy
```

## 🔒 Security Features

- Content stored as hashes to prevent unauthorized access
- Time-based access control with automatic expiration
- Writer-only script management permissions
- Secure payment handling with platform fee distribution

## 📈 Roadmap

- [ ] Bulk purchase discounts
- [ ] Script categories and tagging
- [ ] Writer reputation system
- [ ] Revenue sharing for collaborations
- [ ] NFT integration for script ownership

---

Built with ❤️ on Stacks blockchain 🔗
