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
- 📅 **Subscription Plans** - Time-based unlimited access to creator content

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
Pay to view content (bypassed if active subscription exists):
```clarity
(pay-for-content u1)
```
Automatically transfers payment to creator and platform fee to contract.

#### `withdraw-earnings`
Withdraw accumulated earnings:
```clarity
(withdraw-earnings)
```

### 📅 Subscription Management

#### `create-subscription-plan`
Create a subscription plan for your content:
```clarity
(create-subscription-plan u50000 u4320)
```
- **monthly-price**: Subscription cost (1,000 - 1,000,000 microSTX)
- **duration-blocks**: Subscription duration in blocks (~144 blocks/day)

#### `subscribe-to-creator`
Subscribe to unlimited access for a creator's content:
```clarity
(subscribe-to-creator 'SP1CREATOR...)
```
Provides unlimited content access during subscription period.

#### `toggle-subscription-plan`
Toggle subscription plan availability:
```clarity
(toggle-subscription-plan)
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

#### `get-subscription-plan`
Get creator's subscription plan details:
```clarity
(get-subscription-plan 'SP1CREATOR...)
```

#### `is-subscription-active`
Check if user has active subscription to creator:
```clarity
(is-subscription-active 'SP1USER... 'SP1CREATOR...)
```

#### `get-subscription-expiry`
Get subscription expiration block:
```clarity
(get-subscription-expiry 'SP1USER... 'SP1CREATOR...)
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

3. **Create Subscription Plan**
   ```clarity
   (contract-call? .MicroPay create-subscription-plan u30000 u4320)
   ```

4. **Withdraw Earnings**
   ```clarity
   (contract-call? .MicroPay withdraw-earnings)
   ```

### For Content Consumers

1. **Subscribe to Creator**
   ```clarity
   (contract-call? .MicroPay subscribe-to-creator 'SP1CREATOR...)
   ```

2. **View Content (Pay-per-view or Subscription)**
   ```clarity
   (contract-call? .MicroPay pay-for-content u1)
   ```

3. **Check Subscription Status**
   ```clarity
   (contract-call? .MicroPay is-subscription-active tx-sender 'SP1CREATOR...)
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
- `u107`: Invalid subscription parameters
- `u108`: No active subscription

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

- 📰 **News Websites** - Pay-per-article reading or monthly subscriptions
- 🎥 **Video Platforms** - Micro-payments or unlimited streaming subscriptions
- 📚 **Educational Content** - Course subscriptions and tutorial access
- 🎨 **Digital Art** - Gallery subscriptions for collectors
- 📝 **Blog Platforms** - Premium content with subscription tiers
- 🎵 **Music Platforms** - Artist subscription for exclusive content

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

---

**Built with ❤️ for the Stacks ecosystem**
