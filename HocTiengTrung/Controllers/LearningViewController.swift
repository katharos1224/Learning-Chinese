//
//  LearningViewController.swift
//  HocTiengTrung
//
//  Created by Katharos on 06/01/2023.
//

import UIKit
import AVFAudio

class LearningViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet var categoryLabel: UILabel!
    
    @IBAction func backButton(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBOutlet var playerOutlet: UIButton!
    
    @IBAction func playerButton(_ sender: UIButton) {
        if playing == false {
            playerOutlet.setImage(UIImage(named: "stopbtn"), for: .normal)
            playing = !playing
            print("Playing sounds!")
            
            playFemaleVoice()
            
        } else {
            playerOutlet.setImage(UIImage(named: "playbtn"), for: .normal)
            playing = !playing
            print("Stop playing sounds!")
        }
        
    }
    
    static let identifier = "LearningViewController"
    
    var playing = false
    var favorite = false
    
    var phraseList: [PhraseModel] = [PhraseModel]()
    var chinesePhraseList: [PhraseModel] = [PhraseModel]()
    var pinyinPhraseList: [PhraseModel] = [PhraseModel]()
    
    var searchingDataList: [PhraseModel] = [PhraseModel]()
    var searching = false
    
    var categoryName = ""
    var categoryId = 0
    var selectedIndex = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(VietnameseTableViewCell.nib(), forCellReuseIdentifier: VietnameseTableViewCell.indentifier)
        tableView.register(FullPhraseTableViewCell.nib(), forCellReuseIdentifier: FullPhraseTableViewCell.indentifier)
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.backgroundColor = .clear
        
        categoryLabel.text = categoryName
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        phraseList = PhraseService.shared.getVietnamesePhrasesData(categoryId: categoryId)
        tableView.reloadData()
    }
    
    func getData() {
        phraseList = PhraseService.shared.getFavouriteData()
    }
    
    func playFemaleVoice() {
        // Load "mysoundname.wav"
        
        
        if let soundURL = Bundle.main.url(forResource: "mysoundname", withExtension: "wav") {
            var mySound: SystemSoundID = 0
            AudioServicesCreateSystemSoundID(soundURL as CFURL, &mySound)
            // Play
            AudioServicesPlaySystemSound(mySound);
        }
    }
}

extension LearningViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndex = indexPath.row
        tableView.reloadData()
    }
}

extension LearningViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return phraseList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Show full phrase cell
        if selectedIndex == indexPath.row {
            let cell = tableView.dequeueReusableCell(withIdentifier: FullPhraseTableViewCell.indentifier, for: indexPath) as! FullPhraseTableViewCell
            cell.markOutlet.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap(_:))))
            cell.vietnameseLabel.text = phraseList[indexPath.item].vietnamesePhrases
            cell.chineseLabel.text = phraseList[indexPath.item].chinesePhrases
            cell.pinyinLabel.text = phraseList[indexPath.item].pinyin
            
            if phraseList[indexPath.item].favorite == 1 {
                cell.markOutlet.setImage(UIImage(named: "pinkstar"), for: .normal)
            }
            else {
                cell.markOutlet.setImage(UIImage(named: "graystar"), for: .normal)
            }
            
            selectedIndex = -1
            
            // Recording and playing sound methods
            
            
            cell.selectionStyle = .none
            
            return cell
        }
        
        // Show Vietnamese phrase cell
        let cell = tableView.dequeueReusableCell(withIdentifier: VietnameseTableViewCell.indentifier, for: indexPath) as! VietnameseTableViewCell
        cell.markOutlet.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap(_:))))
        cell.vietnameseLabel.text = phraseList[indexPath.item].vietnamesePhrases
        
        if phraseList[indexPath.item].favorite == 1 {
            cell.vietnameseLabel?.text = phraseList[indexPath.item].vietnamesePhrases
            cell.markOutlet.setImage(UIImage(named: "pinkstar"), for: .normal)
        }
        else {
            cell.vietnameseLabel?.text = phraseList[indexPath.item].vietnamesePhrases
            cell.markOutlet.setImage(UIImage(named: "graystar"), for: .normal)
        }
        
        cell.selectionStyle = .none
        
        return cell
    }
    
    @objc func tap(_ sender: UITapGestureRecognizer) {
        
        let location = sender.location(in: self.tableView)
        let indexPath = self.tableView.indexPathForRow(at: location)
        
        print("Tapped star icon!")
        
        let phraseId = phraseList[indexPath!.row].id
        let favoriteStatus = phraseList[indexPath!.row].favorite
        
        // Update favoriteStatus by selected phraseId
        PhraseService.shared.updateFavoriteData(phraseId: phraseId, favoriteStatus: favoriteStatus)
        phraseList = PhraseService.shared.getFavouriteData()
        getData()
        viewWillAppear(true)
        tableView.reloadData()
    }
}
