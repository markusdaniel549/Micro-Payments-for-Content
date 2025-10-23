;; title: MicroPay
;; version: 1.0.0
;; summary: Micro-payments for content creators
;; description: A system enabling content creators to receive small, automatic payments in STX for articles or videos viewed on a website

;; constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-insufficient-payment (err u103))
(define-constant err-unauthorized (err u104))
(define-constant err-invalid-amount (err u105))
(define-constant err-no-balance (err u106))
(define-constant err-invalid-subscription (err u107))
(define-constant err-no-active-subscription (err u108))
(define-constant err-invalid-tip (err u109))

(define-constant min-payment-amount u1000)
(define-constant max-payment-amount u1000000)
(define-constant platform-fee-percentage u5)
(define-constant tier-bronze u50000000000)
(define-constant tier-silver u200000000000)
(define-constant tier-gold u500000000000)
(define-constant tier-platinum u1000000000000)
(define-constant tier-none u0)
(define-constant tier-bronze-id u1)
(define-constant tier-silver-id u2)
(define-constant tier-gold-id u3)
(define-constant tier-platinum-id u4)
(define-constant bonus-bronze u5)
(define-constant bonus-silver u10)
(define-constant bonus-gold u15)
(define-constant bonus-platinum u20)
(define-constant min-tip-amount u100)

;; data vars
(define-data-var next-content-id uint u1)
(define-data-var total-content-count uint u0)
(define-data-var platform-balance uint u0)
(define-data-var is-paused bool false)
(define-data-var next-tip-id uint u1)

;; data maps
(define-map content-registry
  { content-id: uint }
  {
    creator: principal,
    title: (string-ascii 100),
    payment-amount: uint,
    total-views: uint,
    total-earned: uint,
    is-active: bool,
    created-at: uint
  }
)

(define-map creator-balances
  { creator: principal }
  { balance: uint }
)

(define-map content-views
  { viewer: principal, content-id: uint }
  { view-count: uint, last-viewed: uint }
)

(define-map creator-content-count
  { creator: principal }
  { count: uint }
)

(define-map payment-history
  { payment-id: uint }
  {
    viewer: principal,
    creator: principal,
    content-id: uint,
    amount: uint,
    timestamp: uint
  }
)

(define-data-var next-payment-id uint u1)
(define-data-var next-subscription-id uint u1)

(define-map subscription-plans
  { creator: principal }
  {
    monthly-price: uint,
    duration-blocks: uint,
    is-active: bool,
    total-subscribers: uint,
    created-at: uint
  }
)

(define-map user-subscriptions
  { subscriber: principal, creator: principal }
  {
    expires-at: uint,
    subscription-id: uint,
    auto-renew: bool,
    created-at: uint
  }
)

(define-map subscription-history
  { subscription-id: uint }
  {
    subscriber: principal,
    creator: principal,
    amount: uint,
    duration-blocks: uint,
    timestamp: uint
  }
)

(define-map creator-tiers
  { creator: principal }
  { tier: uint }
)

(define-map creator-bonuses
  { creator: principal }
  { bonus: uint }
)

(define-map tip-history
  { tip-id: uint }
  {
    tipper: principal,
    creator: principal,
    content-id: uint,
    amount: uint,
    timestamp: uint,
    message: (optional (string-ascii 200))
  }
)

(define-map creator-tips-received
  { creator: principal }
  { total-tips: uint, tip-count: uint }
)

(define-map content-tips
  { content-id: uint }
  { total-tips: uint, tip-count: uint }
)

;; private functions
(define-private (evaluate-tier (creator principal) (total-earned uint))
  (let
    (
      (new-tier
        (if (>= total-earned tier-platinum)
          tier-platinum-id
          (if (>= total-earned tier-gold)
            tier-gold-id
            (if (>= total-earned tier-silver)
              tier-silver-id
              (if (>= total-earned tier-bronze)
                tier-bronze-id
                tier-none)))))
      (new-bonus
        (if (is-eq new-tier tier-platinum-id)
          bonus-platinum
          (if (is-eq new-tier tier-gold-id)
            bonus-gold
            (if (is-eq new-tier tier-silver-id)
              bonus-silver
              (if (is-eq new-tier tier-bronze-id)
                bonus-bronze
                u0)))))
    )
    (map-set creator-tiers { creator: creator } { tier: new-tier })
    (map-set creator-bonuses { creator: creator } { bonus: new-bonus })
    new-tier
  )
)

(define-private (calculate-fee-with-bonus (base-fee uint) (creator principal))
  (let
    (
      (bonus-info (map-get? creator-bonuses { creator: creator }))
      (bonus (match bonus-info bonus-data (get bonus bonus-data) u0))
      (discount (/ (* base-fee bonus) u100))
    )
    (- base-fee discount)
  )
)

;; public functions
(define-public (register-content (title (string-ascii 100)) (payment-amount uint))
  (let
    (
      (content-id (var-get next-content-id))
      (creator tx-sender)
      (current-block burn-block-height)
    )
    (asserts! (not (var-get is-paused)) err-unauthorized)
    (asserts! (>= payment-amount min-payment-amount) err-invalid-amount)
    (asserts! (<= payment-amount max-payment-amount) err-invalid-amount)
    
    (map-set content-registry
      { content-id: content-id }
      {
        creator: creator,
        title: title,
        payment-amount: payment-amount,
        total-views: u0,
        total-earned: u0,
        is-active: true,
        created-at: current-block
      }
    )
    
    (match (map-get? creator-content-count { creator: creator })
      existing-count (map-set creator-content-count 
        { creator: creator }
        { count: (+ (get count existing-count) u1) })
      (map-set creator-content-count 
        { creator: creator }
        { count: u1 })
    )
    
    (var-set next-content-id (+ content-id u1))
    (var-set total-content-count (+ (var-get total-content-count) u1))
    
    (ok content-id)
  )
)

(define-public (pay-for-content (content-id uint))
  (let
    (
      (viewer tx-sender)
      (content-info (unwrap! (map-get? content-registry { content-id: content-id }) err-not-found))
      (payment-amount (get payment-amount content-info))
      (creator (get creator content-info))
      (current-block burn-block-height)
      (subscription-info (map-get? user-subscriptions { subscriber: viewer, creator: creator }))
    )
    (asserts! (not (var-get is-paused)) err-unauthorized)
    (asserts! (get is-active content-info) err-not-found)
    
    (if (and (is-some subscription-info) (> (get expires-at (unwrap-panic subscription-info)) current-block))
      (begin
        (map-set content-registry
          { content-id: content-id }
          (merge content-info {
            total-views: (+ (get total-views content-info) u1)
          })
        )
        
        (match (map-get? content-views { viewer: viewer, content-id: content-id })
          existing-view (map-set content-views
            { viewer: viewer, content-id: content-id }
            {
              view-count: (+ (get view-count existing-view) u1),
              last-viewed: current-block
            })
          (map-set content-views
            { viewer: viewer, content-id: content-id }
            {
              view-count: u1,
              last-viewed: current-block
            })
        )
        
        (ok true)
      )
      (let
        (
          (base-fee (/ (* payment-amount platform-fee-percentage) u100))
          (platform-fee (calculate-fee-with-bonus base-fee creator))
          (creator-payment (- payment-amount platform-fee))
          (payment-id (var-get next-payment-id))
        )
        (asserts! (>= (stx-get-balance viewer) payment-amount) err-insufficient-payment)
        
        (try! (stx-transfer? creator-payment viewer creator))
    (var-set platform-balance (+ (var-get platform-balance) platform-fee))
    
    (map-set content-registry
      { content-id: content-id }
      (merge content-info {
        total-views: (+ (get total-views content-info) u1),
        total-earned: (+ (get total-earned content-info) creator-payment)
      })
    )
    
    (match (map-get? creator-balances { creator: creator })
      existing-balance (begin
        (let
          (
            (new-balance (+ (get balance existing-balance) creator-payment))
          )
          (map-set creator-balances 
            { creator: creator }
            { balance: new-balance })
          (evaluate-tier creator new-balance)
        )
      )
      (begin
        (map-set creator-balances 
          { creator: creator }
          { balance: creator-payment })
        u0
      )
    )
    
    (match (map-get? content-views { viewer: viewer, content-id: content-id })
      existing-view (map-set content-views
        { viewer: viewer, content-id: content-id }
        {
          view-count: (+ (get view-count existing-view) u1),
          last-viewed: current-block
        })
      (map-set content-views
        { viewer: viewer, content-id: content-id }
        {
          view-count: u1,
          last-viewed: current-block
        })
    )
    
    (map-set payment-history
      { payment-id: payment-id }
      {
        viewer: viewer,
        creator: creator,
        content-id: content-id,
        amount: creator-payment,
        timestamp: current-block
      }
    )
    
        (var-set next-payment-id (+ payment-id u1))
        
        (ok true)
      )
    )
  )
)

(define-public (withdraw-earnings)
  (let
    (
      (creator tx-sender)
      (balance-info (unwrap! (map-get? creator-balances { creator: creator }) err-no-balance))
      (withdrawal-amount (get balance balance-info))
    )
    (asserts! (> withdrawal-amount u0) err-no-balance)
    
    (map-set creator-balances
      { creator: creator }
      { balance: u0 }
    )
    
    (try! (as-contract (stx-transfer? withdrawal-amount tx-sender creator)))
    
    (ok withdrawal-amount)
  )
)

(define-public (deactivate-content (content-id uint))
  (let
    (
      (content-info (unwrap! (map-get? content-registry { content-id: content-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender (get creator content-info)) err-unauthorized)
    
    (map-set content-registry
      { content-id: content-id }
      (merge content-info { is-active: false })
    )
    
    (ok true)
  )
)

(define-public (reactivate-content (content-id uint))
  (let
    (
      (content-info (unwrap! (map-get? content-registry { content-id: content-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender (get creator content-info)) err-unauthorized)
    
    (map-set content-registry
      { content-id: content-id }
      (merge content-info { is-active: true })
    )
    
    (ok true)
  )
)

(define-public (update-payment-amount (content-id uint) (new-amount uint))
  (let
    (
      (content-info (unwrap! (map-get? content-registry { content-id: content-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender (get creator content-info)) err-unauthorized)
    (asserts! (>= new-amount min-payment-amount) err-invalid-amount)
    (asserts! (<= new-amount max-payment-amount) err-invalid-amount)
    
    (map-set content-registry
      { content-id: content-id }
      (merge content-info { payment-amount: new-amount })
    )
    
    (ok true)
  )
)

(define-public (create-subscription-plan (monthly-price uint) (duration-blocks uint))
  (let
    (
      (creator tx-sender)
      (current-block burn-block-height)
    )
    (asserts! (not (var-get is-paused)) err-unauthorized)
    (asserts! (>= monthly-price min-payment-amount) err-invalid-amount)
    (asserts! (<= monthly-price max-payment-amount) err-invalid-amount)
    (asserts! (> duration-blocks u0) err-invalid-subscription)
    
    (map-set subscription-plans
      { creator: creator }
      {
        monthly-price: monthly-price,
        duration-blocks: duration-blocks,
        is-active: true,
        total-subscribers: u0,
        created-at: current-block
      }
    )
    
    (ok true)
  )
)

(define-public (toggle-subscription-plan)
  (let
    (
      (creator tx-sender)
      (plan-info (unwrap! (map-get? subscription-plans { creator: creator }) err-not-found))
    )
    (map-set subscription-plans
      { creator: creator }
      (merge plan-info { is-active: (not (get is-active plan-info)) })
    )
    
    (ok true)
  )
)

(define-public (subscribe-to-creator (creator principal))
  (let
    (
      (subscriber tx-sender)
      (plan-info (unwrap! (map-get? subscription-plans { creator: creator }) err-not-found))
      (monthly-price (get monthly-price plan-info))
      (duration-blocks (get duration-blocks plan-info))
      (platform-fee (/ (* monthly-price platform-fee-percentage) u100))
      (creator-payment (- monthly-price platform-fee))
      (current-block burn-block-height)
      (subscription-id (var-get next-subscription-id))
      (current-expiry (default-to u0 (get expires-at (map-get? user-subscriptions { subscriber: subscriber, creator: creator }))))
      (new-expiry (+ (if (> current-expiry current-block) current-expiry current-block) duration-blocks))
    )
    (asserts! (not (var-get is-paused)) err-unauthorized)
    (asserts! (get is-active plan-info) err-invalid-subscription)
    (asserts! (>= (stx-get-balance subscriber) monthly-price) err-insufficient-payment)
    
    (try! (stx-transfer? creator-payment subscriber creator))
    (var-set platform-balance (+ (var-get platform-balance) platform-fee))
    
    (match (map-get? creator-balances { creator: creator })
      existing-balance (map-set creator-balances
        { creator: creator }
        { balance: (+ (get balance existing-balance) creator-payment) })
      (map-set creator-balances
        { creator: creator }
        { balance: creator-payment })
    )
    
    (map-set subscription-plans
      { creator: creator }
      (merge plan-info { total-subscribers: (+ (get total-subscribers plan-info) u1) })
    )
    
    (map-set user-subscriptions
      { subscriber: subscriber, creator: creator }
      {
        expires-at: new-expiry,
        subscription-id: subscription-id,
        auto-renew: false,
        created-at: current-block
      }
    )
    
    (map-set subscription-history
      { subscription-id: subscription-id }
      {
        subscriber: subscriber,
        creator: creator,
        amount: creator-payment,
        duration-blocks: duration-blocks,
        timestamp: current-block
      }
    )
    
    (var-set next-subscription-id (+ subscription-id u1))
    
    (ok subscription-id)
  )
)

(define-public (pause-contract)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set is-paused true)
    (ok true)
  )
)

(define-public (unpause-contract)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set is-paused false)
    (ok true)
  )
)

(define-public (withdraw-platform-fees)
  (let
    (
      (fee-balance (var-get platform-balance))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> fee-balance u0) err-no-balance)
    
    (var-set platform-balance u0)
    (try! (as-contract (stx-transfer? fee-balance tx-sender contract-owner)))
    
    (ok fee-balance)
  )
)

(define-public (tip-creator (content-id uint) (tip-amount uint) (message (optional (string-ascii 200))))
  (let
    (
      (tipper tx-sender)
      (content-info (unwrap! (map-get? content-registry { content-id: content-id }) err-not-found))
      (creator (get creator content-info))
      (current-block burn-block-height)
      (tip-id (var-get next-tip-id))
    )
    (asserts! (not (var-get is-paused)) err-unauthorized)
    (asserts! (get is-active content-info) err-not-found)
    (asserts! (>= tip-amount min-tip-amount) err-invalid-tip)
    (asserts! (>= (stx-get-balance tipper) tip-amount) err-insufficient-payment)
    
    (try! (stx-transfer? tip-amount tipper creator))
    
    (match (map-get? creator-balances { creator: creator })
      existing-balance (begin
        (let
          (
            (new-balance (+ (get balance existing-balance) tip-amount))
          )
          (map-set creator-balances 
            { creator: creator }
            { balance: new-balance })
          (evaluate-tier creator new-balance)
        )
      )
      (begin
        (map-set creator-balances 
          { creator: creator }
          { balance: tip-amount })
        u0
      )
    )
    
    (match (map-get? creator-tips-received { creator: creator })
      existing-tips (begin
        (map-set creator-tips-received
          { creator: creator }
          {
            total-tips: (+ (get total-tips existing-tips) tip-amount),
            tip-count: (+ (get tip-count existing-tips) u1)
          })
        true
      )
      (begin
        (map-set creator-tips-received
          { creator: creator }
          { total-tips: tip-amount, tip-count: u1 })
        true
      )
    )
    
    (match (map-get? content-tips { content-id: content-id })
      existing-tips (begin
        (map-set content-tips
          { content-id: content-id }
          {
            total-tips: (+ (get total-tips existing-tips) tip-amount),
            tip-count: (+ (get tip-count existing-tips) u1)
          })
        true
      )
      (begin
        (map-set content-tips
          { content-id: content-id }
          { total-tips: tip-amount, tip-count: u1 })
        true
      )
    )
    
    (map-set tip-history
      { tip-id: tip-id }
      {
        tipper: tipper,
        creator: creator,
        content-id: content-id,
        amount: tip-amount,
        timestamp: current-block,
        message: message
      }
    )
    
    (var-set next-tip-id (+ tip-id u1))
    
    (ok tip-id)
  )
)

;; read only functions
(define-read-only (get-content-info (content-id uint))
  (map-get? content-registry { content-id: content-id })
)

(define-read-only (get-creator-balance (creator principal))
  (default-to { balance: u0 } (map-get? creator-balances { creator: creator }))
)

(define-read-only (get-content-views (viewer principal) (content-id uint))
  (map-get? content-views { viewer: viewer, content-id: content-id })
)

(define-read-only (get-creator-content-count (creator principal))
  (default-to { count: u0 } (map-get? creator-content-count { creator: creator }))
)

(define-read-only (get-payment-history (payment-id uint))
  (map-get? payment-history { payment-id: payment-id })
)

(define-read-only (get-platform-stats)
  {
    total-content: (var-get total-content-count),
    platform-balance: (var-get platform-balance),
    is-paused: (var-get is-paused),
    next-content-id: (var-get next-content-id),
    min-payment: min-payment-amount,
    max-payment: max-payment-amount,
    platform-fee: platform-fee-percentage
  }
)

(define-read-only (is-contract-paused)
  (var-get is-paused)
)

(define-read-only (get-contract-owner)
  contract-owner
)

(define-read-only (get-subscription-plan (creator principal))
  (map-get? subscription-plans { creator: creator })
)

(define-read-only (get-user-subscription (subscriber principal) (creator principal))
  (map-get? user-subscriptions { subscriber: subscriber, creator: creator })
)

(define-read-only (is-subscription-active (subscriber principal) (creator principal))
  (match (map-get? user-subscriptions { subscriber: subscriber, creator: creator })
    subscription-info (> (get expires-at subscription-info) burn-block-height)
    false
  )
)

(define-read-only (get-subscription-history (subscription-id uint))
  (map-get? subscription-history { subscription-id: subscription-id })
)

(define-read-only (get-subscription-expiry (subscriber principal) (creator principal))
  (match (map-get? user-subscriptions { subscriber: subscriber, creator: creator })
    subscription-info (some (get expires-at subscription-info))
    none
  )
)

(define-read-only (get-creator-tier (creator principal))
  (match (map-get? creator-tiers { creator: creator })
    tier-data (get tier tier-data)
    tier-none)
)

(define-read-only (get-creator-bonus (creator principal))
  (match (map-get? creator-bonuses { creator: creator })
    bonus-data (get bonus bonus-data)
    u0)
)

(define-read-only (get-next-tier-threshold (creator principal))
  (let
    (
      (current-tier (get-creator-tier creator))
    )
    (if (is-eq current-tier tier-platinum-id)
      (ok u0)
      (if (is-eq current-tier tier-gold-id)
        (ok tier-platinum)
        (if (is-eq current-tier tier-silver-id)
          (ok tier-gold)
          (if (is-eq current-tier tier-bronze-id)
            (ok tier-silver)
            (ok tier-bronze)))))
  )
)

(define-read-only (get-tier-info (creator principal))
  (ok {
    tier: (get-creator-tier creator),
    bonus: (get-creator-bonus creator),
    balance: (get balance (get-creator-balance creator))
  })
)

(define-read-only (get-tip-history (tip-id uint))
  (map-get? tip-history { tip-id: tip-id })
)

(define-read-only (get-creator-tips (creator principal))
  (default-to { total-tips: u0, tip-count: u0 } (map-get? creator-tips-received { creator: creator }))
)

(define-read-only (get-content-tips (content-id uint))
  (default-to { total-tips: u0, tip-count: u0 } (map-get? content-tips { content-id: content-id }))
)

(define-read-only (get-tipping-stats)
  (ok {
    next-tip-id: (var-get next-tip-id),
    min-tip-amount: min-tip-amount
  })
)
