import Premint from "../Premint.cdc"

transaction(eventId: UInt64) {

  let Whitelist: &Premint.Whitelist

  prepare(acct: AuthAccount) {
    let Registry = acct.borrow<&Premint.Registry>(from: Premint.RegistryStoragePath)
                        ?? panic("Could not borrow the Registry from the signer.")
    self.Whitelist = Registry.borrowEventRef(eventId: eventId)
  }

  execute {
    self.Whitelist.toggleActive()
    log("Toggled the Whitelist active.")
  }
}