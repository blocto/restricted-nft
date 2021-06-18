import NonFungibleToken from "./NonFungibleToken.cdc"
import SimpleAdmin from "./SimpleAdmin.cdc"

pub contract SimpleRestrictedNFT: NonFungibleToken {

  // Events
  pub event ContractInitialized()
  pub event Withdraw(id: UInt64, from: Address?)
  pub event Deposit(id: UInt64, to: Address?)
  pub event Minted(id: UInt64, typeID: UInt64)

  // Named Paths
  pub let CollectionStoragePath: StoragePath
  pub let CollectionPublicPath: PublicPath
  pub let MinterStoragePath: StoragePath

  // totalSupply
  pub var totalSupply: UInt64

  // NFT
  pub resource NFT: NonFungibleToken.INFT {
    // The token's ID
    pub let id: UInt64
    // The token's type, e.g. 3 == Hat
    pub let typeID: UInt64

    // initializer
    //
    init(initID: UInt64, initTypeID: UInt64) {
      self.id = initID
      self.typeID = initTypeID
    }
  }

  // Collection
  pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic {
    // dictionary of NFT conforming tokens
    // NFT is a resource type with an `UInt64` ID field
    //
    pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

    // withdraw
    // Removes an NFT from the collection and moves it to the caller
    //
    pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
      pre {
        false: "withdrawal disabled"
      }

      let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

      emit Withdraw(id: token.id, from: self.owner?.address)

      return <-token
    }

    // withdraw with admin check
    pub fun withdrawWithAdminCheck(withdrawID: UInt64, adminRef: &SimpleAdmin.Admin): @NonFungibleToken.NFT {
      pre {
        adminRef.check(): "capability not valid"
      }
      
      let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

      emit Withdraw(id: token.id, from: self.owner?.address)

      return <-token
    }

    // deposit
    // Takes a NFT and adds it to the collections dictionary
    // and adds the ID to the id array
    //
    pub fun deposit(token: @NonFungibleToken.NFT) {
      let token <- token as! @KittyItems.NFT

      let id: UInt64 = token.id

      // add the new token to the dictionary which removes the old one
      let oldToken <- self.ownedNFTs[id] <- token

      emit Deposit(id: id, to: self.owner?.address)

      destroy oldToken
    }

    // getIDs
    // Returns an array of the IDs that are in the collection
    //
    pub fun getIDs(): [UInt64] {
      return self.ownedNFTs.keys
    }

    // borrowNFT
    // Gets a reference to an NFT in the collection
    // so that the caller can read its metadata and call its methods
    //
    pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
      return &self.ownedNFTs[id] as &NonFungibleToken.NFT
    }

    // destructor
    destroy() {
      destroy self.ownedNFTs
    }

    // initializer
    //
    init () {
      self.ownedNFTs <- {}
    }
  }

  // createEmptyCollection
  // public function that anyone can call to create a new empty collection
  //
  pub fun createEmptyCollection(): @NonFungibleToken.Collection {
    return <- create Collection()
  }

  // NFTMinter
  // Resource that an admin or something similar would own to be
  // able to mint new NFTs
  //
	pub resource NFTMinter {

		// mintNFT
    // Mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		pub fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, typeID: UInt64) {
      emit Minted(id: SimpleRestrictedNFT.totalSupply, typeID: typeID)

			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-create SimpleRestrictedNFT.NFT(initID: SimpleRestrictedNFT.totalSupply, initTypeID: typeID))

      SimpleRestrictedNFT.totalSupply = SimpleRestrictedNFT.totalSupply + (1 as UInt64)
		}
	}

  // initializer
	init() {
    // Set our named paths
    self.CollectionStoragePath = /storage/itemsCollection
    self.CollectionPublicPath = /public/itemsCollection
    self.MinterStoragePath = /storage/itemsMinter

    // Initialize the total supply
    self.totalSupply = 0

    // Create a Minter resource and save it to storage
    let minter <- create NFTMinter()
    self.account.save(<-minter, to: self.MinterStoragePath)

    emit ContractInitialized()
	}
}
