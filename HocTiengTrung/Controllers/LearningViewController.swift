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
        dismiss(animated: false)
    }
    
    @IBOutlet var playerOutlet: UIButton!
    @IBOutlet var searchBar: UISearchBar!
    
    static let identifier = "LearningViewController"
    
    var playingAllVoices = false
    var playing = false
    var favorite = false
    var searching = false
    var isRecordingVoice = false
    var isPlayingRecordedVoice = false
    var didRecord = false
    
    var phraseList: [PhraseModel] = [PhraseModel]()
    var searchingDataList: [PhraseModel] = [PhraseModel]()
    
    var categoryName = ""
    var categoryId = 0
    var selectedIndex = -1
    var playItem = 1
    
    var audioPlayer: AVAudioPlayer?
    var voiceRecorder: AVAudioRecorder?
    var voicePlayer: AVAudioPlayer?
    
    var fileName: String = "sound.m4a"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.backgroundColor = .clear
        categoryLabel.text = categoryName
        searchBar.layer.cornerRadius = 14
        tableView.showsHorizontalScrollIndicator = false
        tableView.showsVerticalScrollIndicator = false
        
        tableView.register(VietnameseTableViewCell.nib(), forCellReuseIdentifier: VietnameseTableViewCell.identifier)
        tableView.register(FullPhraseTableViewCell.nib(), forCellReuseIdentifier: FullPhraseTableViewCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        
        searchBar.delegate = self
        
        audioPlayer?.delegate = self
        voicePlayer?.delegate = self
        voiceRecorder?.delegate = self
                
        setupRecorder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getData()
        tableView.reloadData()
        
        isPlayingRecordedVoice = false
        playing = false
        isRecordingVoice = false
    }
    
    func getData() {
        phraseList = PhraseService.shared.getPhrasesData(categoryId: categoryId)
        
        if searching {
            for item in searchingDataList {
                for item2 in phraseList {
                    if item.id == item2.id {
                        item.favorite = item2.favorite
                    }
                }
            }
        }
    }
    
    @IBAction func automaticallySelectAllRows(_ sender: UIButton) {
        audioPlayer?.delegate = self
        
        if playing {
            audioPlayer?.stop()
        }
        
        if playingAllVoices {
            playingAllVoices = false
            audioPlayer?.stop()
            playItem = 1
            playerOutlet.setImage(UIImage(named: "playbtn"), for: .normal)
        } else {
            playingAllVoices = true
            let indexPath = IndexPath(row: 0, section: 0)
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .bottom)
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPath)
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func setupRecorder() {
        let audioFileName = getDocumentsDirectory().appendingPathComponent(fileName)
        let recordSetting = [ AVFormatIDKey : kAudioFormatAppleLossless,
                   AVEncoderAudioQualityKey : AVAudioQuality.max.rawValue,
                        AVEncoderBitRateKey : 320000,
                      AVNumberOfChannelsKey : 2,
                            AVSampleRateKey : 44100] as [String: Any]
        
        do {
            voiceRecorder = try AVAudioRecorder(url: audioFileName, settings: recordSetting )
            voiceRecorder?.delegate = self
            voiceRecorder?.prepareToRecord()
        } catch {
            print(error)
        }
    }
    
    func setupPlayer() {
        let audioFileName = getDocumentsDirectory().appendingPathComponent(fileName)
        
        do {
            voicePlayer = try AVAudioPlayer(contentsOf: audioFileName)
            voicePlayer?.delegate = self
            voicePlayer?.prepareToPlay()
            voicePlayer?.volume = 5.0
        } catch {
            print(error)
        }
    }
    
    // MARK: - Playing Sound Methods for Cells
    func playCurrentVoice(soundName: String, rate: Float) {
        let pathToSound = Bundle.main.path(forResource: soundName + "_f", ofType: "m4a")!
        let url = URL(fileURLWithPath: pathToSound)
        audioPlayer?.delegate = self
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.enableRate = true
            audioPlayer?.rate = rate
            audioPlayer?.play()
            audioPlayer?.delegate = self

            voiceRecorder?.stop()
            voicePlayer?.stop()
            isRecordingVoice = false
            isPlayingRecordedVoice = false
        } catch {
            print(error)
            isPlayingRecordedVoice = false
        }
    }
    
    func stopCurrentVoice(soundName: String) {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlayingRecordedVoice = false
        isRecordingVoice = false
    }
}

// MARK: - LearningViewController Delegate and DataSource Methods
extension LearningViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searching {
            return searchingDataList.count
        } else {
            return phraseList.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if playing == true {
            playing = false
        }
        
        if searching {
            if selectedIndex == indexPath.row {
                let cell = tableView.dequeueReusableCell(withIdentifier: FullPhraseTableViewCell.identifier, for: indexPath) as! FullPhraseTableViewCell
                
                cell.markOutlet.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(updateBookmarkOutlet(_:))))
                
                cell.recordBtn.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(recordOurVoice(_:))))
                
                cell.playBtn.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(playOurVoice(_:))))
                
                cell.playSystemSoundBtn.addGestureRecognizer(UIGestureRecognizer(target: self, action: #selector(playSystemSound(_:))))
                
                cell.playSlowlySystemSoundBtn.addGestureRecognizer(UIGestureRecognizer(target: self, action: #selector(playSlowlySystemSound(_:))))
                
                cell.playBtn.isEnabled = false
                
                if didRecord {
                    cell.playBtn.isEnabled = true
                }
                
                cell.vietnameseLabel.text = searchingDataList[indexPath.item].vietnamesePhrases
                cell.chineseLabel.text = searchingDataList[indexPath.item].chinesePhrases
                cell.pinyinLabel.text = searchingDataList[indexPath.item].pinyin
                
                if searchingDataList[indexPath.item].favorite == 0 {
                    cell.markOutlet.setImage(UIImage(named: "graystar"), for: .normal)
                } else {
                    cell.markOutlet.setImage(UIImage(named: "pinkstar"), for: .normal)
                }
                
                selectedIndex = -1
                
                cell.selectionStyle = .none
                
                return cell
            }
            
            // Show Vietnamese phrase cell
            let cell = tableView.dequeueReusableCell(withIdentifier: VietnameseTableViewCell.identifier, for: indexPath) as! VietnameseTableViewCell
            cell.markOutlet.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(updateBookmarkOutlet(_:))))
            cell.vietnameseLabel?.text = searchingDataList[indexPath.item].vietnamesePhrases
            
            if searchingDataList[indexPath.item].favorite == 0 {
                cell.markOutlet.setImage(UIImage(named: "graystar"), for: .normal)
            } else {
                cell.markOutlet.setImage(UIImage(named: "pinkstar"), for: .normal)
            }
            
            cell.selectionStyle = .none
            
            return cell
        } else {
            if selectedIndex == indexPath.row {
                let cell = tableView.dequeueReusableCell(withIdentifier: FullPhraseTableViewCell.identifier, for: indexPath) as! FullPhraseTableViewCell
                
                cell.markOutlet.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(updateBookmarkOutlet(_:))))
                
                cell.recordBtn.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(recordOurVoice(_:))))
                
                cell.playBtn.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(playOurVoice(_:))))
                
                cell.playSystemSoundBtn.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(playSystemSound(_:))))
                
                cell.playSlowlySystemSoundBtn.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(playSlowlySystemSound(_:))))
                
                cell.playBtn.isEnabled = false
                
                if didRecord {
                    cell.playBtn.isEnabled = true
                }
                
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
                
                cell.selectionStyle = .none
                
                return cell
            }
            
            // Show Vietnamese phrase cell
            let cell = tableView.dequeueReusableCell(withIdentifier: VietnameseTableViewCell.identifier, for: indexPath) as! VietnameseTableViewCell
            cell.markOutlet.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(updateBookmarkOutlet(_:))))
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
    }
    
    // MARK: - Button Recognizer
    @objc func updateBookmarkOutlet(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: self.tableView)
        let indexPath = self.tableView.indexPathForRow(at: location)
        
        if searching {
            let phraseId = searchingDataList[indexPath!.row].id
            let favoriteStatus = searchingDataList[indexPath!.row].favorite
            
            PhraseService.shared.updateFavoriteData(phraseId: phraseId, favoriteStatus: favoriteStatus)
            
        } else {
            let phraseId = phraseList[indexPath!.row].id
            let favoriteStatus = phraseList[indexPath!.row].favorite
            
            PhraseService.shared.updateFavoriteData(phraseId: phraseId, favoriteStatus: favoriteStatus)
        }
        
        getData()
        tableView.reloadData()
    }
    
    @objc func recordOurVoice(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: self.tableView)
        let indexPath = self.tableView.indexPathForRow(at: location)
        
        let cell = self.tableView.cellForRow(at: indexPath!) as! FullPhraseTableViewCell
        
        cell.playBtn.isEnabled = true
        
        audioPlayer?.stop()
        
        if isPlayingRecordedVoice {
            print("Wait for playing recorded voice!")
            showToast(message: "Wait for playing recorded voice!")
        } else {
            if isRecordingVoice {
                voiceRecorder?.stop()
                isRecordingVoice = false
                showToast(message: "Stopped recording your voice!")
                print("Stop recording my voice!")
                
            } else {
                voiceRecorder?.record()
                isRecordingVoice = true
                showToast(message: "Recording your voice!")
                print("Recording my voice!")
            }
        }
        didRecord = true
    }
    
    @objc func playOurVoice(_ sender: UITapGestureRecognizer) {
        audioPlayer?.stop()
                
        if voiceRecorder == nil {
            print("No record!")
            isPlayingRecordedVoice = false
        } else {
            if isRecordingVoice {
                print("Wait for recording my voice!")
                showToast(message: "Wait for recording your voice!")
            } else {
                if isPlayingRecordedVoice {
                    voicePlayer?.delegate = self
                    voicePlayer?.stop()
                    isPlayingRecordedVoice = false
                    print("Stop playing my voice!")
                } else {
                    setupPlayer()
                    voicePlayer?.play()
                    isPlayingRecordedVoice = true
                    audioPlayer?.delegate = self
                    print("Playing my voice!")
                }
            }
        }
    }
    
    @objc func playSystemSound(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: self.tableView)
        let indexPath = self.tableView.indexPathForRow(at: location)
        
        audioPlayer?.stop()
        playing = false
        
        isPlayingRecordedVoice = false
        isRecordingVoice = false
        
        voicePlayer = nil
        
        if searching {
            if playing == false {
                playCurrentVoice(soundName: searchingDataList[indexPath!.row].voice, rate: 1.0)
                playing = true
            } else {
                playing = false
                stopCurrentVoice(soundName: searchingDataList[indexPath!.row].voice)
            }
        } else {
            if playing == false {
                playCurrentVoice(soundName: phraseList[indexPath!.row].voice, rate: 1.0)
                playing = true
            } else {
                playing = false
                stopCurrentVoice(soundName: phraseList[indexPath!.row].voice)
            }
        }
    }
    
    @objc func playSlowlySystemSound(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: self.tableView)
        let indexPath = self.tableView.indexPathForRow(at: location)
        
        audioPlayer?.stop()
        playing = false
        
        isPlayingRecordedVoice = false
        isRecordingVoice = false
        
        voicePlayer = nil
        
        if searching {
            if playing == false {
                playCurrentVoice(soundName: searchingDataList[indexPath!.row].voice, rate: 0.7)
                playing = true
            } else {
                playing = false
                stopCurrentVoice(soundName: searchingDataList[indexPath!.row].voice)
            }
        } else {
            if playing == false {
                playCurrentVoice(soundName: phraseList[indexPath!.row].voice, rate: 0.7)
                playing = true
            } else {
                playing = false
                stopCurrentVoice(soundName: phraseList[indexPath!.row].voice)
            }
        }
        audioPlayer?.delegate = self
    }
}

extension LearningViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if didRecord == true {
            didRecord = false
        }
        
        if playing {
            audioPlayer?.stop()
            playing = false
        }
        
        if searching {
            if playing == false {
                playCurrentVoice(soundName: searchingDataList[indexPath.row].voice, rate: 1.0)
                playing = !playing
            }
        } else {
            if playing == false {
                playCurrentVoice(soundName: phraseList[indexPath.row].voice, rate: 1.0)
                playing = !playing
            }
        }
        
        playerOutlet.setImage(UIImage(named: "stopbtn"), for: .normal)
        
        selectedIndex = indexPath.row
        tableView.reloadData()
    }
}

// MARK: - SearchBar Delegate Methods
extension LearningViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let textFieldInsideSearchBar = searchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideSearchBar?.textColor = .white
        
        searchingDataList = phraseList.filter({ (userData: PhraseModel) -> Bool in
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
        audioPlayer?.stop()
        playing = false
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searching = true
        searchBar.endEditing(true)
        self.tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        audioPlayer?.stop()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        searchBar.endEditing(true)
    }
}

// MARK: - AudioPlayer Delegate Methods
extension LearningViewController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playing = false
        player.stop()
        playerOutlet.setImage(UIImage(named: "playbtn"), for: .normal)
        audioPlayer?.stop()
        voicePlayer?.stop()
        isPlayingRecordedVoice = false
        
        if playingAllVoices {
            let indexPath = IndexPath(row: playItem, section: 0)
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .bottom)
            tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPath)
            playItem += 1
        }
    }
}

extension LearningViewController: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        voiceRecorder?.stop()
        isRecordingVoice = false
    }
}

extension LearningViewController {
    func showToast(message: String) {
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width / 2 - 50, y: self.view.frame.size.height - 100, width: self.view.frame.width / 2, height: 50))
        
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        toastLabel.textColor = UIColor.white
        toastLabel.font = .systemFont(ofSize: 16.0)
        toastLabel.textAlignment = .center;
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 5;
        toastLabel.clipsToBounds  =  true
        
        self.view.addSubview(toastLabel)
        
        UIView.animate(withDuration: 3.0, delay: 0, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
}
