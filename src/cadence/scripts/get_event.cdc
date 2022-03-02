import Premint from "../Premint.cdc"

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