//
//  CategoryCollectionViewCell.swift
//  HocTiengTrung
//
//  Created by Katharos on 07/01/2023.
//

import UIKit

class CategoryCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var categoryImage: UIImageView!
    @IBOutlet var categoryLabel: UILabel!
    
    static let identifier = "categoryCollectionViewCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    static func nib() -> UINib {
        return UINib(nibName: "CategoryCollectionViewCell", bundle: nil)
    }

}
