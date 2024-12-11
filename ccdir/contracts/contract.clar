;; CommunityCredits (CCR) Token Contract - Stage 2
;; Enhanced security with suspension, verification, and restrictions

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u1))
(define-constant ERR_SUSPENDED (err u2))
(define-constant ERR_RESTRICTED (err u3))
(define-constant ERR_INSUFFICIENT_BALANCE (err u4))
(define-constant ERR_SELF_TRANSFER (err u5))

;; Data Variables
(define-data-var system-suspended bool false)

;; Data Maps
(define-map credit-balances principal uint)
(define-map restricted-participants principal bool)
(define-map verifier-status principal bool)

;; Private Functions
(define-private (is-verifier (account principal))
    (or (is-eq account CONTRACT_OWNER)
        (default-to false (map-get? verifier-status account))))

(define-private (validate-transfer (sender principal) (recipient principal))
    (begin
        (asserts! (not (var-get system-suspended)) ERR_SUSPENDED)
        (asserts! (not (is-eq sender recipient)) ERR_SELF_TRANSFER)
        (asserts! (not (is-restricted sender)) ERR_RESTRICTED)
        (asserts! (not (is-restricted recipient)) ERR_RESTRICTED)
        (ok true)))

;; Verifier Management
(define-public (add-verifier (verifier principal))
    (begin
        (asserts! (is-verifier tx-sender) ERR_NOT_AUTHORIZED)
        (map-set verifier-status verifier true)
        (ok true)))

(define-public (remove-verifier (verifier principal))
    (begin
        (asserts! (is-verifier tx-sender) ERR_NOT_AUTHORIZED)
        (map-set verifier-status verifier false)
        (ok true)))

;; System Control
(define-public (suspend-system)
    (begin
        (asserts! (is-verifier tx-sender) ERR_NOT_AUTHORIZED)
        (var-set system-suspended true)
        (ok true)))

(define-public (resume-system)
    (begin
        (asserts! (is-verifier tx-sender) ERR_NOT_AUTHORIZED)
        (var-set system-suspended false)
        (ok true)))

;; Participant Restriction
(define-public (restrict-participant (address principal))
    (begin
        (asserts! (is-verifier tx-sender) ERR_NOT_AUTHORIZED)
        (map-set restricted-participants address true)
        (ok true)))

(define-public (remove-restriction (address principal))
    (begin
        (asserts! (is-verifier tx-sender) ERR_NOT_AUTHORIZED)
        (map-set restricted-participants address false)
        (ok true)))

(define-read-only (is-restricted (address principal))
    (default-to false (map-get? restricted-participants address)))

;; Public Transfer Function
(define-public (transfer-credits (amount uint) (recipient principal))
    (let ((sender tx-sender)
          (sender-balance (default-to u0 (map-get? credit-balances sender))))
        (try! (validate-transfer sender recipient))
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
    (map-set credit-balances CONTRACT_OWNER u1000000)
    ;; Set contract owner as initial verifier
    (map-set verifier-status CONTRACT_OWNER true))