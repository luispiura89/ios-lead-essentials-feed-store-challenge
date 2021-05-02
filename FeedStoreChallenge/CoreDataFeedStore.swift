//
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import CoreData

public final class CoreDataFeedStore: FeedStore {
	private static let modelName = "FeedStore"
	private static let model = NSManagedObjectModel(name: modelName, in: Bundle(for: CoreDataFeedStore.self))

	private let container: NSPersistentContainer
	private let context: NSManagedObjectContext

	struct ModelNotFound: Error {
		let modelName: String
	}

	public init(storeURL: URL) throws {
		guard let model = CoreDataFeedStore.model else {
			throw ModelNotFound(modelName: CoreDataFeedStore.modelName)
		}

		container = try NSPersistentContainer.load(
			name: CoreDataFeedStore.modelName,
			model: model,
			url: storeURL
		)
		context = container.newBackgroundContext()
	}

	public func retrieve(completion: @escaping RetrievalCompletion) {
		let context = self.context
		context.perform {
			do {
				let fetchedCache = try ManagedCache.find(in: context)
				if let cache = fetchedCache {
					return completion(.found(feed: cache.feed.array.compactMap {
						$0 as? ManagedFeedImage
					}.map {
						LocalFeedImage(id: $0.id, description: $0.imageDescription, location: $0.location, url: $0.url)
					}, timestamp: cache.timestamp))
				} else {
					completion(.empty)
				}
			} catch {
				completion(.failure(error))
			}
		}
	}

	public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
		let context = self.context
		context.perform {
			do {
				let cache = ManagedCache(context: context)
				cache.timestamp = timestamp
				cache.feed = NSOrderedSet(array: feed.map {
					let image = ManagedFeedImage(context: context)

					image.id = $0.id
					image.imageDescription = $0.description
					image.location = $0.location
					image.url = $0.url

					return image
				})

				try context.save()
				completion(nil)
			} catch {
				completion(error)
			}
		}
	}

	public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
		fatalError("Must be implemented")
	}
}

@objc(ManagedCache)
private class ManagedCache: NSManagedObject {
	@NSManaged var timestamp: Date
	@NSManaged var feed: NSOrderedSet

	static func find(in context: NSManagedObjectContext) throws -> ManagedCache? {
		let request = NSFetchRequest<ManagedCache>(entityName: ManagedCache.entity().name!)
		let fetchResult = try context.fetch(request)
		return fetchResult.first
	}
}

@objc(ManagedFeedImage)
private class ManagedFeedImage: NSManagedObject {
	@NSManaged var id: UUID
	@NSManaged var imageDescription: String?
	@NSManaged var location: String?
	@NSManaged var url: URL
	@NSManaged var cache: ManagedCache
}
