# 💰 MicroPay - Micro-Payments for Content

> 🎯 **A decentralized system enabling content creators to receive small, automatic payments in STX for articles or videos viewed on websites.**

## 📖 Overview

MicroPay is a Clarity smart contract that revolutionizes content monetization by enabling seamless micro-payments for digital content consumption. Content creators can register their articles, videos, or other digital content and automatically receive STX payments when users view their content.

## ✨ Features

- 🚀 **Easy Content Registration** - Creators can register content with custom payment amounts
- 💳 **Automatic Payments** - Users pay small amounts to view content automatically
- 💰 **Creator Earnings** - Creators earn STX with each content view
- 📊 **Analytics** - Track views, earnings, and payment history
- ⚡ **Instant Withdrawals** - Creators can withdraw earnings anytime
- 🔒 **Secure Platform** - Built-in security features and owner controls
- 📈 **Low Fees** - Only 5% platform fee on transactions

## 🛠️ Contract Functions

### 📝 Content Management

#### `register-content`
Register new content for monetization:
```clarity
(register-content "My Article Title" u5000)
```
- **title**: Content title (max 100 characters)  
- **payment-amount**: Payment required to view (1,000 - 1,000,000 microSTX)

#### `deactivate-content` / `reactivate-content`
Toggle content availability:
```clarity
(deactivate-content u1)
(reactivate-content u1)
```

#### `update-payment-amount`  
Modify content pricing:
```clarity
(update-payment-amount u1 u7500)
```

### 💳 Payment System

#### `pay-for-content`
Pay to view content:
```clarity
(pay-for-content u1)
```
Automatically transfers payment to creator and platform fee to contract.

#### `withdraw-earnings`
Withdraw accumulated earnings:
```clarity
(withdraw-earnings)
```

### 📊 Read Functions

#### `get-content-info`
Get detailed content information:
```clarity
(get-content-info u1)
```

#### `get-creator-balance`
Check creator's current balance:
```clarity
(get-creator-balance 'SP1CREATOR...)
```

#### `get-platform-stats`
View platform statistics:
```clarity
(get-platform-stats)
```

## 🚀 Getting Started

### For Content Creators

1. **Register Content**
   ```clarity
   (contract-call? .MicroPay register-content "My Amazing Article" u3000)
   ```

2. **Monitor Earnings**
   ```clarity
   (contract-call? .MicroPay get-creator-balance tx-sender)
   ```

3. **Withdraw Earnings**
   ```clarity
   (contract-call? .MicroPay withdraw-earnings)
   ```

### For Content Consumers

1. **View Content**
   ```clarity
   (contract-call? .MicroPay pay-for-content u1)
   ```

2. **Check Payment History**
   ```clarity
   (contract-call? .MicroPay get-content-views tx-sender u1)
   ```

## 📋 Configuration

### Payment Limits
- **Minimum Payment**: 1,000 microSTX (0.001 STX)
- **Maximum Payment**: 1,000,000 microSTX (1 STX)  
- **Platform Fee**: 5% of each transaction

### Error Codes
- `u100`: Owner-only function
- `u101`: Content not found
- `u102`: Already exists  
- `u103`: Insufficient payment
- `u104`: Unauthorized access
- `u105`: Invalid amount
- `u106`: No balance available

## 🔧 Development

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Node.js for testing

### Setup
```bash
# Clone repository
git clone <repository-url>
cd Micro-Payments-for-Content

# Check contract syntax
clarinet check

# Run tests  
npm install
npm test
```

### Testing
```bash
# Check contract compilation
clarinet check

# Run unit tests
npm test

# Interactive console
clarinet console
```

## 🏗️ Architecture

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│   Content   │    │   MicroPay   │    │   Platform  │
│  Creators   │───▶│   Contract   │───▶│    Owner    │
└─────────────┘    └──────────────┘    └─────────────┘
                          │
                          ▼
                   ┌──────────────┐
                   │   Content    │
                   │  Consumers   │
                   └──────────────┘
```

## 📊 Data Storage

The contract maintains several key data structures:

- **Content Registry**: Stores all registered content metadata
- **Creator Balances**: Tracks earnings for each creator  
- **Payment History**: Records all transactions
- **View Tracking**: Monitors content consumption

## 🔐 Security Features

- ✅ Owner-only administrative functions
- ✅ Content creator authorization checks  
- ✅ Payment amount validation
- ✅ Emergency pause functionality
- ✅ Balance verification before transactions

## 🌟 Use Cases

- 📰 **News Websites** - Pay-per-article reading
- 🎥 **Video Platforms** - Micro-payments for video content  
- 📚 **Educational Content** - Monetize tutorials and courses
- 🎨 **Digital Art** - Sell access to digital galleries
- 📝 **Blog Platforms** - Premium content monetization

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

---

**Built with ❤️ for the Stacks ecosystem**
