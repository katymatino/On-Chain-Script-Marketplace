(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u1))
(define-constant ERR_NOT_FOUND (err u2))
(define-constant ERR_ALREADY_EXISTS (err u3))
(define-constant ERR_INSUFFICIENT_FUNDS (err u4))
(define-constant ERR_ACCESS_DENIED (err u5))
(define-constant ERR_EXPIRED (err u6))
(define-constant ERR_INVALID_PRICE (err u7))
(define-constant ERR_INVALID_DURATION (err u8))

(define-data-var next-script-id uint u1)
(define-data-var platform-fee uint u500)

(define-map scripts
  uint
  {
    writer: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    content-hash: (buff 32),
    price: uint,
    total-sales: uint,
    created-at: uint,
    active: bool
  }
)

(define-map script-access
  {script-id: uint, buyer: principal}
  {
    purchased-at: uint,
    expires-at: uint,
    access-count: uint
  }
)

(define-map writer-earnings principal uint)
(define-map writer-scripts principal (list 100 uint))
(define-map buyer-purchases principal (list 100 uint))

(define-public (register-script (title (string-ascii 100)) 
                               (description (string-ascii 500))
                               (content-hash (buff 32))
                               (price uint))
  (let ((script-id (var-get next-script-id)))
    (asserts! (> price u0) ERR_INVALID_PRICE)
    (asserts! (< (len title) u101) ERR_INVALID_PRICE)
    (asserts! (< (len description) u501) ERR_INVALID_PRICE)
    
    (map-set scripts script-id
      {
        writer: tx-sender,
        title: title,
        description: description,
        content-hash: content-hash,
        price: price,
        total-sales: u0,
        created-at: stacks-block-height,
        active: true
      }
    )
    
    (let ((current-scripts (default-to (list) (map-get? writer-scripts tx-sender))))
      (map-set writer-scripts tx-sender (unwrap! (as-max-len? (append current-scripts script-id) u100) ERR_ALREADY_EXISTS))
    )
    
    (var-set next-script-id (+ script-id u1))
    (ok script-id)
  )
)

(define-public (purchase-access (script-id uint) (duration uint))
  (let ((script-info (unwrap! (map-get? scripts script-id) ERR_NOT_FOUND))
        (current-block stacks-block-height)
        (expires-at (+ current-block duration)))
    
    (asserts! (get active script-info) ERR_NOT_FOUND)
    (asserts! (> duration u0) ERR_INVALID_DURATION)
    (asserts! (<= duration u144000) ERR_INVALID_DURATION)
    
    (let ((total-cost (get price script-info))
          (platform-cut (/ (* total-cost (var-get platform-fee)) u10000))
          (writer-cut (- total-cost platform-cut)))
      
      (try! (stx-transfer? total-cost tx-sender CONTRACT_OWNER))
      
      (map-set script-access 
        {script-id: script-id, buyer: tx-sender}
        {
          purchased-at: current-block,
          expires-at: expires-at,
          access-count: u0
        }
      )
      
      (map-set scripts script-id
        (merge script-info {total-sales: (+ (get total-sales script-info) u1)})
      )
      
      (let ((current-earnings (default-to u0 (map-get? writer-earnings (get writer script-info))))
            (current-purchases (default-to (list) (map-get? buyer-purchases tx-sender))))
        (map-set writer-earnings (get writer script-info) (+ current-earnings writer-cut))
        (map-set buyer-purchases tx-sender (unwrap! (as-max-len? (append current-purchases script-id) u100) ERR_ALREADY_EXISTS))
      )
      
      (ok expires-at)
    )
  )
)

(define-public (access-script (script-id uint))
  (let ((access-info (unwrap! (map-get? script-access {script-id: script-id, buyer: tx-sender}) ERR_ACCESS_DENIED))
        (current-block stacks-block-height))
    
    (asserts! (<= current-block (get expires-at access-info)) ERR_EXPIRED)
    
    (map-set script-access 
      {script-id: script-id, buyer: tx-sender}
      (merge access-info {access-count: (+ (get access-count access-info) u1)})
    )
    
    (ok (unwrap! (map-get? scripts script-id) ERR_NOT_FOUND))
  )
)

(define-public (deactivate-script (script-id uint))
  (let ((script-info (unwrap! (map-get? scripts script-id) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get writer script-info)) ERR_UNAUTHORIZED)
    
    (map-set scripts script-id (merge script-info {active: false}))
    (ok true)
  )
)

(define-public (reactivate-script (script-id uint))
  (let ((script-info (unwrap! (map-get? scripts script-id) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get writer script-info)) ERR_UNAUTHORIZED)
    
    (map-set scripts script-id (merge script-info {active: true}))
    (ok true)
  )
)

(define-public (update-script-price (script-id uint) (new-price uint))
  (let ((script-info (unwrap! (map-get? scripts script-id) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get writer script-info)) ERR_UNAUTHORIZED)
    (asserts! (> new-price u0) ERR_INVALID_PRICE)
    
    (map-set scripts script-id (merge script-info {price: new-price}))
    (ok true)
  )
)

(define-public (withdraw-earnings)
  (let ((earnings (default-to u0 (map-get? writer-earnings tx-sender))))
    (asserts! (> earnings u0) ERR_INSUFFICIENT_FUNDS)
    
    (map-set writer-earnings tx-sender u0)
    (try! (as-contract (stx-transfer? earnings tx-sender tx-sender)))
    (ok earnings)
  )
)

(define-public (set-platform-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (<= new-fee u1000) ERR_INVALID_PRICE)
    (var-set platform-fee new-fee)
    (ok true)
  )
)

(define-read-only (get-script (script-id uint))
  (map-get? scripts script-id)
)

(define-read-only (get-script-access (script-id uint) (buyer principal))
  (map-get? script-access {script-id: script-id, buyer: buyer})
)

(define-read-only (get-writer-earnings (writer principal))
  (default-to u0 (map-get? writer-earnings writer))
)

(define-read-only (get-writer-scripts (writer principal))
  (default-to (list) (map-get? writer-scripts writer))
)

(define-read-only (get-buyer-purchases (buyer principal))
  (default-to (list) (map-get? buyer-purchases buyer))
)

(define-read-only (get-platform-fee)
  (var-get platform-fee)
)

(define-read-only (get-next-script-id)
  (var-get next-script-id)
)

(define-read-only (has-active-access (script-id uint) (buyer principal))
  (match (map-get? script-access {script-id: script-id, buyer: buyer})
    access-info (> (get expires-at access-info) stacks-block-height)
    false
  )
)

(define-read-only (get-script-stats (script-id uint))
  (match (map-get? scripts script-id)
    script-info (some {
      total-sales: (get total-sales script-info),
      writer: (get writer script-info),
      price: (get price script-info),
      active: (get active script-info),
      created-at: (get created-at script-info)
    })
    none
  )
)

(define-read-only (calculate-purchase-cost (script-id uint) (duration uint))
  (match (map-get? scripts script-id)
    script-info 
      (let ((base-price (get price script-info))
            (platform-cut (/ (* base-price (var-get platform-fee)) u10000)))
        (some {
          total-cost: base-price,
          platform-fee: platform-cut,
          writer-earnings: (- base-price platform-cut)
        })
      )
    none
  )
)

(define-read-only (get-access-remaining (script-id uint) (buyer principal))
  (match (map-get? script-access {script-id: script-id, buyer: buyer})
    access-info 
      (if (> (get expires-at access-info) stacks-block-height)
        (some (- (get expires-at access-info) stacks-block-height))
        (some u0)
      )
    none
  )
)

(define-private (is-script-writer (script-id uint) (writer principal))
  (match (map-get? scripts script-id)
    script-info (is-eq writer (get writer script-info))
    false
  )
)

(define-private (calculate-earnings-cut (total-amount uint))
  (let ((platform-cut (/ (* total-amount (var-get platform-fee)) u10000)))
    {
      platform: platform-cut,
      writer: (- total-amount platform-cut)
    }
  )
)
