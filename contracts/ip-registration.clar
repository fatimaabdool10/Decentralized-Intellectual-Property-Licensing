;; IP Registration Contract
;; Records ownership of patents and trademarks

(define-data-var last-ip-id uint u0)

(define-map ip-registry
  { ip-id: uint }
  {
    owner: principal,
    ip-type: (string-ascii 10), ;; "patent" or "trademark"
    name: (string-ascii 100),
    description: (string-ascii 500),
    creation-date: uint,
    expiration-date: uint
  }
)

(define-read-only (get-ip (ip-id uint))
  (map-get? ip-registry { ip-id: ip-id })
)

(define-read-only (get-last-ip-id)
  (var-get last-ip-id)
)

(define-public (register-ip
    (ip-type (string-ascii 10))
    (name (string-ascii 100))
    (description (string-ascii 500))
    (expiration-date uint)
  )
  (let
    (
      (new-id (+ (var-get last-ip-id) u1))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (asserts! (or (is-eq ip-type "patent") (is-eq ip-type "trademark")) (err u1))
    (asserts! (> expiration-date current-time) (err u2))

    (var-set last-ip-id new-id)
    (map-set ip-registry
      { ip-id: new-id }
      {
        owner: tx-sender,
        ip-type: ip-type,
        name: name,
        description: description,
        creation-date: current-time,
        expiration-date: expiration-date
      }
    )
    (ok new-id)
  )
)

(define-public (transfer-ip (ip-id uint) (new-owner principal))
  (let
    (
      (ip-data (unwrap! (map-get? ip-registry { ip-id: ip-id }) (err u3)))
    )
    (asserts! (is-eq (get owner ip-data) tx-sender) (err u4))

    (map-set ip-registry
      { ip-id: ip-id }
      (merge ip-data { owner: new-owner })
    )
    (ok true)
  )
)

(define-public (update-ip-expiration (ip-id uint) (new-expiration-date uint))
  (let
    (
      (ip-data (unwrap! (map-get? ip-registry { ip-id: ip-id }) (err u3)))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (asserts! (is-eq (get owner ip-data) tx-sender) (err u4))
    (asserts! (> new-expiration-date current-time) (err u2))

    (map-set ip-registry
      { ip-id: ip-id }
      (merge ip-data { expiration-date: new-expiration-date })
    )
    (ok true)
  )
)

