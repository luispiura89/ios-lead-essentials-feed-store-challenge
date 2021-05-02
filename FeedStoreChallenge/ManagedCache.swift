//
//  ManagedCache.swift
//  FeedStoreChallenge
//
//  Created by Luis Francisco Piura Mejia on 5/2/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import Foundation
import CoreData

@objc(ManagedCache)
internal final class ManagedCache: NSManagedObject {
	@NSManaged var timestamp: Date
	@NSManaged var feed: NSOrderedSet

	var localFeed: [LocalFeedImage] {
		feed.array.compactMap {
			$0 as? ManagedFeedImage
		}.map {
			LocalFeedImage(id: $0.id, description: $0.imageDescription, location: $0.location, url: $0.url)
		}
	}
}

extension ManagedCache {
	static func uniqueInstance(in context: NSManagedObjectContext) throws -> ManagedCache {
		try find(in: context).map(context.delete)

		return ManagedCache(context: context)
	}

	static func find(in context: NSManagedObjectContext) throws -> ManagedCache? {
		let request = NSFetchRequest<ManagedCache>(entityName: ManagedCache.entity().name!)
		let fetchResult = try context.fetch(request)
		return fetchResult.first
	}

	static func getFeed(from feed: [LocalFeedImage], in context: NSManagedObjectContext) -> NSOrderedSet {
		return NSOrderedSet(array: feed.map {
			let image = ManagedFeedImage(context: context)

			image.id = $0.id
			image.imageDescription = $0.description
			image.location = $0.location
			image.url = $0.url

			return image
		})
	}
}
