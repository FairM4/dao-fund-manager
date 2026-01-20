;; ------------------------------------------------------------
;; dao-fund-manager.clar
;; Governance-controlled STX treasury
;; ------------------------------------------------------------

;; ------------------------------------------------------------
;; Error codes
;; ------------------------------------------------------------

(define-constant ERR-NOT-GOVERNANCE u100)
(define-constant ERR-ALREADY-INITIALIZED u101)
(define-constant ERR-INVALID u102)

;; ------------------------------------------------------------
;; Governance authority
;; ------------------------------------------------------------

(define-data-var governance (optional principal) none)

;; ------------------------------------------------------------
;; Initialization (one-time)
;; ------------------------------------------------------------

(define-public (initialize (governance-contract principal))
  (match (var-get governance)
    existing (err ERR-ALREADY-INITIALIZED)
    (begin
      (asserts! (is-standard governance-contract) (err ERR-INVALID))
      (var-set governance (some governance-contract))
      (ok governance-contract)
    )
  )
)

;; ------------------------------------------------------------
;; Internal governance check
;; ------------------------------------------------------------

(define-private (is-governance)
  (match (var-get governance)
    g (is-eq g tx-sender)
    false
  )
)

;; ------------------------------------------------------------
;; Deposit STX into DAO treasury
;; Anyone can fund the DAO
;; ------------------------------------------------------------

(define-public (deposit (amount uint))
  (begin
    (try!
      (stx-transfer?
        amount
        tx-sender
        (as-contract tx-sender)
      )
    )
    (ok amount)
  )
)

;; ------------------------------------------------------------
;; Governance-approved STX payout
;; Called ONLY via dao-core / proposal-exec
;; ------------------------------------------------------------

(define-public (payout (amount uint) (recipient principal))
  (if (not (is-governance))
      (err ERR-NOT-GOVERNANCE)
      (begin
        (asserts! (> amount u0) (err ERR-INVALID))
        (asserts! (is-standard recipient) (err ERR-INVALID))
        (try!
          (stx-transfer?
            amount
            (as-contract tx-sender)
            recipient
          )
        )
        (ok amount)
      )
  )
)

;; ------------------------------------------------------------
;; Emergency sweep (governance only)
;; ------------------------------------------------------------

(define-public (sweep (recipient principal))
  (if (not (is-governance))
      (err ERR-NOT-GOVERNANCE)
      (let
        (
          (balance (stx-get-balance (as-contract tx-sender)))
        )
        (begin
          (asserts! (is-standard recipient) (err ERR-INVALID))
          (try!
            (stx-transfer?
              balance
              (as-contract tx-sender)
              recipient
            )
          )
          (ok balance)
        )
      )
  )
)

;; ------------------------------------------------------------
;; Read-only helpers
;; ------------------------------------------------------------

(define-read-only (get-balance)
  (ok (stx-get-balance (as-contract tx-sender)))
)

(define-read-only (get-governance)
  (var-get governance)
)
