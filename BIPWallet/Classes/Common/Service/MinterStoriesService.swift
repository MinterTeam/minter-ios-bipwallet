//
//  MinterStoriesService.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 22.10.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation
import RxSwift
import MinterCore

var MinterStoriesServiceBaseURLString = "https://minter-stories-api.kubernetes.icu/api"

enum MinterStoriesServiceError: Error {
  case invalidResponse
}

enum MinterStoriesServiceAPIURL {

  case stories
  case storyShowed

  var url: URL {
    switch self {
    case .stories:
      return URL(string: MinterStoriesServiceBaseURLString + "/v1/stories")!
    case .storyShowed:
      return URL(string: MinterStoriesServiceBaseURLString + "/v1/watched")!
    }
  }

}

class MinterStoriesService: StoriesService {

  private let httpClient: HTTPClient

  init(httpClient: HTTPClient = APIClient()) {
    self.httpClient = httpClient
  }

  private let storiesSubject = ReplaySubject<[IGStory]>.create(bufferSize: 1)

  func stories() -> Observable<[IGStory]> {
    return storiesSubject.asObservable()
  }

  func updateStories() {
    self.stories { [weak self] (stories, error) in
      if stories != nil {
        self?.storiesSubject.onNext(stories ?? [])
      }
    }
  }

  func storyShowed(id: Int) {
    //Send request..

    
    UserDefaults(suiteName: "stories")?.set(true, forKey: "\(id)")
    UserDefaults(suiteName: "stories")?.synchronize()
  }

  func hasSeen(storyId: Int) -> Bool {
    return UserDefaults(suiteName: "stories")?.bool(forKey: "\(storyId)") ?? false
  }

  // MARK: -

  /// Retreiving stories
  /// - Parameter completion:
  private func stories(completion: (([IGStory]?, Error?) -> ())?) {

    let url = MinterStoriesServiceAPIURL.stories.url

    self.httpClient.getRequest(url, parameters: nil) { (response, error) in
      var stories: [IGStory]?
      var error: Error?

      defer {
        completion?(stories, error)
      }

      guard let resp = response.data as? [[String: Any]] else {
        error = MinterStoriesServiceError.invalidResponse
        return
      }

      do {
        guard let data = try? JSONSerialization.data(withJSONObject: resp, options: .sortedKeys) else {
          error = MinterStoriesServiceError.invalidResponse
          return
        }
        let strs = try JSONDecoder().decode([IGStory].self, from: data)
        stories = strs
      } catch let err {
        error = err
      }
    }
  }

}
