
import FungibleToken from 0x9a0766d93b6608b7
pub fun main(): String {
  let vault = getAccount(0x6c0d53c676256e8c).getCapability(/public/flowTokenBalance)
                              .borrow<&{FungibleToken.Balance}>()
                              ?? panic("Could not borrow the vault from the path: ")
  return vault.getType().identifier
}