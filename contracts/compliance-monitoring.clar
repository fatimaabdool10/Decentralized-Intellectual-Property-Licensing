;; Compliance Monitoring Contract
;; Tracks adherence to license terms

(define-map usage-reports
  { license-id: uint, report-id: uint }
  {
    reporter: principal,
    usage-metric: uint,
    timestamp: uint,
    details: (string-ascii 500),
    is-verified: bool
  }
)

(define-map license-report-count
  { license-id: uint }
  { count: uint }
)

(define-map compliance-violations
  { license-id: uint, violation-id: uint }
  {
    reporter: principal,
    description: (string-ascii 500),
    timestamp: uint,
    is-resolved: bool
  }
)

(define-map license-violation-count
  { license-id: uint }
  { count: uint }
)

(define-map license-registry
  { license-id: uint }
  {
    licensor: principal,
    licensee: principal,
    is-active: bool
  }
)

(define-read-only (get-usage-report (license-id uint) (report-id uint))
  (map-get? usage-reports { license-id: license-id, report-id: report-id })
)

(define-read-only (get-report-count (license-id uint))
  (default-to { count: u0 } (map-get? license-report-count { license-id: license-id }))
)

(define-read-only (get-violation (license-id uint) (violation-id uint))
  (map-get? compliance-violations { license-id: license-id, violation-id: violation-id })
)

(define-read-only (get-violation-count (license-id uint))
  (default-to { count: u0 } (map-get? license-violation-count { license-id: license-id }))
)

(define-public (register-license (license-id uint) (licensor principal) (licensee principal))
  (begin
    (map-set license-registry
      { license-id: license-id }
      {
        licensor: licensor,
        licensee: licensee,
        is-active: true
      }
    )
    (ok true)
  )
)

(define-public (submit-usage-report
    (license-id uint)
    (usage-metric uint)
    (details (string-ascii 500))
  )
  (let
    (
      (license-data (unwrap! (map-get? license-registry { license-id: license-id }) (err u1)))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
      (current-count (get count (get-report-count license-id)))
      (new-report-id (+ current-count u1))
    )
    ;; Only licensee or licensor can submit reports
    (asserts! (or
      (is-eq tx-sender (get licensee license-data))
      (is-eq tx-sender (get licensor license-data))
    ) (err u2))

    ;; License must be active
    (asserts! (get is-active license-data) (err u3))

    ;; Store the report
    (map-set usage-reports
      { license-id: license-id, report-id: new-report-id }
      {
        reporter: tx-sender,
        usage-metric: usage-metric,
        timestamp: current-time,
        details: details,
        is-verified: (is-eq tx-sender (get licensor license-data))
      }
    )

    ;; Update the report count
    (map-set license-report-count
      { license-id: license-id }
      { count: new-report-id }
    )

    (ok new-report-id)
  )
)

(define-public (verify-usage-report (license-id uint) (report-id uint))
  (let
    (
      (license-data (unwrap! (map-get? license-registry { license-id: license-id }) (err u1)))
      (report-data (unwrap! (map-get? usage-reports { license-id: license-id, report-id: report-id }) (err u4)))
    )
    ;; Only licensor can verify reports
    (asserts! (is-eq tx-sender (get licensor license-data)) (err u5))

    ;; Update the report verification status
    (map-set usage-reports
      { license-id: license-id, report-id: report-id }
      (merge report-data { is-verified: true })
    )

    (ok true)
  )
)

(define-public (report-violation
    (license-id uint)
    (description (string-ascii 500))
  )
  (let
    (
      (license-data (unwrap! (map-get? license-registry { license-id: license-id }) (err u1)))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
      (current-count (get count (get-violation-count license-id)))
      (new-violation-id (+ current-count u1))
    )
    ;; Only licensor can report violations
    (asserts! (is-eq tx-sender (get licensor license-data)) (err u5))

    ;; Store the violation
    (map-set compliance-violations
      { license-id: license-id, violation-id: new-violation-id }
      {
        reporter: tx-sender,
        description: description,
        timestamp: current-time,
        is-resolved: false
      }
    )

    ;; Update the violation count
    (map-set license-violation-count
      { license-id: license-id }
      { count: new-violation-id }
    )

    (ok new-violation-id)
  )
)

(define-public (resolve-violation (license-id uint) (violation-id uint))
  (let
    (
      (license-data (unwrap! (map-get? license-registry { license-id: license-id }) (err u1)))
      (violation-data (unwrap! (map-get? compliance-violations { license-id: license-id, violation-id: violation-id }) (err u6)))
    )
    ;; Only licensor can resolve violations
    (asserts! (is-eq tx-sender (get licensor license-data)) (err u5))

    ;; Update the violation resolution status
    (map-set compliance-violations
      { license-id: license-id, violation-id: violation-id }
      (merge violation-data { is-resolved: true })
    )

    (ok true)
  )
)

