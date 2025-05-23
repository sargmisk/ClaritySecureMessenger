;; ADVANCED-MESSAGING-CONTRACT - Production Implementation
;; Full-featured secure messaging with encryption, deletion, and advanced management

;; Error constants
(define-constant ERR-USER-EXISTS u3001)
(define-constant ERR-USER-NOT-FOUND u3002)
(define-constant ERR-UNAUTHORIZED u3003)
(define-constant ERR-MESSAGE-NOT-FOUND u3004)
(define-constant ERR-INBOX-FULL u3005)
(define-constant ERR-MESSAGE-TOO_LARGE u3006)
(define-constant ERR-INVALID-PRIORITY u3007)

;; System configuration constants
(define-constant MAX-MESSAGE-LENGTH u1024)
(define-constant MAX-INBOX-SIZE u25)
(define-constant MIN-PRIORITY u1)
(define-constant MAX-PRIORITY u5)

;; System state management
(define-data-var total-users uint u0)
(define-data-var message-id-counter uint u0)
(define-data-var temp-message-id uint u0)
(define-data-var system-paused bool false)

;; Comprehensive user profiles
(define-map registered-users principal 
  {
    active: bool,
    public-key: (buff 33),
    registration-timestamp: uint,
    sent-message-count: uint,
    received-message-count: uint,
    last-activity: uint
  }
)

;; Full message storage with metadata
(define-map stored-messages uint 
  {
    sender: principal,
    recipient: principal,
    encrypted-content: (buff 1024),
    timestamp: uint,
    is-read: bool,
    priority: uint,
    thread-id: (optional uint),
    expires-at: (optional uint)
  }
)

;; Advanced inbox management
(define-map user-inboxes principal (list 25 uint))

;; Conversation thread management
(define-map conversation-threads principal (list 25 principal))

;; User blocking system
(define-map blocked-users principal (list 10 principal))

;; Message deletion tracking
(define-map deleted-messages uint bool)

;; Get current timestamp
(define-private (get-current-timestamp)
  (default-to u0 (get-block-info? time u0))
)

;; System status check
(define-read-only (is-system-active)
  (not (var-get system-paused))
)

;; Comprehensive user verification
(define-read-only (is-active-user (user principal))
  (match (map-get? registered-users user)
    user-data (get active user-data)
    false
  )
)

;; Get complete user profile
(define-read-only (get-complete-user-profile (user principal))
  (map-get? registered-users user)
)

;; Get message with deletion check
(define-read-only (get-active-message (msg-id uint))
  (if (default-to false (map-get? deleted-messages msg-id))
      none
      (map-get? stored-messages msg-id)
  )
)

;; Get user's complete inbox
(define-read-only (get-complete-inbox (user principal))
  (default-to (list) (map-get? user-inboxes user))
)

;; Get user's conversation list
(define-read-only (get-active-conversations (user principal))
  (default-to (list) (map-get? conversation-threads user))
)

;; Get blocked users list
(define-read-only (get-blocked-users (user principal))
  (default-to (list) (map-get? blocked-users user))
)

;; Get comprehensive system metrics
(define-read-only (get-detailed-system-stats)
  {
    total-registered-users: (var-get total-users),
    total-messages-sent: (var-get message-id-counter),
    system-status: (if (var-get system-paused) "paused" "active")
  }
)

;; Enhanced user registration with validation
(define-public (register-enhanced-user (encryption-key (buff 33)))
  (let (
    (new-user tx-sender)
    (registration-time (get-current-timestamp))
  )
    ;; System availability check
    (asserts! (is-system-active) (err ERR-UNAUTHORIZED))
    
    ;; Prevent duplicate registrations
    (asserts! (not (is-active-user new-user)) (err ERR-USER-EXISTS))
    
    ;; Create comprehensive user profile
    (map-set registered-users new-user
      {
        active: true,
        public-key: encryption-key,
        registration-timestamp: registration-time,
        sent-message-count: u0,
        received-message-count: u0,
        last-activity: registration-time
      }
    )
    
    ;; Initialize user's messaging infrastructure
    (map-set user-inboxes new-user (list))
    (map-set conversation-threads new-user (list))
    (map-set blocked-users new-user (list))
    
    ;; Update system counters
    (var-set total-users (+ (var-get total-users) u1))
    (ok true)
  )
)

;; Advanced message sending with full validation
(define-public (send-secure-message (recipient principal) (encrypted-content (buff 1024)) (priority uint) (expires-in (optional uint)))
  (let (
    (sender tx-sender)
    (msg-id (var-get message-id-counter))
    (current-time (get-current-timestamp))
    (sender-profile (unwrap! (get-complete-user-profile sender) (err ERR-USER-NOT-FOUND)))
    (recipient-profile (unwrap! (get-complete-user-profile recipient) (err ERR-USER-NOT-FOUND)))
    (recipient-inbox (get-complete-inbox recipient))
    (recipient-conversations (get-active-conversations recipient))
    (sender-blocked-list (get-blocked-users recipient))
    (expiry-time (match expires-in
                   exp-duration (some (+ current-time exp-duration))
                   none))
  )
    ;; System and user validation
    (asserts! (is-system-active) (err ERR-UNAUTHORIZED))
    (asserts! (get active sender-profile) (err ERR-USER-NOT-FOUND))
    (asserts! (get active recipient-profile) (err ERR-USER-NOT-FOUND))
    
    ;; Priority validation
    (asserts! (and (>= priority MIN-PRIORITY) (<= priority MAX-PRIORITY)) (err ERR-INVALID-PRIORITY))
    
    ;; Block list check
    (asserts! (is-none (index-of sender-blocked-list sender)) (err ERR-UNAUTHORIZED))
    
    ;; Inbox capacity check
    (asserts! (< (len recipient-inbox) MAX-INBOX-SIZE) (err ERR-INBOX-FULL))
    
    ;; Create message record
    (map-set stored-messages msg-id
      {
        sender: sender,
        recipient: recipient,
        encrypted-content: encrypted-content,
        timestamp: current-time,
        is-read: false,
        priority: priority,
        thread-id: none,
        expires-at: expiry-time
      }
    )
    
    ;; Update recipient's inbox
    (map-set user-inboxes recipient
      (unwrap-panic (as-max-len? (append recipient-inbox msg-id) u25))
    )
    
    ;; Manage conversation threads
    (if (is-none (index-of recipient-conversations sender))
        (map-set conversation-threads recipient
          (unwrap-panic (as-max-len? (append recipient-conversations sender) u25)))
        true
    )
    
    ;; Update sender statistics and activity
    (map-set registered-users sender
      (merge sender-profile {
        sent-message-count: (+ (get sent-message-count sender-profile) u1),
        last-activity: current-time
      })
    )
    
    ;; Update recipient statistics
    (map-set registered-users recipient
      (merge recipient-profile {
        received-message-count: (+ (get received-message-count recipient-profile) u1)
      })
    )
    
    ;; Advance message counter
    (var-set message-id-counter (+ msg-id u1))
    
    (ok msg-id)
  )
)

;; Mark message as read with activity tracking
(define-public (acknowledge-message-read (msg-id uint))
  (let (
    (reader tx-sender)
    (current-time (get-current-timestamp))
    (message-data (unwrap! (get-active-message msg-id) (err ERR-MESSAGE-NOT-FOUND)))
    (reader-profile (unwrap! (get-complete-user-profile reader) (err ERR-USER-NOT-FOUND)))
  )
    ;; Authorization check
    (asserts! (is-eq (get recipient message-data) reader) (err ERR-UNAUTHORIZED))
    
    ;; Update message read status
    (map-set stored-messages msg-id
      (merge message-data { is-read: true })
    )
    
    ;; Update user activity
    (map-set registered-users reader
      (merge reader-profile { last-activity: current-time })
    )
    
    (ok true)
  )
)

;; Comprehensive message deletion
(define-public (delete-message-permanently (msg-id uint))
  (let (
    (requester tx-sender)
    (message-data (unwrap! (get-active-message msg-id) (err ERR-MESSAGE-NOT-FOUND)))
    (current-time (get-current-timestamp))
    (requester-profile (unwrap! (get-complete-user-profile requester) (err ERR-USER-NOT-FOUND)))
  )
    ;; Permission verification (sender or recipient)
    (asserts! (or 
               (is-eq (get sender message-data) requester)
               (is-eq (get recipient message-data) requester))
             (err ERR-UNAUTHORIZED))
    
    ;; Remove from recipient's inbox if requester is recipient
    (if (is-eq (get recipient message-data) requester)
        (begin
          (var-set temp-message-id msg-id)
          (map-set user-inboxes requester
            (fold filter-deleted-message (get-complete-inbox requester) (list)))
        )
        true
    )
    
    ;; Mark message as deleted
    (map-set deleted-messages msg-id true)
    
    ;; Update user activity
    (map-set registered-users requester
      (merge requester-profile { last-activity: current-time })
    )
    
    (ok true)
  )
)

;; Helper function for inbox cleanup
(define-private (filter-deleted-message (msg-id uint) (clean-inbox (list 25 uint)))
  (if (is-eq msg-id (var-get temp-message-id))
      clean-inbox
      (unwrap-panic (as-max-len? (append clean-inbox msg-id) u25))
  )
)

;; User blocking functionality
(define-public (block-user (target-user principal))
  (let (
    (blocker tx-sender)
    (current-blocked-list (get-blocked-users blocker))
    (blocker-profile (unwrap! (get-complete-user-profile blocker) (err ERR-USER-NOT-FOUND)))
    (current-time (get-current-timestamp))
  )
    ;; Verify target user exists
    (asserts! (is-active-user target-user) (err ERR-USER-NOT-FOUND))
    
    ;; Check if not already blocked
    (asserts! (is-none (index-of current-blocked-list target-user)) (err ERR-USER-EXISTS))
    
    ;; Add to blocked list
    (map-set blocked-users blocker
      (unwrap-panic (as-max-len? (append current-blocked-list target-user) u10))
    )
    
    ;; Update activity timestamp
    (map-set registered-users blocker
      (merge blocker-profile { last-activity: current-time })
    )
    
    (ok true)
  )
)

;; Update encryption key with enhanced security
(define-public (rotate-encryption-key (new-encryption-key (buff 33)))
  (let (
    (user tx-sender)
    (current-time (get-current-timestamp))
    (user-profile (unwrap! (get-complete-user-profile user) (err ERR-USER-NOT-FOUND)))
  )
    ;; Update encryption key and activity
    (map-set registered-users user
      (merge user-profile {
        public-key: new-encryption-key,
        last-activity: current-time
      })
    )
    
    (ok true)
  )
)

;; Get filtered unread messages count
(define-read-only (get-unread-messages-count (user principal))
  (let (
    (user-inbox (get-complete-inbox user))
  )
    (fold count-unread-messages user-inbox u0)
  )
)

;; Helper function for counting unread messages
(define-private (count-unread-messages (msg-id uint) (unread-count uint))
  (let (
    (message-info (get-active-message msg-id))
  )
    (if (and (is-some message-info) (not (get is-read (unwrap-panic message-info))))
        (+ unread-count u1)
        unread-count
    )
  )
)