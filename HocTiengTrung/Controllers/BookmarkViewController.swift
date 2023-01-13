//
//  BookmarkViewController.swift
//  HocTiengTrung
//
//  Created by Katharos on 07/01/2023.
//

import UIKit

class BookmarkViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var markOutlet: UIButton!
    
    @IBAction func markButton(_ sender: UIButton) {
        if bookmarkList.count > 0 {
            markOutlet.alpha = 1
            
            let count = bookmarkList.count
            
            for item in stride(from: count - 1, through: 0, by: -1) {
                bookmarkList.remove(at: item)
                tableView.deleteRows(at: [IndexPath(row: item, section: 0)], with: .left)
            }
            
            PhraseService.shared.resetFavoriteData()
        }
        tableView.reloadData()
    }
    
    @IBAction func backToCategoryButton(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBOutlet var searchBar: UISearchBar!
    
    static let identifier = "BookmarkViewController"
    
    var bookmarkList = [PhraseModel]()
    var searchingDataList = [PhraseModel]()
    
    var searching = false
    var deleting = false
    var favorite = false
    
    var selectedIndex = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(VietnameseTableViewCell.nib(), forCellReuseIdentifier: VietnameseTableViewCell.indentifier)
        tableView.register(FullPhraseTableViewCell.nib(), forCellReuseIdentifier: FullPhraseTableViewCell.indentifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        
        searchBar.layer.cornerRadius = 14
    }
    
    override func viewWillAppear(_ animated: Bool) {
        bookmarkList = PhraseService.shared.getFavouriteData()
        
        tableView.reloadData()
    }
    
    func getData() {
        bookmarkList = PhraseService.shared.getFavouriteData()
    }
}

extension BookmarkViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedIndex = indexPath.row
        tableView.reloadData()
    }
    
}

extension BookmarkViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bookmarkList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Show full phrase cell
        if selectedIndex == indexPath.row {
            let cell = tableView.dequeueReusableCell(withIdentifier: FullPhraseTableViewCell.indentifier, for: indexPath) as! FullPhraseTableViewCell
            cell.vietnameseLabel.text = bookmarkList[indexPath.item].vietnamesePhrases
            cell.chineseLabel.text = bookmarkList[indexPath.item].chinesePhrases
            cell.pinyinLabel.text = bookmarkList[indexPath.item].pinyin
            
            if bookmarkList[indexPath.item].favorite == 1 {
                cell.markOutlet.setImage(UIImage(named: "pinkstar"), for: .normal)
            }
            else {
                cell.markOutlet.setImage(UIImage(named: "graystar"), for: .normal)
            }
            
            selectedIndex = -1
            
            // Recording and playing sound methods
            
            
            cell.selectionStyle = .none
            cell.markOutlet.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap(_:))))
            return cell
        }
        
        // Show Vietnamese phrase cell
        let cell = tableView.dequeueReusableCell(withIdentifier: VietnameseTableViewCell.indentifier, for: indexPath) as! VietnameseTableViewCell
        cell.vietnameseLabel.text = bookmarkList[indexPath.item].vietnamesePhrases
        
        if bookmarkList[indexPath.item].favorite == 1 {
            cell.vietnameseLabel?.text = bookmarkList[indexPath.item].vietnamesePhrases
            cell.markOutlet.setImage(UIImage(named: "pinkstar"), for: .normal)
        }
        else {
            cell.vietnameseLabel?.text = bookmarkList[indexPath.item].vietnamesePhrases
            cell.markOutlet.setImage(UIImage(named: "pinkstar"), for: .normal)
        }
        
        cell.selectionStyle = .none
        cell.markOutlet.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap(_:))))
        return cell
    }
    
    // Tap star icon func
    @objc func tap(_ sender: UITapGestureRecognizer) {
        
        let location = sender.location(in: self.tableView)
        let indexPath = self.tableView.indexPathForRow(at: location)
        
        print("Star icon got tap!")
        
        let phraseId = bookmarkList[indexPath!.row].id
        let favoriteStatus = bookmarkList[indexPath!.row].favorite
        
        // Update favoriteStatus by selected phraseId
        PhraseService.shared.updateFavoriteData(phraseId: phraseId, favoriteStatus: favoriteStatus)
        getData()
        tableView.reloadData()
    }
}

extension BookmarkViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let textFieldInsideSearchBar = searchBar.value(forKey: "searchField") as? UITextField
        
        textFieldInsideSearchBar?.textColor = .white
        
        searchingDataList = bookmarkList.filter({ (userData: PhraseModel) -> Bool in
            let data = userData.vietnamesePhrases.lowercased()
            if searchText != "" {
                return data.contains(searchText.lowercased())
            } else {
                return true
            }
        })
        
        if searchText != "" {
            searching = true
            self.tableView.reloadData()
        } else {
            searching = false
            self.tableView.reloadData()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searching = true
        searchBar.endEditing(true)
        self.tableView.reloadData()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        searchBar.endEditing(true)
    }
}
