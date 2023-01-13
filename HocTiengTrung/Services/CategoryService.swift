//
//  CategoryService.swift
//  HocTiengTrung
//
//  Created by Katharos on 07/01/2023.
//

import Foundation
import SQLite

class CategoryService: NSObject {
    static let shared: CategoryService = CategoryService()
    var DatabaseRoot: Connection?
    
    var listData: [CategoryModel] = [CategoryModel]()
    let categoryTable = Table("category")
    let id = Expression<Int>("_id")
    let category = Expression<String>("english")
    let thumbnail = Expression<String>("thumbnail")
    
    func loadInit(linkPath: String) {
        var dbPath: String = ""
        var dbResourcePath: String = ""
        
        let fileManager = FileManager.default
        
        do {
            dbPath = try fileManager
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("TrungQuoc.sqlite")
                .path
            if !fileManager.fileExists(atPath: dbPath) {
                dbResourcePath = Bundle.main.path(forResource: "TrungQuoc", ofType: "sqlite")!
                try fileManager.copyItem(atPath: dbResourcePath, toPath: dbPath)
            }
        } catch {
            print("An error has occured")
        }
        
        do {
            self.DatabaseRoot = try Connection(dbPath)
        } catch {
            print(error)
        }
    }
    
    func getData() -> [CategoryModel] {
        listData.removeAll()
        if let DatabaseRoot = DatabaseRoot {
            do {
                for item in try DatabaseRoot.prepare(categoryTable) {
                    listData.append(CategoryModel(id: Int(item[id]), category: item[category], thumbnail: item[thumbnail]))
                }
            } catch {
                print("Can not get data from \(self.categoryTable) with error: \(error)")
            }
        }
        NotificationCenter.default.post(name: Notification.Name("LOADING_DATABASE_DONE"), object: nil)
        return listData
    }
}
