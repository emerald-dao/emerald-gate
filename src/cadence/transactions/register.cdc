import Premint from "../Premint.cdc"

transaction(eventId: UInt64, host: Address) {
 
  let Registry: &Premint.Registry
  let Whitelist: &Premint.Whitelist{Premint.WhitelistPublic}

  prepare(acct: AuthAccount) {
    // set up the Registry where users will store all their created events
    if acct.borrow<&Premint.Registry>(from: Premint.RegistryStoragePath) == nil {
      acct.save(<- Premint.createEmptyRegistry(), to: Premint.RegistryStoragePath)
      acct.link<&Premint.Registry{Premint.RegistryPublic}>(Premint.RegistryPublicPath, target: Premint.RegistryStoragePath)
    }

    let HostRegistry = getAccount(host).getCapability(Premint.RegistryPublicPath)
                        .borrow<&Premint.Registry{Premint.RegistryPublic}>()
                        ?? panic("Could not borrow the public Registry from the host.")
    
    self.Whitelist = HostRegistry.borrowPublicEventRef(eventId: eventId)

    self.Registry = acct.borrow<&Premint.Registry>(from:  Premint.RegistryStoragePath)
                      ?? panic("Could not borrow the Registry from the signer of registering.")
  }

  execute {
    self.Registry.register(whitelist: self.Whitelist, params: {})
  }
}
 