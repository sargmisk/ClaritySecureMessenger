;; ENHANCED-MESSAGING-CONTRACT - Improved Implementation
;; Advanced messaging with inbox management and message status tracking

;; Error constants
(define-constant ERR-USER-EXISTS u2001)
(define-constant ERR-USER-NOT-FOUND u2002)
(define-constant ERR-UNAUTHORIZED u2003)
(define-constant ERR-MESSAGE-NOT-FOUND u2004)
(define-constant ERR-INBOX-FULL u2005)

;; System configuration
(define-constant MAX-MESSAGE-LENGTH u1024)
(define-constant MAX-INBOX-SIZE u20)

;; System state variables
(define-data-var total-users uint u0)
(define-data-var message-id-counter uint u0)

;; Enhanced user storage with encryption keys
(define-map registered-users principal 
  {
    active: bool,
    public-key: (buff 33),
    registration-block: uint,
    message-count: uint
  }
)

;; Enhanced message storage with timestamps and read status
(define-map stored-messages uint 
  {
    sender: principal,
    recipient: principal,
    message: (buff 1024),
    timestamp: uint,
    is-read: bool,
    priority: uint
  }
)

;; User inbox management
(define-map user-inboxes principal (list 20 uint))

;; Message thread tracking
(define-map message-threads principal (list 20 principal))

;; Get current timestamp
(define-private (get-timestamp)
  (default-to u0 (get-block-info? time u0))
)

;; Check if user is registered
(define-read-only (is-user-registered (user principal))
  (is-some (map-get? registered-users user))
)

;; Get user profile
(define-read-only (get-user-profile (user principal))
  (map-get? registered-users user)
)

;; Get message details
(define-read-only (get-message-details (msg-id uint))
  (map-get? stored-messages msg-id)
)

;; Get user's inbox
(define-read-only (get-user-inbox (user principal))
  (default-to (list) (map-get? user-inboxes user))
)

;; Get user's conversation threads
(define-read-only (get-conversation-threads (user principal))
  (default-to (list) (map-get? message-threads user))
)

;; Get system statistics
(define-read-only (get-system-stats)
  {
    total-users: (var-get total-users),
    total-messages: (var-get message-id-counter)
  }
)

;; Register user with public key
(define-public (register-user-with-key (pub-key (buff 33)))
  (let (
    (user tx-sender)
    (current-time (get-timestamp))
  )
    ;; Ensure user doesn't already exist
    (asserts! (not (is-user-registered user)) (err ERR-USER-EXISTS))
    
    ;; Register the user with enhanced profile
    (map-set registered-users user
      {
        active: true,
        public-key: pub-key,
        registration-block: current-time,
        message-count: u0
      }
    )
    
    ;; Initialize empty inbox
    (map-set user-inboxes user (list))
    
    ;; Initialize empty conversation threads
    (map-set message-threads user (list))
    
    ;; Update counter
    (var-set total-users (+ (var-get total-users) u1))
    (ok true)
  )
)

;; Send message with priority
(define-public (send-priority-message (to principal) (content (buff 1024)) (priority uint))
  (let (
    (from tx-sender)
    (msg-id (var-get message-id-counter))
    (current-time (get-timestamp))
    (sender-info (unwrap! (get-user-profile from) (err ERR-USER-NOT-FOUND)))
    (recipient-inbox (get-user-inbox to))
    (recipient-threads (get-conversation-threads to))
  )
    ;; Verify sender is registered
    (asserts! (is-user-registered from) (err ERR-USER-NOT-FOUND))
    
    ;; Verify recipient is registered
    (asserts! (is-user-registered to) (err ERR-USER-NOT-FOUND))
    
    ;; Check inbox capacity
    (asserts! (< (len recipient-inbox) MAX-INBOX-SIZE) (err ERR-INBOX-FULL))
    
    ;; Store the message
    (map-set stored-messages msg-id
      {
        sender: from,
        recipient: to,
        message: content,
        timestamp: current-time,
        is-read: false,
        priority: priority
      }
    )
    
    ;; Add to recipient's inbox
    (map-set user-inboxes to
      (unwrap-panic (as-max-len? (append recipient-inbox msg-id) u20))
    )
    
    ;; Update conversation threads
    (if (is-none (index-of recipient-threads from))
        (map-set message-threads to
          (unwrap-panic (as-max-len? (append recipient-threads from) u20)))
        true
    )
    
    ;; Update sender's message count
    (map-set registered-users from
      (merge sender-info {
        message-count: (+ (get message-count sender-info) u1)
      })
    )
    
    ;; Increment message counter
    (var-set message-id-counter (+ msg-id u1))
    
    (ok msg-id)
  )
)

;; Mark message as read
(define-public (mark-message-read (msg-id uint))
  (let (
    (user tx-sender)
    (message-info (unwrap! (get-message-details msg-id) (err ERR-MESSAGE-NOT-FOUND)))
  )
    ;; Verify user is the recipient
    (asserts! (is-eq (get recipient message-info) user) (err ERR-UNAUTHORIZED))
    
    ;; Update read status
    (map-set stored-messages msg-id
      (merge message-info { is-read: true })
    )
    
    (ok true)
  )
)

;; Get unread message count for user
(define-read-only (get-unread-count (user principal))
  (let (
    (inbox (get-user-inbox user))
  )
    (fold count-unread inbox u0)
  )
)

;; Helper function to count unread messages
(define-private (count-unread (msg-id uint) (count uint))
  (let (
    (msg-info (get-message-details msg-id))
  )
    (if (and (is-some msg-info) (not (get is-read (unwrap-panic msg-info))))
        (+ count u1)
        count
    )
  )
)