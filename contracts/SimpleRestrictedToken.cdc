import FungibleToken from "./FungibleToken.cdc"
import SimpleAdmin from "./SimpleAdmin.cdc"

access(all) contract SimpleRestrictedToken: FungibleToken {
  // Total supply of SimpleToken in existence
  pub var totalSupply: UFix64

  /// TokensInitialized
  ///
  /// The event that is emitted when the contract is created
  ///
  pub event TokensInitialized(initialSupply: UFix64)

  /// TokensWithdrawn
  ///
  /// The event that is emitted when tokens are withdrawn from a Vault
  ///
  pub event TokensWithdrawn(amount: UFix64, from: Address?)

  /// TokensDeposited
  ///
  /// The event that is emitted when tokens are deposited into a Vault
  ///
  pub event TokensDeposited(amount: UFix64, to: Address?)

  pub resource Vault: FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance {
    // holds the balance of a users tokens
    pub var balance: UFix64

    // initialize the balance at resource creation time
    init(balance: UFix64) {
      self.balance = balance
    }

    // withdraw
    pub fun withdraw(amount: UFix64): @FungibleToken.Vault {
      pre {
        false: "withdrawal disabled"
      }
      
      self.balance = self.balance - amount
      emit TokensWithdrawn(amount: amount, from: self.owner?.address)
      return <-create Vault(balance: amount)
    }

    // withdraw
    pub fun withdrawWithAdminCheck(amount: UFix64, adminRef: &SimpleAdmin.Admin): @FungibleToken.Vault {
      pre {
        adminRef.check(): "capability not valid"
      }
      
      self.balance = self.balance - amount
      emit TokensWithdrawn(amount: amount, from: self.owner?.address)
      return <-create Vault(balance: amount)
    }

    // deposit
    pub fun deposit(from: @FungibleToken.Vault) {
      let vault <- from as! @SimpleRestrictedToken.Vault
      self.balance = self.balance + vault.balance
      emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
      vault.balance = 0.0
      destroy vault
    }

    destroy() {
      SimpleRestrictedToken.totalSupply = SimpleRestrictedToken.totalSupply - self.balance
    }
  }

  pub fun createEmptyVault(): @FungibleToken.Vault {
      return <-create Vault(balance: 0.0)
  }

  init() {
    self.totalSupply = 0.0
    
    let admin <- create Vault(balance: 100.0)
    self.account.save(<-admin, to: /storage/simpleToken)

    // Emit an event that shows that the contract was initialized
    emit TokensInitialized(initialSupply: self.totalSupply)
  }
}
