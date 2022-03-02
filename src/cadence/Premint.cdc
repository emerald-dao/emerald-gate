pub contract Premint {

    /***********************************************/
    /******************** PATHS ********************/
    /***********************************************/

    pub let RegistryStoragePath: StoragePath
    pub let RegistryPublicPath: PublicPath

    /************************************************/
    /******************** EVENTS ********************/
    /************************************************/

    pub event ContractInitialized()

    /***********************************************/
    /******************** STATE ********************/
    /***********************************************/


    /***********************************************/
    /**************** FUNCTIONALITY ****************/
    /***********************************************/

    pub struct interface IModule {
        access(account) fun verify(_ params: {String: AnyStruct})
    }

    pub resource interface WhitelistPublic {
        pub var active: Bool
        pub let dateCreated: UFix64
        pub let description: String 
        pub let eventId: UInt64
        pub let host: Address
        pub let image: String 
        pub let name: String
        pub var totalCount: UInt64
        pub let url: String
        pub fun getRegistered(): [Address]
        pub fun getExtraMetadata(): {String: String}
        pub fun hasRegistered(account: Address): Bool
        pub fun getModules(): [{IModule}]
        access(account) fun register(account: Address, params: {String: AnyStruct})
    }

    //
    // Event
    //
    pub resource Whitelist: WhitelistPublic {
        pub var active: Bool
        access(account) var registered: {Address: Bool}
        pub let dateCreated: UFix64
        pub let description: String 
        pub let eventId: UInt64
        access(account) var extraMetadata: {String: String}
        pub let host: Address
        pub let image: String 
        pub let name: String
        pub var totalCount: UInt64
        pub let url: String
        pub let modules: [{IModule}]

        /***************** Setters for the Event Owner *****************/

        // Toggles claiming on/off
        pub fun toggleActive(): Bool {
            self.active = !self.active
            return self.active
        }

        // Updates the metadata in case you want
        // to add something. Not currently used for anything
        // on FLOAT, so it's empty.
        pub fun updateMetadata(newExtraMetadata: {String: String}) {
            self.extraMetadata = newExtraMetadata
        }

        /***************** Getters (all exposed to the public) *****************/

        pub fun getRegistered(): [Address] {
            return self.registered.keys
        }

        pub fun hasRegistered(account: Address): Bool {
            return self.registered[account] != nil
        }

        pub fun getExtraMetadata(): {String: String} {
            return self.extraMetadata
        }

        pub fun getModules(): [{IModule}] {
            return self.modules
        }

        /****************** Registering ******************/

        pub fun register(account: Address, params: {String: AnyStruct}) {
            pre {
                self.active: 
                    "This FLOATEvent is not claimable, and thus not currently active."
            }
            
            for module in self.modules {
                module.verify(params)
            }

            self.registered[account] = true
            self.totalCount = self.totalCount + 1
        }

        init (
            _active: Bool,
            _description: String, 
            _extraMetadata: {String: String},
            _host: Address, 
            _image: String, 
            _name: String,
            _url: String,
            _modules: [{IModule}],
        ) {
            self.active = _active
            self.dateCreated = getCurrentBlock().timestamp
            self.description = _description
            self.eventId = self.uuid
            self.extraMetadata = _extraMetadata
            self.host = _host
            self.image = _image
            self.name = _name
            self.registered = {}
            self.totalCount = 0
            self.url = _url
            self.modules = _modules
        }

        destroy() {
           
        }
    }
 
    // 
    // FLOATEvents
    //
    pub resource interface RegistryPublic {
        // Public Getters
        pub fun borrowPublicEventRef(eventId: UInt64): &Whitelist{WhitelistPublic}
        pub fun getIDs(): [UInt64]
    }

    pub resource Registry: RegistryPublic {
        access(account) var events: @{UInt64: Whitelist}

        // ACCESSIBLE BY: Owner
        // Create a new Whitelist.
        pub fun createEvent(
            active: Bool,
            description: String,
            image: String, 
            name: String, 
            url: String,
            modules: [{IModule}],
            _ extraMetadata: {String: String}
        ): UInt64 {
            let FLOATEvent <- create Whitelist(
                _active: active,
                _description: description, 
                _extraMetadata: extraMetadata,
                _host: self.owner!.address, 
                _image: image, 
                _name: name, 
                _url: url,
                _modules: modules
            )
            let eventId = FLOATEvent.eventId
            self.events[FLOATEvent.eventId] <-! FLOATEvent
            return eventId
        }

        // ACCESSIBLE BY: Owner
        pub fun deleteWhitelist(eventId: UInt64) {
            let whitelist <- self.events.remove(key: eventId) ?? panic("This event does not exist")
            destroy whitelist
        }

        // ACCESSIBLE BY: Owner, Contract
        pub fun borrowEventRef(eventId: UInt64): &Whitelist {
            return &self.events[eventId] as &Whitelist
        }

        /************* Getters (for anyone) *************/

        // Get a public reference to the FLOATEvent
        // so you can call some helpful getters
        pub fun borrowPublicEventRef(eventId: UInt64): &Whitelist{WhitelistPublic} {
            return &self.events[eventId] as &Whitelist{WhitelistPublic}
        }

        pub fun getIDs(): [UInt64] {
            return self.events.keys
        }

        pub fun register(whitelist: &Whitelist{WhitelistPublic}, params: {String: AnyStruct}) {
            let registree = self.owner!.address
            params["registree"] = registree
            whitelist.register(account: registree, params: params)
        }

        init() {
            self.events <- {}
        }

        destroy() {
            destroy self.events
        }
    }

    pub fun createEmptyRegistry(): @Registry {
        return <- create Registry()
    }

    init() {
        emit ContractInitialized()

        self.RegistryStoragePath = /storage/PremintRegistryStoragePath002
        self.RegistryPublicPath = /public/PremintRegistryPublicPath002
    }
}