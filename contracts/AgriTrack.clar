;; Agriculture Supply Chain Management Smart Contract
;; Implements tracking, quality control, and stakeholder management

;; Constants
(define-constant contract-owner tx-sender)
(define-constant ERROR-NOT-AUTHORIZED (err u1))
(define-constant ERROR-PRODUCT-DOES-NOT-EXIST (err u2))
(define-constant ERROR-INVALID-STATUS-CHANGE (err u3))
(define-constant ERROR-EXISTING-RECORD (err u4))
(define-constant ERROR-INVALID-DATA (err u5))

;; Data Variables
(define-data-var required-quality-score uint u60)

;; Principal Maps
(define-map stakeholder-registry
    principal
    {
        stakeholder-type: (string-ascii 20),
        stakeholder-active: bool,
        stakeholder-score: uint
    }
)

;; Product Structure
(define-map product-registry
    uint  ;; product-id
    {
        product-title: (string-ascii 50),
        original-producer: principal,
        current-owner: principal,
        product-phase: (string-ascii 20),
        quality-score: uint,
        creation-time: uint,
        current-position: (string-ascii 100),
        current-price: uint,
        quality-verified: bool
    }
)

;; Transaction History
(define-map chain-transactions
    {product-id: uint, transaction-id: uint}
    {
        transaction-from: principal,
        transaction-to: principal,
        transaction-category: (string-ascii 20),
        transaction-time: uint,
        transaction-details: (string-ascii 200)
    }
)

;; Counter for transaction IDs
(define-data-var transaction-sequence uint u0)

;; Read-only functions
(define-read-only (get-product-details (product-id uint))
    (map-get? product-registry product-id)
)

(define-read-only (get-stakeholder-info (stakeholder-address principal))
    (map-get? stakeholder-registry stakeholder-address)
)

(define-read-only (get-transaction-details (product-id uint) (transaction-id uint))
    (map-get? chain-transactions {product-id: product-id, transaction-id: transaction-id})
)

;; Internal Functions
(define-private (is-stakeholder-valid (stakeholder-address principal))
    (let ((stakeholder-data (unwrap! (map-get? stakeholder-registry stakeholder-address) false)))
        (get stakeholder-active stakeholder-data)
    )
)

(define-private (get-next-transaction-id)
    (begin
        (var-set transaction-sequence (+ (var-get transaction-sequence) u1))
        (var-get transaction-sequence)
    )
)

;; Input validation functions
(define-private (validate-short-string (input-text (string-ascii 20)))
    (and (>= (len input-text) u1) (<= (len input-text) u20))
)

(define-private (validate-medium-string (input-text (string-ascii 50)))
    (and (>= (len input-text) u1) (<= (len input-text) u50))
)

(define-private (validate-long-string (input-text (string-ascii 100)))
    (and (>= (len input-text) u1) (<= (len input-text) u100))
)

(define-private (validate-extended-string (input-text (string-ascii 200)))
    (and (>= (len input-text) u1) (<= (len input-text) u200))
)

(define-private (validate-number (input-number uint))
    (< input-number u340282366920938463463374607431768211455)  ;; Max uint value
)

;; Administrative Functions
(define-public (register-stakeholder (stakeholder-address principal) (stakeholder-type (string-ascii 20)))
    (begin
        (asserts! (is-eq tx-sender contract-owner) ERROR-NOT-AUTHORIZED)
        (asserts! (is-none (map-get? stakeholder-registry stakeholder-address)) ERROR-EXISTING-RECORD)
        (asserts! (validate-short-string stakeholder-type) ERROR-INVALID-DATA)
        (ok (map-set stakeholder-registry 
            stakeholder-address
            {
                stakeholder-type: stakeholder-type,
                stakeholder-active: true,
                stakeholder-score: u100
            }
        ))
    )
)

(define-public (update-stakeholder-status (stakeholder-address principal) (is-active bool))
    (begin
        (asserts! (is-eq tx-sender contract-owner) ERROR-NOT-AUTHORIZED)
        (asserts! (is-some (map-get? stakeholder-registry stakeholder-address)) ERROR-NOT-AUTHORIZED)
        (ok (map-set stakeholder-registry 
            stakeholder-address
            (merge (unwrap-panic (map-get? stakeholder-registry stakeholder-address))
                  {stakeholder-active: is-active})
        ))
    )
)

;; Product Management Functions
(define-public (register-product 
    (product-id uint)
    (product-title (string-ascii 50))
    (product-position (string-ascii 100))
    (product-price uint))
    (let ((registering-stakeholder tx-sender))
        (begin
            (asserts! (is-stakeholder-valid registering-stakeholder) ERROR-NOT-AUTHORIZED)
            (asserts! (is-none (map-get? product-registry product-id)) ERROR-EXISTING-RECORD)
            (asserts! (validate-number product-id) ERROR-INVALID-DATA)
            (asserts! (validate-medium-string product-title) ERROR-INVALID-DATA)
            (asserts! (validate-long-string product-position) ERROR-INVALID-DATA)
            (asserts! (validate-number product-price) ERROR-INVALID-DATA)
            (ok (map-set product-registry
                product-id
                {
                    product-title: product-title,
                    original-producer: registering-stakeholder,
                    current-owner: registering-stakeholder,
                    product-phase: "registered",
                    quality-score: u100,
                    creation-time: block-height,
                    current-position: product-position,
                    current-price: product-price,
                    quality-verified: false
                }
            ))
        )
    )
)

(define-public (update-product-phase 
    (product-id uint)
    (new-phase (string-ascii 20))
    (phase-notes (string-ascii 200)))
    (let (
        (updating-stakeholder tx-sender)
        (product-data (unwrap! (map-get? product-registry product-id) ERROR-PRODUCT-DOES-NOT-EXIST))
        )
        (begin
            (asserts! (is-stakeholder-valid updating-stakeholder) ERROR-NOT-AUTHORIZED)
            (asserts! (is-eq (get current-owner product-data) updating-stakeholder) ERROR-NOT-AUTHORIZED)
            (asserts! (validate-number product-id) ERROR-INVALID-DATA)
            (asserts! (validate-short-string new-phase) ERROR-INVALID-DATA)
            (asserts! (validate-extended-string phase-notes) ERROR-INVALID-DATA)
            (map-set product-registry
                product-id
                (merge product-data {product-phase: new-phase})
            )
            (map-set chain-transactions
                {product-id: product-id, transaction-id: (get-next-transaction-id)}
                {
                    transaction-from: updating-stakeholder,
                    transaction-to: updating-stakeholder,
                    transaction-category: new-phase,
                    transaction-time: block-height,
                    transaction-details: phase-notes
                }
            )
            (ok true)
        )
    )
)

(define-public (transfer-ownership
    (product-id uint)
    (new-owner principal)
    (transfer-details (string-ascii 200)))
    (let (
        (current-owner tx-sender)
        (product-data (unwrap! (map-get? product-registry product-id) ERROR-PRODUCT-DOES-NOT-EXIST))
        )
        (begin
            (asserts! (is-stakeholder-valid current-owner) ERROR-NOT-AUTHORIZED)
            (asserts! (is-stakeholder-valid new-owner) ERROR-NOT-AUTHORIZED)
            (asserts! (is-eq (get current-owner product-data) current-owner) ERROR-NOT-AUTHORIZED)
            (asserts! (validate-number product-id) ERROR-INVALID-DATA)
            (asserts! (validate-extended-string transfer-details) ERROR-INVALID-DATA)
            (map-set product-registry
                product-id
                (merge product-data {
                    current-owner: new-owner,
                    product-phase: "transferred"
                })
            )
            (map-set chain-transactions
                {product-id: product-id, transaction-id: (get-next-transaction-id)}
                {
                    transaction-from: current-owner,
                    transaction-to: new-owner,
                    transaction-category: "transfer",
                    transaction-time: block-height,
                    transaction-details: transfer-details
                }
            )
            (ok true)
        )
    )
)

(define-public (update-quality
    (product-id uint)
    (new-quality-score uint)
    (quality-details (string-ascii 200)))
    (let (
        (quality-inspector tx-sender)
        (product-data (unwrap! (map-get? product-registry product-id) ERROR-PRODUCT-DOES-NOT-EXIST))
        )
        (begin
            (asserts! (is-stakeholder-valid quality-inspector) ERROR-NOT-AUTHORIZED)
            (asserts! (validate-number product-id) ERROR-INVALID-DATA)
            (asserts! (<= new-quality-score u100) ERROR-INVALID-DATA)
            (asserts! (validate-extended-string quality-details) ERROR-INVALID-DATA)
            (map-set product-registry
                product-id
                (merge product-data {
                    quality-score: new-quality-score,
                    quality-verified: (>= new-quality-score (var-get required-quality-score))
                })
            )
            (map-set chain-transactions
                {product-id: product-id, transaction-id: (get-next-transaction-id)}
                {
                    transaction-from: quality-inspector,
                    transaction-to: quality-inspector,
                    transaction-category: "quality-update",
                    transaction-time: block-height,
                    transaction-details: quality-details
                }
            )
            (ok true)
        )
    )
)

(define-public (update-position
    (product-id uint)
    (new-position (string-ascii 100))
    (position-notes (string-ascii 200)))
    (let (
        (updating-stakeholder tx-sender)
        (product-data (unwrap! (map-get? product-registry product-id) ERROR-PRODUCT-DOES-NOT-EXIST))
        )
        (begin
            (asserts! (is-stakeholder-valid updating-stakeholder) ERROR-NOT-AUTHORIZED)
            (asserts! (is-eq (get current-owner product-data) updating-stakeholder) ERROR-NOT-AUTHORIZED)
            (asserts! (validate-number product-id) ERROR-INVALID-DATA)
            (asserts! (validate-long-string new-position) ERROR-INVALID-DATA)
            (asserts! (validate-extended-string position-notes) ERROR-INVALID-DATA)
            (map-set product-registry
                product-id
                (merge product-data {current-position: new-position})
            )
            (map-set chain-transactions
                {product-id: product-id, transaction-id: (get-next-transaction-id)}
                {
                    transaction-from: updating-stakeholder,
                    transaction-to: updating-stakeholder,
                    transaction-category: "position-update",
                    transaction-time: block-height,
                    transaction-details: position-notes
                }
            )
            (ok true)
        )
    )
)
