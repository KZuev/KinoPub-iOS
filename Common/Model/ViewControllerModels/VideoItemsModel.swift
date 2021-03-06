//
//  VideoItemsModel.swift
//  KinoPub
//
//  Created by Евгений Дац on 28.09.2017.
//  Copyright © 2017 Evgeny Dats. All rights reserved.
//

import Foundation

protocol VideoItemsModelDelegate: class {
    func didUpdateItems(model: VideoItemsModel)
}

class VideoItemsModel: AccountManagerDelegate {
    weak var delegate: VideoItemsModelDelegate?
    var videoItems = [Item]()
    var videoItemsDict = [String : [Item]]()
    var parameters = [String : String]()
    var from: String?
    var page: Int = 1
    var totalPages: Int = 1
    var type: ItemType? {
        didSet {
            parameters["type"] = type?.rawValue
            if let type = type {
                parameters["genre"] = type == .cartoons ? "23" : ""
            }
        }
    }
    // Search
    var resultItems = [Item]()
    var pageOfSearch: Int = 1
    var totalPagesOfSearch: Int = 1
    // Filters
    var filter = Filter.defaultFilter
    
    // Main page
    var newFilms = [Item]()
    var newSeries = [Item]()
    var hotFilms = [Item]()
    var hotSeries = [Item]()
    var freshMovies = [Item]()
    var freshSeries = [Item]()
    
    //
    let accountManager: AccountManager
    let networkingService: VideosNetworkingService
    
    init(accountManager: AccountManager) {
        self.accountManager = accountManager
        networkingService = VideosNetworkingService(requestFactory: accountManager.requestFactory)
        accountManager.addDelegate(delegate: self)
    }
    
    func loadVideoItems(completed: @escaping (_ count: Int?) -> ()) {
        guard accountManager.hasAccount else { return }
        switch from {
        case "watching"?:
            loadWatchingSeries(completed: { (count) in
                completed(count)
            })
        case "used"?:
            loadWatchingSeries(0, completed: { (count) in
                completed(count)
            })
        case "usedMovie"?:
            loadWatchingMovie(completed: { (count) in
                completed(count)
            })
        case "collections"?:
            loadItemsCollection(completed: { (count) in
                completed(count)
            })
        default:
            loadVideos(completed: { (count, error) in
                completed(count)
            })
        }
    }
    
    func loadVideoItems(completed: @escaping (_ count: Int?, _ error: Error?) -> ()) {
        guard accountManager.hasAccount else { return }
        switch from {
        case "watching"?:
            loadWatchingSeries(completed: { (count) in
                completed(count, nil)
            })
        case "used"?:
            loadWatchingSeries(0, completed: { (count) in
                completed(count, nil)
            })
        case "usedMovie"?:
            loadWatchingMovie(completed: { (count) in
                completed(count, nil)
            })
        case "collections"?:
            loadItemsCollection(completed: { (count) in
                completed(count, nil)
            })
        default:
            loadVideos(completed: { (count, error)  in
                completed(count, error)
            })
        }
    }
    
    // Load Movies (all, fresh, hot popular), Series, Docu, TV Show, Concert
    private func loadVideos(completed: @escaping (_ count: Int?, _ error: Error?) -> ()) {
        parameters["page"] = "\(page)"
        parameters["perpage"] = "50"
        var param = parameters
        if let parameters = filter.parameters {
            param.unionInPlace(parameters)
        }
        networkingService.receiveItems(withParameters: param, from: from, completed: { [weak self] (response, error) in
            guard let strongSelf = self else { return }
            var count: Int?
            defer {
                strongSelf.delegate?.didUpdateItems(model: strongSelf)
                completed(count, error)
            }
            if let itemsData = response {
                guard var items = itemsData.items else { return }
                strongSelf.page += 1
                strongSelf.totalPages = response?.pagination?.total ?? 1
                if Config.shared.animeIsHidden {
                    items = items.filter{!($0.genres?.contains(Genres(id: 25, title: "Аниме")))!}
                }
                strongSelf.videoItems.append(contentsOf: items)
                if let key = param["type"] {
                    if strongSelf.videoItemsDict[key] == nil {
                        strongSelf.videoItemsDict[key] = [Item]()
                    }
                    strongSelf.videoItemsDict[key]?.append(contentsOf: items)
                }
                count = items.count
            } else {
                Helper.showError(error?.localizedDescription)
            }
        })
    }
    
    // Load Watchlist and Used Series
     private func loadWatchingSeries(_ subscribed: Int = 1, completed: @escaping (_ count: Int?) -> ()) {
        networkingService.receiveWatchingSeries(subscribed) { [weak self] (response, error) in
            guard let strongSelf = self else { return }
            var count: Int?
            defer {
                strongSelf.delegate?.didUpdateItems(model: strongSelf)
                completed(count)
            }
            if let itemsData = response {
                guard let items = itemsData.items else { return }
                strongSelf.videoItems.append(contentsOf: items)
                strongSelf.videoItems.unique()
                count = items.count
            } else {
                Helper.showError(error?.localizedDescription)
            }
        }
    }
    
    // Load Used Movies
    private func loadWatchingMovie(completed: @escaping (_ count: Int?) -> ()) {
        networkingService.receiveWatchingMovie { [weak self] (response, error) in
            guard let strongSelf = self else { return }
            var count: Int?
            defer {
                strongSelf.delegate?.didUpdateItems(model: strongSelf)
                completed(count)
            }
            if let itemsData = response {
                guard let items = itemsData.items else { return }
                strongSelf.videoItems.append(contentsOf: items)
                count = items.count
            } else {
                Helper.showError(error?.localizedDescription)
            }
        }
    }
    
    // Load items title search
    func loadSearchItems(_ title: String, iOS11: Bool = false, _ completed: @escaping (_ count: Int?)->()) {
        var parameters = [String : String]()
        parameters["title"] = title
        iOS11 ? (parameters["page"] = "\(pageOfSearch)") : (parameters["perpage"] = "50")
        networkingService.receiveItems(withParameters: parameters, from: nil, cancelPrevious: false, completed: { [weak self] (response, error) in
            guard let strongSelf = self else { return }
            var count: Int?
            defer { completed(count) }
            if let itemsData = response {
                guard let items = itemsData.items else { return }
                strongSelf.pageOfSearch += 1
                strongSelf.totalPagesOfSearch = response?.pagination?.total ?? 1
                strongSelf.resultItems.append(contentsOf: items)
                count = items.count
            }
        })
    }
    
    // Load collection items
    func loadItemsCollection(completed: @escaping (_ count: Int?) -> ()) {
        networkingService.receiveItemsCollection(parameters: parameters) { [weak self] (response, error) in
            guard let strongSelf = self else { return }
            var count: Int?
            defer {
                strongSelf.delegate?.didUpdateItems(model: strongSelf)
                completed(count)
            }
            if let itemsData = response {
                strongSelf.videoItems.append(contentsOf: itemsData)
                count = itemsData.count
            } else {
                Helper.showError(error?.localizedDescription)
            }
        }
    }
    
    // Load New Films
    func loadNewFilms() {
        var param = parameters
        param["type"] = ItemType.movies.rawValue
        param["sort"] = "-created"
//        let from = "fresh"
        loadItems(with: param, from: from) { [weak self] (items) in
            guard let strongSelf = self else { return }
            if let _items = items {
                strongSelf.newFilms = _items
            }
        }
    }
    
    // Load New Series
    func loadNewSeries() {
        var param = parameters
        param["type"] = ItemType.shows.rawValue
        param["sort"] = "-created"
//        let from = "fresh"
        loadItems(with: param, from: from) { [weak self] (items) in
            guard let strongSelf = self else { return }
            if var items = items {
                if Config.shared.animeIsHidden {
                    items = items.filter{!($0.genres?.contains(Genres(id: 25, title: "Аниме")))!}
                }
                strongSelf.newSeries = items
            }
        }
    }
    
    // Load Hot Films
    func loadHotFilms() {
        var param = parameters
        param["type"] = ItemType.movies.rawValue
//        let from = "hot"
        param["conditions[0]"] = "created>\(Date().timeIntervalSince1970 - 3600 * 24 * 30)"
        param["sort"] = "-views"
        loadItems(with: param, from: from) { [weak self] (items) in
            guard let strongSelf = self else { return }
            if let _items = items {
                strongSelf.hotFilms = _items
            }
        }
    }
    
    // Load Hot Series
    func loadHotSeries() {
        var param = parameters
        param["type"] = ItemType.shows.rawValue
        let from = "popular"
        loadItems(with: param, from: from) { [weak self] (items) in
            guard let strongSelf = self else { return }
            if let _items = items {
                strongSelf.hotSeries = _items
            }
        }
    }
    
    // Load Fresh Movies
    func loadFreshMovies() {
        var param = parameters
        param["type"] = ItemType.movies.rawValue
        let from = "fresh"
        loadItems(with: param, from: from) { [weak self] (items) in
            guard let strongSelf = self else { return }
            if let _items = items {
                strongSelf.freshMovies = _items
            }
        }
    }
    
    // Load Fresh Series
    func loadFreshSeries() {
        var param = parameters
        param["type"] = ItemType.shows.rawValue
        let from = "fresh"
        loadItems(with: param, from: from) { [weak self] (items) in
            guard let strongSelf = self else { return }
            if let _items = items {
                strongSelf.freshSeries = _items
            }
        }
    }
    
    // Load Items
    private func loadItems(with parameters: [String : String], from: String?, completed: @escaping (_ items: [Item]?) -> ()) {
        guard accountManager.hasAccount else { return }
        networkingService.receiveItems(withParameters: parameters, from: from) { [weak self] (response, error) in
            guard let strongSelf = self else { return }
            var items: [Item]?
            defer {
                strongSelf.delegate?.didUpdateItems(model: strongSelf)
                completed(items)
            }
            if let itemsData = response {
                items = itemsData.items
            } else {
                Helper.showError(error?.localizedDescription)
            }
        }
    }
    
    func setParameter(_ key: String, value: String?) {
        parameters[key] = value
    }
    
    func configFrom(_ from: String?) {
        self.from = from
    }
    
    func refresh() {
        page = 1
        videoItems.removeAll()
        guard let index = type?.rawValue else { return }
        videoItemsDict[index]?.removeAll()
    }
    
    func refreshSearch() {
        pageOfSearch = 1
        resultItems.removeAll()
    }
    
    func countPerPage() -> Int {
        switch from {
        case "watching"?, "used"?, "usedMovie"?:
            return 51
        case "collections"?:
            return 100
        default:
            return 20
        }
    }
}
