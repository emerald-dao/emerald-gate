import Premint from "../Premint.cdc"

pub fun main(account: Address): {String: &Premint.Whitelist{Premint.WhitelistPublic}} {
  let registry = getAccount(account).getCapability(Premint.RegistryPublicPath)
                              .borrow<&Premint.Registry{Premint.RegistryPublic}>()
                              ?? panic("Could not borrow the Public Registry from the account.")
  let whitelists: [UInt64] = registry.getIDs()
  let returnVal: {String: &Premint.Whitelist{Premint.WhitelistPublic}} = {}

  for eventId in whitelists {
    let event = registry.borrowPublicEventRef(eventId: eventId)
    returnVal[event.name] = event
  }
  return returnVal
}