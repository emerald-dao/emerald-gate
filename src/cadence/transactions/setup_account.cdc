import Premint from "../Premint.cdc"

transaction {

  prepare(acct: AuthAccount) {
    // set up the Registry where users will store all their created events
    if acct.borrow<&Premint.Registry>(from: Premint.RegistryStoragePath) == nil {
      acct.save(<- Premint.createEmptyRegistry(), to: Premint.RegistryStoragePath)
      acct.link<&Premint.Registry{Premint.RegistryPublic}>(Premint.RegistryPublicPath, target: Premint.RegistryStoragePath)
    }
  }

  execute {
    log("Finished setting up the account for FLOATs.")
  }
}
