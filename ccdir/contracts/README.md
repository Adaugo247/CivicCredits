
### README: **CivicCredits**

---

## CivicCredits: A Blockchain-based Community Service Credit System  

**CivicCredits** is a decentralized platform built on the Clarity blockchain that manages and tracks community service credits securely and transparently. This system incentivizes community service and ensures fair distribution of credits through verifier validation and daily credit limits.  

---

### Features  
- **Credit Transfers**: Seamless transfer of community service credits between participants.  
- **Quota Management**: Enforces daily credit transfer limits to promote equitable distribution.  
- **Account Recovery**: Secure account transfer functionality to recover balances.  
- **System Suspension and Resumption**: Temporarily suspend the system during audits or emergencies.  
- **Verifier Management**: Enables trusted entities to oversee system operations and enforce rules.  
- **Restriction Mechanism**: Restrict participants for non-compliance with system rules.  
- **Historical Balance Tracking**: Query past account balances for audit or dispute resolution.  

---

### Installation and Setup  

1. **Prerequisites**:  
   - Ensure you have a Clarity-compatible blockchain environment set up (e.g., [Stacks Blockchain](https://www.stacks.co/)).  
   - Install Clarity development tools such as [Clarinet](https://github.com/hirosystems/clarinet) for local testing.  

2. **Clone the Repository**:  
   ```bash  
   git clone https://github.com/your-repo/civiccredits.git  
   cd civiccredits  
   ```  

3. **Deploy the Contract**:  
   Use the Clarinet tool to deploy the contract:  
   ```bash  
   clarinet deploy  
   ```  

4. **Interact with the Contract**:  
   Utilize a Clarity-compatible wallet or command-line tools to interact with the contract.  

---

### Usage  

1. **Initialize the Contract**:  
   - Upon deployment, the contract owner is credited with the total supply of credits and is designated as the initial verifier.  

2. **Transfer Credits**:  
   - Participants can transfer credits to other participants using the `transfer-credits` function.  
   ```clarity  
   (contract-call? .civiccredits transfer-credits u100 'recipient-principal)  
   ```  

3. **Manage Quotas**:  
   - Enable or update daily credit transfer limits.  
   ```clarity  
   (contract-call? .civiccredits set-daily-quota true u500)  
   ```  

4. **Add/Remove Verifiers**:  
   - Grant or revoke verifier status to participants.  
   ```clarity  
   (contract-call? .civiccredits add-verifier 'verifier-principal)  
   ```  

5. **Suspend or Resume System**:  
   - Temporarily suspend operations or lift restrictions.  
   ```clarity  
   (contract-call? .civiccredits suspend-system)  
   ```  

6. **Restrict Participants**:  
   - Restrict participants for non-compliance.  
   ```clarity  
   (contract-call? .civiccredits restrict-participant 'participant-principal)  
   ```  

7. **Historical Balances**:  
   - Query historical balances for any participant.  
   ```clarity  
   (contract-call? .civiccredits get-historical-balance 'participant-principal u1625097600)  
   ```  

---

### Contract Constants and Errors  

| Constant                  | Description                         |  
|---------------------------|-------------------------------------|  
| `CONTRACT_OWNER`          | Address of the contract deployer.   |  
| `ERR_NOT_AUTHORIZED`      | Caller lacks required permissions.  |  
| `ERR_SUSPENDED`           | System is currently suspended.      |  
| `ERR_QUOTA_EXCEEDED`      | Daily quota exceeded for transfers. |  

---

### Security Features  

- **Role-based Access Control**: Only authorized verifiers can perform administrative tasks.  
- **Self-Protection**: Prevent self-crediting and unauthorized operations.  
- **Suspension Mechanism**: Halt all operations during emergencies or audits.  

---

### Contributing  

We welcome contributions! Please fork the repository, create a feature branch, and submit a pull request.  

---

### Contact  

For inquiries or support, please contact **dev.triggerfish@gmail.com**.  