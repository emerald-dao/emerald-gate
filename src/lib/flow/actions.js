import { browser } from '$app/env';

import * as fcl from "@samatech/onflow-fcl-esm";

import "./config.js";
import {
  user,
  txId,
  transactionStatus,
  transactionInProgress,
  eventCreationInProgress,
  eventCreatedStatus,
  registeringInProgress,
  registeringStatus
} from './stores.js';

import { respondWithError, respondWithSuccess } from '$lib/response';
import { parseErrorMessageFromFCL } from './utils.js';

if (browser) {
  // set Svelte $user store to currentUser, 
  // so other components can access it
  fcl.currentUser.subscribe(user.set, [])
}

// Lifecycle FCL Auth functions
export const unauthenticate = () => fcl.unauthenticate();
export const authenticate = () => fcl.authenticate();

const convertDraftWhitelist = (draftWhitelist) => {
  return {
    active: draftWhitelist.active,
    name: draftWhitelist.name,
    description: draftWhitelist.description,
    image: draftWhitelist.ipfsHash,
    url: draftWhitelist.url,
    tokenPath: {
      domain: "public", // public | private | storage
      identifier: draftWhitelist.tokenPath.replace("/public/", "")
    },
    amount: draftWhitelist.amount == "" ? 0.0 : parseInt(draftWhitelist.amount).toFixed(1),
    identifier: draftWhitelist.identifier
  };
}

/****************************** SETTERS ******************************/

export const createWhitelist = async (draftWhitelist) => {

  const whitelistObject = convertDraftWhitelist(draftWhitelist);
  console.log(whitelistObject);

  eventCreationInProgress.set(true);

  let transactionId = false;
  initTransactionState()

  try {
    transactionId = await fcl.mutate({
      cadence: `
      import Premint from 0xPM
      import PremintModules from 0xPM

      transaction(active: Bool, name: String, description: String, image: String, url: String, tokenPath: PublicPath, amount: UFix64, identifier: String) {

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
          if identifier != "" {
            modules.append(PremintModules.OwnsToken(_path: tokenPath, amount: amount, identifier: identifier))
          }
          self.Registry.createEvent(active: active, description: description, image: image, name: name, url: url, modules: modules, {})
          log("Started a new event.")
        }
      }
      `,
      args: (arg, t) => [
        arg(whitelistObject.active, t.Bool),
        arg(whitelistObject.name, t.String),
        arg(whitelistObject.description, t.String),
        arg(whitelistObject.image, t.String),
        arg(whitelistObject.url, t.String),
        arg(whitelistObject.tokenPath, t.Path),
        arg(whitelistObject.amount, t.UFix64),
        arg(whitelistObject.identifier, t.String)
      ],
      payer: fcl.authz,
      proposer: fcl.authz,
      authorizations: [fcl.authz],
      limit: 999
    })

    txId.set(transactionId);

    fcl.tx(transactionId).subscribe(res => {
      transactionStatus.set(res.status)
      if (res.status === 4) {
        if (res.statusCode === 0) {
          eventCreatedStatus.set(respondWithSuccess());
        } else {
          eventCreatedStatus.set(respondWithError(parseErrorMessageFromFCL(res.errorMessage), res.statusCode));
        }
        eventCreationInProgress.set(false);
        setTimeout(() => transactionInProgress.set(false), 2000)
      }
    })

    let res = await fcl.tx(transactionId).onceSealed()
    return res;

  } catch (e) {
    eventCreatedStatus.set(false);
    transactionStatus.set(99)
    console.log(e)

    setTimeout(() => transactionInProgress.set(false), 10000)
  }
}

export const register = async (eventId, host, secret) => {

  let transactionId = false;
  initTransactionState()

  registeringInProgress.set(true);

  try {
    transactionId = await fcl.mutate({
      cadence: `
      import Premint from 0xPM

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
      `,
      args: (arg, t) => [
        arg(parseInt(eventId), t.UInt64),
        arg(host, t.Address)
      ],
      payer: fcl.authz,
      proposer: fcl.authz,
      authorizations: [fcl.authz],
      limit: 999
    })

    txId.set(transactionId);

    fcl.tx(transactionId).subscribe(res => {
      transactionStatus.set(res.status)
      if (res.status === 4) {
        console.log(res);
        if (res.statusCode === 0) {
          registeringStatus.set(respondWithSuccess());
        } else {
          registeringStatus.set(respondWithError(parseErrorMessageFromFCL(res.errorMessage), res.statusCode));
        }
        registeringInProgress.set(false);
        draftFloat.set({
          claimable: true,
          transferrable: true,
        })

        setTimeout(() => transactionInProgress.set(false), 2000)
      }
    })

  } catch (e) {
    transactionStatus.set(99)
    registeringStatus.set(respondWithError(e));
    registeringInProgress.set(false);

    console.log(e)
  }
}

export const toggleActive = async (eventId) => {
  let transactionId = false;
  initTransactionState()

  try {
    transactionId = await fcl.mutate({
      cadence: `
      import Premint from 0xPM

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
      `,
      args: (arg, t) => [
        arg(eventId, t.UInt64),
      ],
      payer: fcl.authz,
      proposer: fcl.authz,
      authorizations: [fcl.authz],
      limit: 999
    })

    txId.set(transactionId);

    fcl.tx(transactionId).subscribe(res => {
      transactionStatus.set(res.status)
      if (res.status === 4) {
        setTimeout(() => transactionInProgress.set(false), 2000)
      }
    })

    let res = await fcl.tx(transactionId).onceSealed()
    return res;

  } catch (e) {
    transactionStatus.set(99)
    console.log(e)
  }
}

export const deleteEvent = async (eventId) => {
  let transactionId = false;
  initTransactionState()

  try {
    transactionId = await fcl.mutate({
      cadence: `
      import Premint from 0xPM

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
      `,
      args: (arg, t) => [
        arg(eventId, t.UInt64),
      ],
      payer: fcl.authz,
      proposer: fcl.authz,
      authorizations: [fcl.authz],
      limit: 999
    })

    txId.set(transactionId);

    fcl.tx(transactionId).subscribe(res => {
      transactionStatus.set(res.status)
      if (res.status === 4) {
        setTimeout(() => transactionInProgress.set(false), 2000)
      }
    })

    let res = await fcl.tx(transactionId).onceSealed()
    return res;

  } catch (e) {
    transactionStatus.set(99)
    console.log(e)
  }
}


/****************************** GETTERS ******************************/

export const getEvent = async (addr, eventId) => {
  try {
    let queryResult = await fcl.query({
      cadence: `
      import Premint from 0xPM

      pub fun main(account: Address, eventId: UInt64): FLOATEventMetadataView {
        let registry = getAccount(account).getCapability(Premint.RegistryPublicPath)
                                    .borrow<&Premint.Registry{Premint.RegistryPublic}>()
                                    ?? panic("Could not borrow the Public Registry from the account.")
        let event = registry.borrowPublicEventRef(eventId: eventId)
        return FLOATEventMetadataView(
          _active: event.active, 
          _dateCreated: event.dateCreated, 
          _description: event.description, 
          _extraMetadata: event.getExtraMetadata(), 
          _host: event.host, 
          _eventId: event.eventId, 
          _image: event.image, 
          _name: event.name, 
          _totalCount: event.totalCount, 
          _url: event.url, 
          _modules: event.getModules()
        )
      }

      pub struct FLOATEventMetadataView {
          pub let active: Bool
          pub let dateCreated: UFix64
          pub let description: String 
          pub let extraMetadata: {String: String}
          pub let host: Address
          pub let eventId: UInt64
          pub let image: String 
          pub let name: String
          pub var totalCount: UInt64
          pub let url: String
          pub let modules: [{Premint.IModule}]

          init(
              _active: Bool,
              _dateCreated: UFix64,
              _description: String, 
              _extraMetadata: {String: String},
              _host: Address, 
              _eventId: UInt64,
              _image: String, 
              _name: String,
              _totalCount: UInt64,
              _url: String,
              _modules: [{Premint.IModule}]
          ) {
              self.active = _active
              self.dateCreated = _dateCreated
              self.description = _description
              self.extraMetadata = _extraMetadata
              self.host = _host
              self.eventId = _eventId
              self.image = _image
              self.name = _name
              self.totalCount = _totalCount
              self.url = _url
              self.modules = _modules
          }
      }
      `,
      args: (arg, t) => [
        arg(addr, t.Address),
        arg(parseInt(eventId), t.UInt64)
      ]
    })
    // console.log(queryResult);
    return queryResult || {};
  } catch (e) {
    console.log(e);
  }
}

export const getEvents = async (addr) => {
  try {
    let queryResult = await fcl.query({
      cadence: `
      import Premint from 0xPM

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
      `,
      args: (arg, t) => [
        arg(addr, t.Address)
      ]
    })
    return queryResult || {};
  } catch (e) {
  }
}

export const getRegisteredInEvent = async (addr, eventId) => {
  try {
    let queryResult = await fcl.query({
      cadence: `
      import Premint from 0xPM

      pub fun main(account: Address, eventId: UInt64): [Address] {
        let registry = getAccount(account).getCapability(Premint.RegistryPublicPath)
                                    .borrow<&Premint.Registry{Premint.RegistryPublic}>()
                                    ?? panic("Could not borrow the Public Registry from the account.")
        return registry.borrowPublicEventRef(eventId: eventId).getRegistered()
      }
      `,
      args: (arg, t) => [
        arg(addr, t.Address),
        arg(parseInt(eventId), t.UInt64)
      ]
    })
    // console.log(queryResult);
    return queryResult || [];
  } catch (e) {
    console.log(e);
  }
}

export const hasRegisteredInEvent = async (hostAddress, eventId, accountAddress) => {
  try {
    let queryResult = await fcl.query({
      cadence: `
      import Premint from 0xPM

      pub fun main(hostAddress: Address, eventId: UInt64, accountAddress: Address): Bool {
        let registry = getAccount(hostAddress).getCapability(Premint.RegistryPublicPath)
                                    .borrow<&Premint.Registry{Premint.RegistryPublic}>()
                                    ?? panic("Could not borrow the Public Registry from the account.")
        let whitelist = registry.borrowPublicEventRef(eventId: eventId)

        return whitelist.hasRegistered(account: accountAddress)
      }
      `,
      args: (arg, t) => [
        arg(hostAddress, t.Address),
        arg(parseInt(eventId), t.UInt64),
        arg(accountAddress, t.Address)
      ]
    })
    
    return queryResult;
  } catch (e) {
    console.log(e);
  }
}

function initTransactionState() {
  transactionInProgress.set(true);
  transactionStatus.set(-1);
  registeringStatus.set(false);
  eventCreatedStatus.set(false);
}