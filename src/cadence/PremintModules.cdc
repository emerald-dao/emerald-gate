import Premint from "./Premint.cdc"
import FungibleToken from "./core-contracts/FungibleToken.cdc"
import NonFungibleToken from "./core-contracts/NonFungibleToken.cdc"

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
}