//
//  MessageThread.swift
//  Message Board
//
//  Created by Michael Redig on 5/8/19.
//  Copyright © 2019 Michael Redig. All rights reserved.
//

import Foundation

class MessageThread: Equatable, Codable {
	let title: String
	let identifier: String
	let timestamp: Date

	var messages = [Message]()

	init(title: String, identifier: String = UUID().uuidString) {
		self.messages = []
		self.identifier = identifier
		self.title = title
		self.timestamp = Date()
	}

	required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		self.title = try container.decode(String.self, forKey: .title)
		self.identifier = try container.decode(String.self, forKey: .identifier)
		self.timestamp = try container.decode(Date.self, forKey: .timestamp)
		let messagesDictionaries = try container.decodeIfPresent([String: Message].self, forKey: .messages)

		self.messages = (messagesDictionaries?.compactMap { $0.value }) ?? []
		self.messages.sort { $0.timestamp < $1.timestamp }
	}

	struct Message: Equatable, Codable {
		let text: String
		let sender: String
		let timestamp: Date

		init(text: String, sender: String, timestamp: Date = Date()) {
			self.text = text
			self.sender = sender
			self.timestamp = timestamp
		}
	}

	static func == (rhs: MessageThread, lhs: MessageThread) -> Bool {
		return rhs.identifier == lhs.identifier
	}

	func createMessage(on thread: MessageThread, text: String, sender: String, completion: @escaping (Error?) -> Void) {
		let message = Message(text: text, sender: sender)

		var url = MessageThreadController.baseURL.appendingPathComponent(thread.identifier)
		url = url.appendingPathComponent("messages")
		url = url.appendingPathExtension("json")

		var request = URLRequest(url: url)
		request.httpMethod = HTTPMethods.post.rawValue

		let encoder = JSONEncoder()
		do {
			request.httpBody = try encoder.encode(message)
		} catch {
			print("error encoding data: \(error)")
		}

		URLSession.shared.dataTask(with: request) { (_, response, error) in
			if let error = error {
				print("error getting url '\(request.url ?? URL(string: "")!)': \(error)")
				completion(error)
				return
			} else if let response = response as? HTTPURLResponse, response.statusCode != 200 {
				print("non 200 http response: \(response.statusCode)")
				completion(HTTPError.non200StatusCode)
				return
			}
			thread.messages.append(message)
			completion(nil)
		}.resume()
	}
}
