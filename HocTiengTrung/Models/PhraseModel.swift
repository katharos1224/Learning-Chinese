//
//  PhraseModel.swift
//  HocTiengTrung
//
//  Created by Katharos on 07/01/2023.
//

import Foundation

class PhraseModel {
    var id: Int = 0
    var category_id: Int = 0
    var vietnamesePhrases: String = ""
    var pinyin: String = ""
    var chinesePhrases: String = ""
    var favorite: Int = 0
    var voice: String = ""
    
    init(id: Int, category_id: Int, vietnamesePhrases: String, pinyin: String, chinesePhrases: String, favorite: Int, voice: String) {
        self.id = id
        self.category_id = category_id
        self.vietnamesePhrases = vietnamesePhrases
        self.pinyin = pinyin
        self.chinesePhrases = chinesePhrases
        self.favorite = favorite
        self.voice = voice
    }
}
