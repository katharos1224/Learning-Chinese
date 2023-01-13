//
//  CategoryModel.swift
//  HocTiengTrung
//
//  Created by Katharos on 07/01/2023.
//

import Foundation

class CategoryModel {
    var id: Int = 0
    var category: String = ""
    var thumbnail: String = ""
    
    init(id: Int, category: String, thumbnail: String) {
        self.id = id
        self.category = category
        self.thumbnail = thumbnail
    }
}
