;; CommunityCredits (CCR) Token Contract - Stage 1
;; Basic implementation with core token transfer and balance management

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u1))
(define-constant ERR_INSUFFICIENT_BALANCE (err u2))

;; Data Maps
(define-map credit-balances principal uint)

;; Private Functions
(define-private (is-owner (account principal))
    (is-eq account CONTRACT_OWNER))

;; Public Functions
(define-public (transfer-credits (amount uint) (recipient principal))
    (let ((sender tx-sender)
          (sender-balance (default-to u0 (map-get? credit-balances sender))))
        (asserts! (>= sender-balance amount) ERR_INSUFFICIENT_BALANCE)
        
        (map-set credit-balances sender (- sender-balance amount))
        (map-set credit-balances recipient 
            (+ (default-to u0 (map-get? credit-balances recipient)) amount))
        (ok true)))

(define-read-only (get-credit-balance (account principal))
    (map-get? credit-balances account))

;; Initialize contract
(begin
    ;; Set initial balance for contract owner (1 million credits)
    (map-set credit-balances CONTRACT_OWNER u1000000))