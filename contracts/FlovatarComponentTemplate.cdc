/*

 This contract defines the Flovatar Component Templates and the Collection to manage them.
 While Components are the building blocks (lego bricks) of the final Flovatar, 
 Templates are the blueprint where all the details and characteristics of each component are defined.
 The main part is the SVG (stored on-chain as a String) and the category that can be one of the following: 
 body, hair, facialHair, eyes, nose, mouth, clothing, accessory, hat, eyeglasses, background.

 Templates are NOT using the NFT standard and will be always linked only to the contract's owner account.

 Each templates will also declare in advance the maximum amount of mintable components, so that 
 the scarcity can be enforced by the smart contract itself and so that different rarities can be guaranteed.

 Finally, Templates are organized in Series, so that in the future it will be possible to create new editions
 with different characters and styles.

 */

access(all)
contract FlovatarComponentTemplate{ 
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	// Counter for all the Templates ever minted
	access(all)
	var totalSupply: UInt64
	
	//These counters will keep track of how many Components were minted for each Template
	access(contract)
	let totalMintedComponents:{ UInt64: UInt64}
	
	access(contract)
	let lastComponentMintedAt:{ UInt64: UFix64}
	
	// Event to notify about the Template creation
	access(all)
	event ContractInitialized()
	
	access(all)
	event Created(
		id: UInt64,
		name: String,
		category: String,
		color: String,
		maxMintableComponents: UInt64
	)
	
	// The public interface providing the SVG and all the other 
	// metadata like name, category, color, series, description and 
	// the maximum mintable Components
	access(all)
	resource interface Public{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let category: String
		
		access(all)
		let color: String
		
		access(all)
		let description: String
		
		access(all)
		let svg: String
		
		access(all)
		let series: UInt32
		
		access(all)
		let maxMintableComponents: UInt64
		
		access(all)
		let rarity: String
	}
	
	// The Component resource implementing the public interface as well
	access(all)
	resource ComponentTemplate: Public{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let category: String
		
		access(all)
		let color: String
		
		access(all)
		let description: String
		
		access(all)
		let svg: String
		
		access(all)
		let series: UInt32
		
		access(all)
		let maxMintableComponents: UInt64
		
		access(all)
		let rarity: String
		
		// Initialize a Template with all the necessary data
		init(name: String, category: String, color: String, description: String, svg: String, series: UInt32, maxMintableComponents: UInt64, rarity: String){ 
			// increments the counter and stores it as the ID
			FlovatarComponentTemplate.totalSupply = FlovatarComponentTemplate.totalSupply + UInt64(1)
			self.id = FlovatarComponentTemplate.totalSupply
			self.name = name
			self.category = category
			self.color = color
			self.description = description
			self.svg = svg
			self.series = series
			self.maxMintableComponents = maxMintableComponents
			self.rarity = rarity
		}
	}
	
	// Standard CollectionPublic interface that can also borrow Component Templates
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		fun borrowComponentTemplate(id: UInt64): &{FlovatarComponentTemplate.Public}?
	}
	
	// The main Collection that manages the Templates and that implements also the Public interface
	access(all)
	resource Collection: CollectionPublic{ 
		// Dictionary of Component Templates
		access(all)
		var ownedComponentTemplates: @{UInt64: FlovatarComponentTemplate.ComponentTemplate}
		
		init(){ 
			self.ownedComponentTemplates <-{} 
		}
		
		// deposit takes a Component Template and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(componentTemplate: @FlovatarComponentTemplate.ComponentTemplate){ 
			let id: UInt64 = componentTemplate.id
			
			// add the new Component Template to the dictionary which removes the old one
			let oldComponentTemplate <- self.ownedComponentTemplates[id] <- componentTemplate
			destroy oldComponentTemplate
		}
		
		// getIDs returns an array of the IDs that are in the collection
		access(all)
		fun getIDs(): [UInt64]{ 
			return self.ownedComponentTemplates.keys
		}
		
		// borrowComponentTemplate returns a borrowed reference to a Component Template
		// so that the caller can read data and call methods from it.
		access(all)
		fun borrowComponentTemplate(id: UInt64): &{FlovatarComponentTemplate.Public}?{ 
			if self.ownedComponentTemplates[id] != nil{ 
				let ref = (&self.ownedComponentTemplates[id] as &FlovatarComponentTemplate.ComponentTemplate?)!
				return ref
			} else{ 
				return nil
			}
		}
	}
	
	// This function can only be called by the account owner to create an empty Collection
	access(account)
	fun createEmptyCollection(): @FlovatarComponentTemplate.Collection{ 
		return <-create Collection()
	}
	
	// This struct is used to send a data representation of the Templates 
	// when retrieved using the contract helper methods outside the collection.
	access(all)
	struct ComponentTemplateData{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let category: String
		
		access(all)
		let color: String
		
		access(all)
		let description: String
		
		access(all)
		let svg: String?
		
		access(all)
		let series: UInt32
		
		access(all)
		let maxMintableComponents: UInt64
		
		access(all)
		let totalMintedComponents: UInt64
		
		access(all)
		let lastComponentMintedAt: UFix64
		
		access(all)
		let rarity: String
		
		init(
			id: UInt64,
			name: String,
			category: String,
			color: String,
			description: String,
			svg: String?,
			series: UInt32,
			maxMintableComponents: UInt64,
			rarity: String
		){ 
			self.id = id
			self.name = name
			self.category = category
			self.color = color
			self.description = description
			self.svg = svg
			self.series = series
			self.maxMintableComponents = maxMintableComponents
			self.totalMintedComponents = FlovatarComponentTemplate.getTotalMintedComponents(id: id)!
			self.lastComponentMintedAt = FlovatarComponentTemplate.getLastComponentMintedAt(id: id)!
			self.rarity = rarity
		}
	}
	
	// Get all the Component Templates from the account. 
	// We hide the SVG field because it might be too big to execute in a script
	access(all)
	fun getComponentTemplates(): [ComponentTemplateData]{ 
		var componentTemplateData: [ComponentTemplateData] = []

		if let componentTemplateCollection = self.account.capabilities.borrow<&FlovatarComponentTemplate.Collection>(FlovatarComponentTemplate.CollectionPublicPath){ 
			for id in componentTemplateCollection.getIDs(){ 
				var componentTemplate = componentTemplateCollection.borrowComponentTemplate(id: id)
				componentTemplateData.append(ComponentTemplateData(id: id, name: (componentTemplate!).name, category: (componentTemplate!).category, color: (componentTemplate!).color, description: (componentTemplate!).description, svg: nil, series: (componentTemplate!).series, maxMintableComponents: (componentTemplate!).maxMintableComponents, rarity: (componentTemplate!).rarity))
			}
		}
			 
		return componentTemplateData
	}
	
	// Gets a specific Template from its ID
	access(all)
	fun getComponentTemplate(id: UInt64): ComponentTemplateData?{ 
		
		if let componentTemplateCollection = self.account.capabilities.borrow<&FlovatarComponentTemplate.Collection>(FlovatarComponentTemplate.CollectionPublicPath){ 
			if let componentTemplate = componentTemplateCollection.borrowComponentTemplate(id: id){ 
				return ComponentTemplateData(id: id, name: (componentTemplate!).name, category: (componentTemplate!).category, color: (componentTemplate!).color, description: (componentTemplate!).description, svg: (componentTemplate!).svg, series: (componentTemplate!).series, maxMintableComponents: (componentTemplate!).maxMintableComponents, rarity: (componentTemplate!).rarity)
			}
		}
		return nil
	}
	
	// Returns the amount of minted Components for a specific Template
	access(all)
	fun getTotalMintedComponents(id: UInt64): UInt64?{ 
		return FlovatarComponentTemplate.totalMintedComponents[id]
	}
	
	// Returns the timestamp of the last time a Component for a specific Template was minted
	access(all)
	fun getLastComponentMintedAt(id: UInt64): UFix64?{ 
		return FlovatarComponentTemplate.lastComponentMintedAt[id]
	}
	
	// This function is used within the contract to set the new counter for each Template
	access(account)
	fun setTotalMintedComponents(id: UInt64, value: UInt64){ 
		FlovatarComponentTemplate.totalMintedComponents[id] = value
	}
	
	// This function is used within the contract to set the timestamp 
	// when a Component for a specific Template was minted
	access(account)
	fun setLastComponentMintedAt(id: UInt64, value: UFix64){ 
		FlovatarComponentTemplate.lastComponentMintedAt[id] = value
	}
	
	// It creates a new Template with the data provided.
	// This is used from the Flovatar Admin resource
	access(account)
	fun createComponentTemplate(
		name: String,
		category: String,
		color: String,
		description: String,
		svg: String,
		series: UInt32,
		maxMintableComponents: UInt64,
		rarity: String
	): @FlovatarComponentTemplate.ComponentTemplate{ 
		var newComponentTemplate <-
			create ComponentTemplate(
				name: name,
				category: category,
				color: color,
				description: description,
				svg: svg,
				series: series,
				maxMintableComponents: maxMintableComponents,
				rarity: rarity
			)
		
		// Emits the Created event to notify about the new Template
		emit Created(
			id: newComponentTemplate.id,
			name: newComponentTemplate.name,
			category: newComponentTemplate.category,
			color: newComponentTemplate.color,
			maxMintableComponents: newComponentTemplate.maxMintableComponents
		)
		
		// Set the counter for the minted Components of this Template to 0
		FlovatarComponentTemplate.setTotalMintedComponents(
			id: newComponentTemplate.id,
			value: UInt64(0)
		)
		FlovatarComponentTemplate.setLastComponentMintedAt(
			id: newComponentTemplate.id,
			value: UFix64(0)
		)
		return <-newComponentTemplate
	}
	
	// ----------------------------------------------------------------------------------------------------------------
	// Restrictions (2026-11 incident)
	//
	// Admin-managed registry of restricted addresses and restricted NFT ids. The NFT, marketplace, inbox and crafting
	// contracts of this account consult it:
	//   - a restricted id can't be withdrawn, sold, listed, used for crafting / building / upgrading,
	//     and can only be deposited into this contract account itself;
	//   - a restricted address can't withdraw, sell, claim or receive this account's NFTs / rewards.
	//
	// Why it lives here: Flow mainnet does not accept NEW contract deployments without allow-listing, and an
	// in-place update can't add fields to an existing contract. So this was added in an update as new nested types
	// and functions, and the state is a FlovatarComponentTemplate.RestrictionsRegistry resource saved in this contract account's
	// storage at /storage/FlovatarRestrictionsRegistry (created by setupRestrictionsRegistry, called from an admin transaction).
	// No registry = nothing is restricted.
	//
	// Every change emits an event. Restrictions can be removed again by the admin (to fix mistakes).
	// Status is public: isRestricted / getRestrictionStatus, and the NFT contracts add a "restricted" trait to their
	// metadata.
	// ----------------------------------------------------------------------------------------------------------------

	access(all) entitlement RestrictionsManage

	access(all) event AddressRestricted(address: Address, reason: String)
	access(all) event AddressUnrestricted(address: Address)
	access(all) event IDsRestricted(nftType: String, ids: [UInt64], reason: String)
	access(all) event IDsUnrestricted(nftType: String, ids: [UInt64])

	access(all) struct RestrictionStatus {
		access(all) let nftType: String
		access(all) let id: UInt64
		access(all) let idRestricted: Bool
		access(all) let ownerRestricted: Bool
		access(all) let reason: String?

		view init(nftType: String, id: UInt64, idRestricted: Bool, ownerRestricted: Bool, reason: String?) {
			self.nftType = nftType
			self.id = id
			self.idRestricted = idRestricted
			self.ownerRestricted = ownerRestricted
			self.reason = reason
		}
	}

	// Held only in this contract account's storage. Mutators need the RestrictionsManage entitlement, which only the
	// account itself can obtain (storage borrow); no capability to it is ever issued.
	access(all) resource RestrictionsRegistry {

		// address -> reason
		access(self) let restrictedAddresses: {Address: String}

		// NFT type identifier -> (id -> reason)
		access(self) let restrictedIDs: {String: {UInt64: String}}

		access(all) view fun getAddressReason(_ address: Address): String? {
			return self.restrictedAddresses[address]
		}

		access(all) view fun getIDReason(nftType: String, id: UInt64): String? {
			if let ids = &self.restrictedIDs[nftType] as &{UInt64: String}? {
				return ids[id]
			}
			return nil
		}

		access(all) view fun getRestrictedAddresses(): [Address] {
			return self.restrictedAddresses.keys
		}

		access(all) view fun getRestrictedTypes(): [String] {
			return self.restrictedIDs.keys
		}

		access(all) view fun getRestrictedIDCount(nftType: String): Int {
			if let ids = &self.restrictedIDs[nftType] as &{UInt64: String}? {
				return ids.length
			}
			return 0
		}

		access(all) view fun getRestrictedIDs(nftType: String, from: Int, upTo: Int): [UInt64] {
			if let ids = &self.restrictedIDs[nftType] as &{UInt64: String}? {
				let keys = ids.keys
				let end = upTo < keys.length ? upTo : keys.length
				if from >= end {
					return []
				}
				return keys.slice(from: from, upTo: end)
			}
			return []
		}

		access(RestrictionsManage) fun restrictAddress(_ address: Address, reason: String) {
			self.restrictedAddresses[address] = reason
			emit AddressRestricted(address: address, reason: reason)
		}

		access(RestrictionsManage) fun unrestrictAddress(_ address: Address) {
			self.restrictedAddresses.remove(key: address)
			emit AddressUnrestricted(address: address)
		}

		// Batches: keep ids.length <= 500 per call (event size / computation).
		access(RestrictionsManage) fun restrictIDs(nftType: Type, ids: [UInt64], reason: String) {
			pre {
				ids.length <= 500: "Max 500 ids per call"
			}
			let key = nftType.identifier
			if self.restrictedIDs[key] == nil {
				self.restrictedIDs[key] = {}
			}
			let map = (&self.restrictedIDs[key] as auth(Mutate) &{UInt64: String}?)!
			for id in ids {
				map[id] = reason
			}
			emit IDsRestricted(nftType: key, ids: ids, reason: reason)
		}

		access(RestrictionsManage) fun unrestrictIDs(nftType: Type, ids: [UInt64]) {
			pre {
				ids.length <= 500: "Max 500 ids per call"
			}
			let key = nftType.identifier
			if let map = &self.restrictedIDs[key] as auth(Mutate) &{UInt64: String}? {
				for id in ids {
					map.remove(key: id)
				}
			}
			emit IDsUnrestricted(nftType: key, ids: ids)
		}

		init() {
			self.restrictedAddresses = {}
			self.restrictedIDs = {}
		}
	}

	access(all) view fun getRestrictionsRegistryStoragePath(): StoragePath {
		return /storage/FlovatarRestrictionsRegistry
	}

	access(contract) view fun borrowRestrictionsRegistry(): &RestrictionsRegistry? {
		return self.account.storage.borrow<&RestrictionsRegistry>(from: /storage/FlovatarRestrictionsRegistry)
	}

	// True once setupRestrictionsRegistry has been run by the contract account.
	access(all) view fun isRestrictionsRegistrySetUp(): Bool {
		return self.borrowRestrictionsRegistry() != nil
	}

	// Creates the registry in this contract account's storage. Only the contract account can call it with effect
	// (it must pass a reference to its own account). Idempotent.
	access(all) fun setupRestrictionsRegistry(account: auth(Storage) &Account) {
		pre {
			account.address == self.account.address: "Only the contract account can set up the restrictions registry"
		}
		if account.storage.type(at: /storage/FlovatarRestrictionsRegistry) == nil {
			account.storage.save(<-create RestrictionsRegistry(), to: /storage/FlovatarRestrictionsRegistry)
		}
	}

	// ---- public, read-only views ----

	access(all) view fun isAddressRestricted(_ address: Address?): Bool {
		if address == nil {
			return false
		}
		if let registry = self.borrowRestrictionsRegistry() {
			return registry.getAddressReason(address!) != nil
		}
		return false
	}

	access(all) view fun isIDRestricted(nftType: Type, id: UInt64): Bool {
		if let registry = self.borrowRestrictionsRegistry() {
			return registry.getIDReason(nftType: nftType.identifier, id: id) != nil
		}
		return false
	}

	// True if the id is restricted or the given holder address is restricted.
	access(all) view fun isRestricted(nftType: Type, id: UInt64, owner: Address?): Bool {
		return self.isIDRestricted(nftType: nftType, id: id) || self.isAddressRestricted(owner)
	}

	access(all) view fun getRestrictionStatus(nftType: Type, id: UInt64, owner: Address?): RestrictionStatus {
		var reason: String? = nil
		if let registry = self.borrowRestrictionsRegistry() {
			reason = registry.getIDReason(nftType: nftType.identifier, id: id)
			if reason == nil && owner != nil {
				reason = registry.getAddressReason(owner!)
			}
		}
		return RestrictionStatus(
			nftType: nftType.identifier,
			id: id,
			idRestricted: self.isIDRestricted(nftType: nftType, id: id),
			ownerRestricted: self.isAddressRestricted(owner),
			reason: reason
		)
	}

	access(all) view fun getAddressReason(_ address: Address): String? {
		if let registry = self.borrowRestrictionsRegistry() {
			return registry.getAddressReason(address)
		}
		return nil
	}

	access(all) view fun getRestrictedAddresses(): [Address] {
		if let registry = self.borrowRestrictionsRegistry() {
			return registry.getRestrictedAddresses()
		}
		return []
	}

	access(all) view fun getRestrictedTypes(): [String] {
		if let registry = self.borrowRestrictionsRegistry() {
			return registry.getRestrictedTypes()
		}
		return []
	}

	access(all) view fun getRestrictedIDCount(nftType: Type): Int {
		if let registry = self.borrowRestrictionsRegistry() {
			return registry.getRestrictedIDCount(nftType: nftType.identifier)
		}
		return 0
	}

	// Paged list (ids are returned in dictionary order).
	access(all) view fun getRestrictedIDs(nftType: Type, from: Int, upTo: Int): [UInt64] {
		if let registry = self.borrowRestrictionsRegistry() {
			return registry.getRestrictedIDs(nftType: nftType.identifier, from: from, upTo: upTo)
		}
		return []
	}

	// ---- checks used by the NFT / marketplace / crafting contracts (they panic) ----

	// Withdrawing / transferring / listing / selling an NFT held by `owner`.
	access(all) view fun assertTransferAllowed(nftType: Type, id: UInt64, owner: Address?) {
		pre {
			!self.isIDRestricted(nftType: nftType, id: id): "Restricted: this NFT is restricted and can't be transferred, sold or used"
			!self.isAddressRestricted(owner): "Restricted: the holder address is restricted"
		}
	}

	// Depositing an NFT into a collection owned by `to`.
	// Restricted ids may only be deposited into this contract account (or into a collection that is not stored yet).
	access(all) view fun assertDepositAllowed(nftType: Type, id: UInt64, to: Address?) {
		pre {
			!self.isAddressRestricted(to): "Restricted: the recipient address is restricted"
			!self.isIDRestricted(nftType: nftType, id: id) || to == nil || to == self.account.address: "Restricted: this NFT is restricted and can't be deposited here"
		}
	}

	// Using an NFT as input of crafting / building / upgrading / equipping.
	access(all) view fun assertUsable(nftType: Type, id: UInt64) {
		pre {
			!self.isIDRestricted(nftType: nftType, id: id): "Restricted: this NFT is restricted and can't be used"
		}
	}

	// An address that wants to claim / receive rewards or act as buyer / seller.
	access(all) view fun assertAddressAllowed(_ address: Address?) {
		pre {
			!self.isAddressRestricted(address): "Restricted: this address is restricted"
		}
	}

	// ---------------------------------------------------------------------------------------------- end Restrictions

	init(){ 
		self.CollectionPublicPath = /public/FlovatarComponentTemplateCollection
		self.CollectionStoragePath = /storage/FlovatarComponentTemplateCollection
		
		// Initialize the total supply
		self.totalSupply = 0
		self.totalMintedComponents ={} 
		self.lastComponentMintedAt ={} 
		self.account.storage.save<@FlovatarComponentTemplate.Collection>(
			<-FlovatarComponentTemplate.createEmptyCollection(),
			to: FlovatarComponentTemplate.CollectionStoragePath
		)
		var capability_1 =
			self.account.capabilities.storage.issue<&{FlovatarComponentTemplate.CollectionPublic}>(
				FlovatarComponentTemplate.CollectionStoragePath
			)
		self.account.capabilities.publish(
			capability_1,
			at: FlovatarComponentTemplate.CollectionPublicPath
		)
		emit ContractInitialized()
	}
}
