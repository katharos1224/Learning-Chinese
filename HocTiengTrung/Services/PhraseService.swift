//
//  PhraseService.swift
//  HocTiengTrung
//
//  Created by Katharos on 07/01/2023.
//

import Foundation
import SQLite

class PhraseService: NSObject {
    static let shared: PhraseService = PhraseService()
    
    var DatabaseRoot: Connection?
    
    var listData: [PhraseModel] = [PhraseModel]()
    let phraseTable = Table("phrase")
    let id = Expression<Int>("_id")
    let vietnamesePhrases = Expression<String>("english")
    let category_id = Expression<Int>("category_id")
    let pinyin = Expression<String>("trans_p_female")
    let chinesePhrases = Expression<String>("trans_n_female")
    let favorite = Expression<Int>("favorite")
    let voice = Expression<String>("voice")
    
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
    
    // MARK: - Get Full Data
    
    func getData() -> [PhraseModel] {
        listData.removeAll()
        if let DatabaseRoot = DatabaseRoot {
            do {
                for item in try DatabaseRoot.prepare(phraseTable) {
                    listData.append(PhraseModel(id: item[id], category_id: item[category_id], vietnamesePhrases: item[vietnamesePhrases], pinyin: item[pinyin], chinesePhrases: item[chinesePhrases], favorite: item[favorite], voice: item[voice]))
                }
            } catch {
            }
        }
        NotificationCenter.default.post(name: Notification.Name("LOADING_DATABASE_DONE"), object: nil)
        return listData
    }
    
    // MARK: - Get Phrase Data
    
    func getVietnamesePhrasesData(categoryId: Int) -> [PhraseModel] {
        listData.removeAll()
        if let DatabaseRoot = DatabaseRoot {
            do {
                for item in try DatabaseRoot.prepare(self.phraseTable.filter(self.category_id == categoryId)) {
                    
                    listData.append(PhraseModel(id: item[id], category_id: item[category_id], vietnamesePhrases: item[vietnamesePhrases], pinyin: item[pinyin], chinesePhrases: item[chinesePhrases], favorite: item[favorite], voice: item[voice]))
                    
                }
            } catch {
                print("Cannot get data from \(self.phraseTable), Error is: \(error)")
            }
        }
        return listData
    }
    
    // MARK: - Get Bookmark Data
    
    func getFavouriteData() -> [PhraseModel] {
        var favoriteData: [PhraseModel] = [PhraseModel]()
        
        do {
            if let favoriteList = try  DatabaseRoot?.prepare(self.phraseTable.filter(self.favorite == 1)) {
                for item in favoriteList {
                    favoriteData.append(PhraseModel(id: item[id], category_id: item[category_id], vietnamesePhrases: item[vietnamesePhrases], pinyin: item[pinyin], chinesePhrases: item[chinesePhrases], favorite: item[favorite], voice: item[voice]))
                }
            }
        } catch {
            print("Cannot get data from \(self.phraseTable), Error is: \(error)")
        }
        return favoriteData
    }
    
    func updateFavoriteData(phraseId: Int, favoriteStatus: Int) {
        if favoriteStatus == 0 {
            do {
                let update = phraseTable.filter(id == phraseId)
                if (try DatabaseRoot?.run(update.update(favorite <- 1)))! > 0 {
                    print("Successfully updated favorite!")
                } else {
                    print("Favorite is not found")
                }
            } catch {
                print("Failed to update favorite status!")
            }
        } else {
            do {
                let update = phraseTable.filter(id == phraseId)
                if (try DatabaseRoot?.run(update.update(favorite <- 0)))! > 0 {
                    print("Successfully updated favorite!")
                } else {
                    print("Favorite is not found")
                }
            } catch {
                print("Failed to update favorite status!")
            }
        }
    }
    
    func resetFavoriteData() {
        for item in listData {
            item.favorite = 0
        }
        let userFilter = phraseTable
        do {
            let update = userFilter.update(self.favorite <- 0)
            try DatabaseRoot!.run(update)
            print("Reseted favorite data!")
        } catch{
            print("Update failed: \(error)")
        }
    }
}
