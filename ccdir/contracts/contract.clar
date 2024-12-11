;; CommunityCredits (CCR) Token Contract
;; A secure system for managing community service credits with verification

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u1))
(define-constant ERR_SUSPENDED (err u2))
(define-constant ERR_NOT_SUSPENDED (err u3))
(define-constant ERR_RESTRICTED (err u4))
(define-constant ERR_QUOTA_EXCEEDED (err u5))
(define-constant ERR_INVALID_HOURS (err u6))
(define-constant ERR_INVALID_PARTICIPANT (err u7))
(define-constant ERR_SELF_CREDIT (err u8))
(define-constant DAILY_QUOTA_PERIOD u86400) ;; 24 hours in seconds

;; Data Variables
(define-data-var system-suspended bool false)
(define-data-var total-credits uint u1000000000) ;; 1 billion service credits
(define-data-var quota-check-active bool false)
(define-data-var daily-credit-limit uint u1000)
(define-data-var last-suspension-timestamp uint u0)
(define-data-var current-timestamp uint u0)

;; Data Maps
(define-map credit-balances principal uint)
(define-map restricted-participants principal bool)
(define-map verifier-status principal bool)
(define-map credit-transfer-requests {participant: principal, new-account: principal} bool)
(define-map daily-credit-transfers {user: principal, timestamp: uint} uint)
(define-map balance-records {user: principal, timestamp: uint} uint)

;; Private Functions
(define-private (is-verifier (account principal))
    (or (is-eq account CONTRACT_OWNER)
        (default-to false (map-get? verifier-status account))))

(define-private (get-day-start (timestamp uint))
    (* (/ timestamp DAILY_QUOTA_PERIOD) DAILY_QUOTA_PERIOD))

(define-private (check-daily-quota (participant principal) (amount uint))
    (let ((day-start (get-day-start (var-get current-timestamp)))
          (current-amount (default-to u0 
            (map-get? daily-credit-transfers 
                {user: participant, timestamp: day-start}))))
        (if (and (var-get quota-check-active)
                (> (+ current-amount amount) (var-get daily-credit-limit)))
            ERR_QUOTA_EXCEEDED
            (ok true))))

(define-private (record-balance (address principal))
    (map-set balance-records 
        {user: address, timestamp: (var-get current-timestamp)}
        (default-to u0 (get-credit-balance address))))

(define-private (validate-participant (address principal))
    (if (is-eq address tx-sender)
        ERR_SELF_CREDIT
        (ok true)))

;; Public Functions

;; Timestamp Management
(define-public (update-timestamp (new-timestamp uint))
    (begin
        (asserts! (is-verifier tx-sender) ERR_NOT_AUTHORIZED)
        (var-set current-timestamp new-timestamp)
        (ok true)))

;; Credit Transfer Functions
(define-public (transfer-credits (amount uint) (recipient principal))
    (let ((sender tx-sender)
          (sender-balance (default-to u0 (get-credit-balance sender))))
        (asserts! (not (var-get system-suspended)) ERR_SUSPENDED)
        (asserts! (not (is-restricted sender)) ERR_RESTRICTED)
        (asserts! (not (is-restricted recipient)) ERR_RESTRICTED)
        (asserts! (>= sender-balance amount) ERR_INVALID_HOURS)
        (asserts! (not (is-eq sender recipient)) ERR_SELF_CREDIT)
        (try! (check-daily-quota sender amount))
        
        (let ((day-start (get-day-start (var-get current-timestamp))))
            (map-set daily-credit-transfers 
                {user: sender, timestamp: day-start}
                (+ amount (default-to u0 
                    (map-get? daily-credit-transfers 
                        {user: sender, timestamp: day-start})))))
        
        (map-set credit-balances sender (- sender-balance amount))
        (map-set credit-balances recipient 
            (+ (default-to u0 (get-credit-balance recipient)) amount))
        (ok true)))

(define-read-only (get-credit-balance (account principal))
    (map-get? credit-balances account))

;; Verifier Functions
(define-public (suspend-system)
    (begin
        (asserts! (is-verifier tx-sender) ERR_NOT_AUTHORIZED)
        (var-set system-suspended true)
        (var-set last-suspension-timestamp (var-get current-timestamp))
        (ok true)))

(define-public (resume-system)
    (begin
        (asserts! (is-verifier tx-sender) ERR_NOT_AUTHORIZED)
        (var-set system-suspended false)
        (var-set quota-check-active true)
        (ok true)))

(define-public (add-verifier (verifier principal))
    (begin
        (asserts! (is-verifier tx-sender) ERR_NOT_AUTHORIZED)
        (asserts! (not (is-eq verifier tx-sender)) ERR_SELF_CREDIT)
        (asserts! (not (is-eq verifier CONTRACT_OWNER)) ERR_NOT_AUTHORIZED)
        (map-set verifier-status verifier true)
        (ok true)))

(define-public (remove-verifier (verifier principal))
    (begin
        (asserts! (is-verifier tx-sender) ERR_NOT_AUTHORIZED)
        (asserts! (not (is-eq verifier CONTRACT_OWNER)) ERR_NOT_AUTHORIZED)
        (map-set verifier-status verifier false)
        (ok true)))

;; Restriction Functions
(define-public (restrict-participant (address principal))
    (begin
        (asserts! (is-verifier tx-sender) ERR_NOT_AUTHORIZED)
        (asserts! (not (is-eq address CONTRACT_OWNER)) ERR_NOT_AUTHORIZED)
        (asserts! (not (is-verifier address)) ERR_NOT_AUTHORIZED)
        (map-set restricted-participants address true)
        (record-balance address)
        (ok true)))

(define-public (remove-restriction (address principal))
    (begin
        (asserts! (is-verifier tx-sender) ERR_NOT_AUTHORIZED)
        (asserts! (is-restricted address) ERR_NOT_AUTHORIZED)
        (asserts! (not (is-eq address CONTRACT_OWNER)) ERR_NOT_AUTHORIZED)
        (asserts! (not (is-verifier address)) ERR_NOT_AUTHORIZED)
        (map-set restricted-participants address false)
        (ok true)))

(define-read-only (is-restricted (address principal))
    (default-to false (map-get? restricted-participants address)))

;; Account Recovery
(define-public (request-account-transfer (new-address principal))
    (begin
        (asserts! (var-get system-suspended) ERR_NOT_SUSPENDED)
        (asserts! (not (is-restricted tx-sender)) ERR_RESTRICTED)
        (asserts! (not (is-eq new-address tx-sender)) ERR_SELF_CREDIT)
        (asserts! (not (is-restricted new-address)) ERR_RESTRICTED)
        (map-set credit-transfer-requests {participant: tx-sender, new-account: new-address} true)
        (ok true)))

(define-public (approve-account-transfer (participant principal) (new-address principal))
    (begin
        (asserts! (is-verifier tx-sender) ERR_NOT_AUTHORIZED)
        (asserts! (not (is-eq participant new-address)) ERR_SELF_CREDIT)
        (asserts! (not (is-restricted new-address)) ERR_RESTRICTED)
        (asserts! (default-to false 
            (map-get? credit-transfer-requests {participant: participant, new-account: new-address}))
            ERR_NOT_AUTHORIZED)
        
        (let ((balance (default-to u0 (get-credit-balance participant))))
            (map-set credit-balances participant u0)
            (map-set credit-balances new-address balance)
            (map-delete credit-transfer-requests {participant: participant, new-account: new-address})
            (ok true))))

;; Quota Management
(define-public (set-daily-quota (active bool) (amount uint))
    (begin
        (asserts! (is-verifier tx-sender) ERR_NOT_AUTHORIZED)
        (asserts! (> amount u0) ERR_INVALID_HOURS)
        (var-set quota-check-active active)
        (var-set daily-credit-limit amount)
        (ok true)))

;; Balance History
(define-read-only (get-historical-balance (address principal) (timestamp uint))
    (map-get? balance-records {user: address, timestamp: timestamp}))

;; Initialize contract
(begin
    ;; Set initial balance for contract owner
    (map-set credit-balances CONTRACT_OWNER (var-get total-credits))
    ;; Set contract owner as verifier
    (map-set verifier-status CONTRACT_OWNER true))