
## 📝 README — ClaritySecureMessenger

### Overview

**ClaritySecureMessenger** is a fully-featured, production-grade smart contract for secure, decentralized messaging on the Stacks blockchain. It enables encrypted communication between registered users with features such as:

* User registration and profile management
* Encrypted message transmission
* Inbox management with capacity limits
* Priority messaging
* Optional message expiry
* Message read acknowledgment
* Permanent message deletion
* User blocking
* Public key rotation for encryption
* Comprehensive system statistics and state tracking

---

### 🔐 Features

* **Secure Messaging**: Messages are end-to-end encrypted using user-supplied public keys.
* **Inbox Capacity Enforcement**: Prevents spam and abuse with inbox size limits (`MAX-INBOX-SIZE`).
* **Message Expiry**: Send messages that automatically expire after a user-defined duration.
* **Priority Tagging**: Messages can be prioritized on a scale (`MIN-PRIORITY` to `MAX-PRIORITY`).
* **Read Tracking**: Recipients can mark messages as read.
* **User Blocking**: Users can block others from sending them messages.
* **Public Key Rotation**: Users can rotate their encryption key securely.
* **Message Deletion**: Either the sender or recipient can permanently delete a message.
* **System Monitoring**: View metrics such as total users, messages sent, and system status.

---

### 📚 Contract Constants

| Constant             | Description                          |
| -------------------- | ------------------------------------ |
| `MAX-MESSAGE-LENGTH` | Maximum allowed length for a message |
| `MAX-INBOX-SIZE`     | Inbox capacity per user              |
| `MIN-PRIORITY`       | Minimum message priority             |
| `MAX-PRIORITY`       | Maximum message priority             |

---

### ⚠️ Error Codes

| Error Code              | Description                                 |
| ----------------------- | ------------------------------------------- |
| `ERR-USER-EXISTS`       | User already registered                     |
| `ERR-USER-NOT-FOUND`    | User not found                              |
| `ERR-UNAUTHORIZED`      | Operation not authorized                    |
| `ERR-MESSAGE-NOT-FOUND` | Message not found or already deleted        |
| `ERR-INBOX-FULL`        | Recipient's inbox is full                   |
| `ERR-MESSAGE-TOO_LARGE` | Message exceeds `MAX-MESSAGE-LENGTH`        |
| `ERR-INVALID-PRIORITY`  | Priority value is outside acceptable bounds |

---

### 🛠️ Key Functions

#### 📤 `send-secure-message`

Send an encrypted message to a registered user with optional expiry and priority control.

#### ✅ `acknowledge-message-read`

Marks a message as read and updates user activity timestamp.

#### 🧹 `delete-message-permanently`

Permanently deletes a message if the sender or recipient initiates it.

#### ⛔ `block-user`

Adds a user to the caller's blocklist, preventing further message delivery.

#### 🔑 `rotate-encryption-key`

Updates the caller’s stored encryption public key.

#### 📈 `get-detailed-system-stats`

Returns real-time system metrics such as total users and overall status.

---

### 👤 User Lifecycle

1. **Register** via `register-enhanced-user`.
2. **Communicate** with `send-secure-message`.
3. **Manage** inbox, conversations, blocklist.
4. **Update** encryption key periodically.
5. **Exit** messages via `delete-message-permanently`.

---

### ✅ Recommended Usage Scenarios

* Private messaging apps
* Decentralized whistleblowing platforms
* Blockchain-based customer support
* DAO communication tools
* Secure community governance coordination
