//
//  CategoryViewController.swift
//  HocTiengTrung
//
//  Created by Katharos on 06/01/2023.
//

import UIKit
import SQLite

class CategoryViewController: UIViewController {
    
    @IBOutlet weak var categoryCollectionView: UICollectionView!
    
    @IBOutlet var searchBar: UISearchBar!
    
    @IBOutlet var bookmarkOutlet: UIButton!
    
    @IBAction func backButton(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func bookmarkButton(_ sender: UIButton) {
        let vc = storyboard?.instantiateViewController(withIdentifier: BookmarkViewController.identifier) as! BookmarkViewController
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true)
    }
    
    static let identifier = "CategoryViewController"
    
    var categoryList: [CategoryModel] = [CategoryModel]()
    var searchingDataList: [CategoryModel] = [CategoryModel]()
    var bookmarkList: [PhraseModel] = [PhraseModel]()
    
    var searching = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        categoryCollectionView.register(CategoryCollectionViewCell.nib(), forCellWithReuseIdentifier: CategoryCollectionViewCell.identifier)
        categoryCollectionView.delegate = self
        categoryCollectionView.dataSource = self
        
        searchBar.delegate = self
        
        categoryCollectionView.backgroundColor = .clear
        searchBar.layer.cornerRadius = 14
    }
    
    override func viewWillAppear(_ animated: Bool) {
        bookmarkList = PhraseService.shared.getFavouriteData()

        if bookmarkList.count == 0 {
            bookmarkOutlet.alpha = 1.0
            bookmarkOutlet.setImage(UIImage(named: "grayheart"), for: .normal)
        } else {
            bookmarkOutlet.alpha = 1.0
            bookmarkOutlet.setImage(UIImage(named: "pinkheart"), for: .normal)
        }
        
        categoryList = CategoryService.shared.getData()
        
        categoryCollectionView.reloadData()
    }
}

// MARK: - UICategoryViewControllerDelegate Methods

extension CategoryViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let vc = storyboard?.instantiateViewController(withIdentifier: LearningViewController.identifier) as! LearningViewController
        
        if searching {
            vc.categoryId = searchingDataList[indexPath.item].id
            vc.phraseList = PhraseService.shared.getPhrasesData(categoryId: indexPath.item + 1)
            vc.categoryName = searchingDataList[indexPath.item].category
        } else {
            vc.categoryId = indexPath.item + 1
            vc.phraseList = PhraseService.shared.getPhrasesData(categoryId: indexPath.item + 1)
            vc.categoryName = categoryList[indexPath.item].category
        }
        
        vc.modalPresentationStyle = .fullScreen
        
        self.present(vc, animated: true)
    }
}

// MARK: - UICategoryViewControllerDatasource Methods

extension CategoryViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if searching {
            return searchingDataList.count
        }
        return categoryList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryCollectionViewCell.identifier, for: indexPath) as! CategoryCollectionViewCell
        cell.categoryImage.layer.cornerRadius = 10
                
        if searching {
            cell.categoryImage.image = UIImage(named: searchingDataList[indexPath.item].thumbnail)
            cell.categoryLabel.text = searchingDataList[indexPath.item].category
        } else {
            cell.categoryImage.image = UIImage(named: categoryList[indexPath.item].thumbnail)
            cell.categoryLabel.text = categoryList[indexPath.item].category
        }
        
        return cell
    }
}

extension CategoryViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return CGSize(width: collectionView.frame.width/4 - 20, height: collectionView.frame.width/4 - 20)
        }
        return CGSize(width: 154, height: 160)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 15
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 20
    }
}

extension CategoryViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let textFieldInsideSearchBar = searchBar.value(forKey: "searchField") as? UITextField
        
        textFieldInsideSearchBar?.textColor = .white
        
        searchingDataList = categoryList.filter({ (userData: CategoryModel) -> Bool in
            let data = userData.category.lowercased()
            if searchText != "" {
                return data.contains(searchText.lowercased())
            } else {
                return true
            }
        })
        
        if searchText != "" {
            searching = true
            self.categoryCollectionView.reloadData()
        } else {
            searching = false
            self.categoryCollectionView.reloadData()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searching = true
        searchBar.endEditing(true)
        self.categoryCollectionView.reloadData()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        searchBar.endEditing(true)
    }
}

