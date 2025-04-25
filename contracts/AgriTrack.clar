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
