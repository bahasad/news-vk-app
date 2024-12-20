//
//  NewsFeedPresenter.swift
//  NewsVKApp
//
//  Created by Baha Sadyr on 12/5/24.
//

import Foundation

protocol NewsFeedPresenterProtocol: AnyObject {
    
    init(view: NewsFeedVCProtocol, networkService: NetworkServiceProtocol, dataManager: DataManager, imageCacheManager: ImageCacheManager)
    func getAllNews()
    func getNewsBySearchWord(searchWord: String)
    var news: [NewsFeedItems]? { get set }
    func handleStarButtonTap(for newsItem: NewsFeedItems)
    func fetchAllFavouriteNews() -> [SavedNews]
    func fetchImage(for urlString: String, completion: @escaping (Data?) -> Void)
    
}

class NewsFeedPresenter: NewsFeedPresenterProtocol {
    
    weak var view: NewsFeedVCProtocol?
    let networkService: NetworkServiceProtocol
    var news: [NewsFeedItems]?
    let dataManager: DataManager
    let imageCacheManager: ImageCacheManager
    
    required init(view: NewsFeedVCProtocol, networkService: any NetworkServiceProtocol, dataManager: DataManager, imageCacheManager: ImageCacheManager) {
        self.view = view
        self.networkService = networkService
        self.dataManager = dataManager
        self.imageCacheManager = imageCacheManager
        getAllNews()
    }
    
    func getAllNews() {
        Task {
            do {
                news = try await networkService.fetchAllNews()
                print("Fetched it: \(String(describing: news))")
                DispatchQueue.main.async { [weak self] in
                    self?.view?.updateNewsFeed(with: self?.news ?? [])
                }
            } catch CustomError.invalidURL {
                print("invalid URL")
            } catch CustomError.invalidResponse {
                print("invalid Response")
            } catch CustomError.invalidData {
                print("invalid Data")
            } catch {
                print("unexpected error")
            }
        }
    }
    
    func getNewsBySearchWord(searchWord: String) {
        Task {
            do {
                news = try await networkService.fetchNewsBySearchWord(searchWord: searchWord)
                print("Fetched it: \(String(describing: news))")
                DispatchQueue.main.async { [weak self] in
                    self?.view?.updateNewsFeed(with: self?.news ?? [])
                }
            } catch CustomError.invalidURL {
                print("invalid URL")
            } catch CustomError.invalidResponse {
                print("invalid Response")
            } catch CustomError.invalidData {
                print("invalid Data")
            } catch {
                print("unexpected error")
            }
        }
    }
    
    func handleStarButtonTap(for newsItem: NewsFeedItems) {
        let savedNews = dataManager.fetchAllFavouriteNews()
        if let savedItem = savedNews.first(where: { $0.id == newsItem.uuid }) {
            savedItem.deleteFavouriteNews()
            print("Bookmark removed for item: \(newsItem.title)")
        } else {
            dataManager.saveNews(newsItem: newsItem)
            print("Bookmark added for item: \(newsItem.title)")
        }
        DispatchQueue.main.async { [weak self] in
            self?.view?.updateNewsFeed(with: self?.news ?? [])
        }
    }
    
}

extension NewsFeedPresenter {
    
    func fetchAllFavouriteNews() -> [SavedNews] {
        return dataManager.fetchAllFavouriteNews()
    }
    
}

extension NewsFeedPresenter {
    
    func fetchImage(for urlString: String, completion: @escaping (Data?) -> Void) {
        if let cachedData = imageCacheManager.getImageFromCache(forKey: urlString) {
            completion(cachedData)
            return
        }
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        DispatchQueue.global(qos: .utility).async {
            do {
                let data = try Data(contentsOf: url)
                self.imageCacheManager.addImageToCache(imageData: data, forKey: urlString)
                DispatchQueue.main.async {
                    completion(data)
                }
            } catch {
                print("Failed to fetch image: \(error)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
}



