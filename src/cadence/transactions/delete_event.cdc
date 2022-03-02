import Premint from "../Premint.cdc"

transaction(eventId: UInt64) {

  let Registry: &Premint.Registry

  prepare(acct: AuthAccount) {
    self.Registry = acct.borrow<&Premint.Registry>(from: Premint.RegistryStoragePath)
                        ?? panic("Could not borrow the Registry from the signer.")
  }

  execute {
    self.Registry.deleteWhitelist(eventId: eventId)
    log("Removed the Whitelist.")
  }
}