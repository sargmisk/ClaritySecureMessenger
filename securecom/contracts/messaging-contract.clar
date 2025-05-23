;; BASIC-MESSAGING-CONTRACT - Initial Implementation
;; Simple peer-to-peer messaging with user registration

;; Error constants
(define-constant ERR-USER-EXISTS u1001)
(define-constant ERR-USER-NOT-FOUND u1002)
(define-constant ERR-UNAUTHORIZED u1003)

;; Basic configuration
(define-constant MAX-MESSAGE-LENGTH u512)

;; System counters
(define-data-var total-users uint u0)
(define-data-var message-id-counter uint u0)

;; User registration storage
(define-map registered-users principal 
  {
    active: bool,
    registration-block: uint
  }
)

;; Simple message storage
(define-map stored-messages uint 
  {
    sender: principal,
    recipient: principal,
    message: (buff 512),
    block-height: uint
  }
)

;; Get current block height
(define-private (get-block-height)
  (default-to u0 (get-block-info? height u0))
)

;; Check if user is registered
(define-read-only (is-user-registered (user principal))
  (is-some (map-get? registered-users user))
)

;; Get user info
(define-read-only (get-user-info (user principal))
  (map-get? registered-users user)
)

;; Get message by ID
(define-read-only (get-message-by-id (msg-id uint))
  (map-get? stored-messages msg-id)
)

;; Get system statistics
(define-read-only (get-stats)
  {
    users: (var-get total-users),
    messages: (var-get message-id-counter)
  }
)

;; Register a new user
(define-public (register-user)
  (let (
    (user tx-sender)
    (current-block (get-block-height))
  )
    ;; Ensure user doesn't already exist
    (asserts! (not (is-user-registered user)) (err ERR-USER-EXISTS))
    
    ;; Register the user
    (map-set registered-users user
      {
        active: true,
        registration-block: current-block
      }
    )
    
    ;; Update counter
    (var-set total-users (+ (var-get total-users) u1))
    (ok true)
  )
)

;; Send a message
(define-public (send-message (to principal) (content (buff 512)))
  (let (
    (from tx-sender)
    (msg-id (var-get message-id-counter))
    (current-block (get-block-height))
  )
    ;; Verify sender is registered
    (asserts! (is-user-registered from) (err ERR-USER-NOT-FOUND))
    
    ;; Verify recipient is registered
    (asserts! (is-user-registered to) (err ERR-USER-NOT-FOUND))
    
    ;; Store the message
    (map-set stored-messages msg-id
      {
        sender: from,
        recipient: to,
        message: content,
        block-height: current-block
      }
    )
    
    ;; Increment message counter
    (var-set message-id-counter (+ msg-id u1))
    
    (ok msg-id)
  )
)