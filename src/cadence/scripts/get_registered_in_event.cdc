import Premint from "../Premint.cdc"

pub fun main(account: Address, eventId: UInt64): [Address] {
  let registry = getAccount(account).getCapability(Premint.RegistryPublicPath)
                              .borrow<&Premint.Registry{Premint.RegistryPublic}>()
                              ?? panic("Could not borrow the Public Registry from the account.")
  return registry.borrowPublicEventRef(eventId: eventId).getRegistered()
}