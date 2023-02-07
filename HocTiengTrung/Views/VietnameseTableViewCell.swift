//
//  VietnameseTableViewCell.swift
//  HocTiengTrung
//
//  Created by Katharos on 09/01/2023.
//

import UIKit

class VietnameseTableViewCell: UITableViewCell {
    
    
    @IBOutlet var vietnameseLabel: UILabel!
    
    @IBOutlet var markOutlet: UIButton!
    
    var isFavorite = false
    
    static let identifier = "vietnameseTableViewCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    static func nib() -> UINib {
        return UINib(nibName: "VietnameseTableViewCell", bundle: nil)
    }
    
}
