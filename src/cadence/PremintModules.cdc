import Premint from "./Premint.cdc"
import FungibleToken from "./core-contracts/FungibleToken.cdc"
import NonFungibleToken from "./core-contracts/NonFungibleToken.cdc"
import ZayVerifierV2 from "./ZayVerifierV2.cdc"

pub contract PremintModules {
  pub struct OwnsToken: Premint.IModule {
    pub let path: PublicPath
    pub let amount: UFix64
    pub let identifier: String

    pub fun verify(_ params: {String: AnyStruct}) {
      let account = params["registree"]! as! Address
      let vault = getAccount(account).getCapability(self.path)
                            .borrow<&{FungibleToken.Balance}>()
                            ?? panic("Could not borrow the Vault from the path: ".concat(self.path.toString().concat(".")))
      assert(
        vault.getType().identifier == self.identifier,
        message: "Mismatched identifiers. "
                    .concat(vault.getType().identifier)
                    .concat(" on the Vault, but ")
                    .concat(self.identifier)
                    .concat(" on the passed in identifier.")
      )

      assert(
        vault.balance >= self.amount, 
        message: "The registree does not have enough "
              .concat(self.identifier)
              .concat(". They only have ")
              .concat(vault.balance.toString())
              .concat(" of the required ")
              .concat(self.amount.toString())
              .concat(".")
      )
    }

    init(_path: PublicPath, _amount: UFix64, _identifier: String) {
      self.path = _path
      self.amount = _amount
      self.identifier = _identifier
    }
  }

  pub struct OwnsNFT: Premint.IModule {
    pub let path: PublicPath
    pub let identifier: String

    pub fun verify(_ params: {String: AnyStruct}) {
      let account = params["registree"]! as! Address
      let collection = getAccount(account).getCapability(self.path)
                            .borrow<&{NonFungibleToken.CollectionPublic}>()
                            ?? panic("Could not borrow the Collection from the path: ".concat(self.path.toString().concat(".")))
      assert(
        collection.getType().identifier == self.identifier,
        message: "Mismatched identifiers. "
                    .concat(collection.getType().identifier)
                    .concat(" on the Collection, but ")
                    .concat(self.identifier)
                    .concat(" on the passed in identifier.")
      )

      assert(
        collection.getIDs().length >= 1, 
        message: "The registree does not have a "
              .concat(self.identifier)
              .concat(".")
      )
    }

    init(_path: PublicPath, _identifier: String) {
      self.path = _path
      self.identifier = _identifier
    }
  }

  pub struct VerifySig {
    pub let acctAddress: Address
    pub let message: String 
    pub let signatures: [String] 
    pub let keyIds: [Int]
    pub let signatureBlock: UInt64

    init(
      _acctAddress: Address, 
      _message: String, 
      _signatures: [String], 
      _keyIds: [Int], 
      _signatureBlock: UInt64
    ) {
      self.acctAddress = _acctAddress
      self.message = _message
      self.signatures = _signatures
      self.keyIds = _keyIds
      self.signatureBlock = _signatureBlock
    }
  }

  pub struct TwitterFollows: Premint.IModule {
    pub let twitterAccounts: [String]
    
    pub fun verify(_ params: {String: AnyStruct}) {
      let registrantId = params["registrantId"]! as! UInt64
      let twitterSig = params["twitterSig"]! as! VerifySig
      let whitelist = params["whitelist"]! as! &Premint.Whitelist{Premint.WhitelistPublic}
      let whitelistId = whitelist.uuid

      let intent = "VERIFY_TWITTER_"
                        .concat(whitelistId.toString())
                        .concat("_")
                        .concat(registrantId.toString())
      let identifier = registrantId.toString()

      let result = ZayVerifierV2.verifySignature(
        acctAddress: twitterSig.acctAddress, 
        message: twitterSig.message, 
        keyIds: twitterSig.keyIds, 
        signatures: twitterSig.signatures, 
        signatureBlock: twitterSig.signatureBlock, 
        intent: intent, 
        identifier: identifier
      )

      assert(
        result != nil, 
        message: "The registrant does not follow the required people."
      )
    }

    init(_twitterAccounts: [String]) {
      self.twitterAccounts = _twitterAccounts
    }

  }

  pub struct DiscordRoles: Premint.IModule {
    pub let guild: String
    pub let discordRoles: [String]
    
    pub fun verify(_ params: {String: AnyStruct}) {
      let registrantId = params["registrantId"]! as! UInt64
      let discordSig = params["discordSig"]! as! VerifySig
      let whitelist = params["whitelist"]! as! &Premint.Whitelist{Premint.WhitelistPublic}
      let whitelistId = whitelist.uuid

      let intent = "VERIFY_DISCORD_"
                        .concat(whitelistId.toString())
                        .concat("_")
                        .concat(registrantId.toString())
      let identifier = registrantId.toString()

      let result = ZayVerifierV2.verifySignature(
        acctAddress: discordSig.acctAddress, 
        message: discordSig.message, 
        keyIds: discordSig.keyIds, 
        signatures: discordSig.signatures, 
        signatureBlock: discordSig.signatureBlock, 
        intent: intent, 
        identifier: identifier
      )

      assert(
        result != nil, 
        message: "The registrant does not have the correct roles."
      )
    }

    init(_guild: String, _discordRoles: [String]) {
      self.guild = _guild
      self.discordRoles = _discordRoles
    }

  }

  pub struct Timelock: Premint.IModule {
        pub let dateStart: UFix64
        pub let dateEnding: UFix64

        pub fun verify(_ params: {String: AnyStruct}) {
            assert(
                getCurrentBlock().timestamp >= self.dateStart,
                message: "This FLOAT Event has not started yet."
            )
            assert(
                getCurrentBlock().timestamp <= self.dateEnding,
                message: "Sorry! The time has run out to mint this FLOAT."
            )
        }

        init(_dateStart: UFix64, _timePeriod: UFix64) {
            self.dateStart = _dateStart
            self.dateEnding = self.dateStart + _timePeriod
        }
    }

    pub struct Limited: Premint.IModule {
        pub var capacity: UInt64

        pub fun verify(_ params: {String: AnyStruct}) {
            let whitelist = params["whitelist"]! as! &Premint.Whitelist{Premint.WhitelistPublic}
            let currentCapacity = whitelist.getRegistered().length
            assert(
                currentCapacity < Int(self.capacity),
                message: "This FLOAT Event is at capacity."
            )
        }

        init(_capacity: UInt64) {
            self.capacity = _capacity
        }
    }
}