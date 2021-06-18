import SimpleRestrictedToken from "../contracts/SimpleRestrictedToken.cdc"
import SimpleAdmin from "../contracts/SimpleAdmin.cdc"

transaction(amount: UFix64) {
    prepare(signer: AuthAccount, admin: AuthAccount) {

        let vaultRef = signer.borrow<&SimpleRestrictedToken.Vault>(from: /storage/simpleToken)
            ?? panic("Could not borrow reference to the owner's Vault!")

        let adminRef = admin.borrow<&SimpleAdmin.Admin>(from: /storage/simpleAdmin)
            ?? panic("Could not borrow reference to the admin resource!")

        // Withdraw tokens from the signer's stored vault
        let sentVault <- vaultRef.withdrawWithAdminCheck(amount: amount, adminRef: adminRef)

        vaultRef.deposit(from: <- sentVault)
    }
}
