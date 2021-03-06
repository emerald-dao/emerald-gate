import Premint from "../Premint.cdc"
import PremintModules from "../PremintModules.cdc"

transaction(active: Bool, name: String, description: String, image: String, url: String, tokenPaths: [PublicPath], amounts: [UFix64], identifiers: [String]) {

  let Registry: &Premint.Registry

  prepare(acct: AuthAccount) {
    // set up the Registry where users will store all their created events
    if acct.borrow<&Premint.Registry>(from: Premint.RegistryStoragePath) == nil {
      acct.save(<- Premint.createEmptyRegistry(), to: Premint.RegistryStoragePath)
      acct.link<&Premint.Registry{Premint.RegistryPublic}>(Premint.RegistryPublicPath, target: Premint.RegistryStoragePath)
    }

    self.Registry = acct.borrow<&Premint.Registry>(from: Premint.RegistryStoragePath)
                        ?? panic("Could not borrow the Registry from the signer.")
  }

  execute {
    let modules: [{Premint.IModule}] = []
    var i = 0
    while i < identifiers.length {
      modules.append(PremintModules.OwnsToken(_path: tokenPaths[i], amount: amounts[i], identifier: identifiers[i]))
      i = i + 1
    }
    self.Registry.createEvent(active: active, description: description, image: image, name: name, url: url, modules: modules, {})
    log("Started a new event.")
  }
}

