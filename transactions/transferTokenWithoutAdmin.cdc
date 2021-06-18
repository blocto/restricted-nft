import SimpleRestrictedToken from "../contracts/SimpleRestrictedToken.cdc"

transaction(amount: UFix64) {
    prepare(signer: AuthAccount) {

        // Get a reference to the signer's stored vault
        let vaultRef = signer.borrow<&SimpleRestrictedToken.Vault>(from: /storage/simpleToken)
            ?? panic("Could not borrow reference to the owner's Vault!")

        // Withdraw tokens from the signer's stored vault
        let sentVault <- vaultRef.withdraw(amount: amount)

        vaultRef.deposit(from: <- sentVault)
    }
}
