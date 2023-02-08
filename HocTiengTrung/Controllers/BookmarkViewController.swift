//
//  BookmarkViewController.swift
//  HocTiengTrung
//
//  Created by Katharos on 07/01/2023.
//

import UIKit
import AVFAudio

class BookmarkViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var markOutlet: UIButton!
    
    @IBAction func markButton(_ sender: UIButton) {
        if searching {
            audioPlayer?.stop()
        }
        
        if bookmarkList.count != 0 {
            let count = bookmarkList.count
            
            for item in stride(from: count - 1, through: 0, by: -1) {
                bookmarkList.remove(at: item)
                tableView.deleteRows(at: [IndexPath(row: item, section: 0)], with: .left)
            }
            
            PhraseService.shared.resetFavoriteData()
            
            audioPlayer?.stop()
        }
        
        if bookmarkList.count == 0 {
            markOutlet.alpha = 0.5
            markOutlet.setImage(UIImage(named: "grayheart"), for: .normal)
        } else {
            markOutlet.alpha = 1.0
            markOutlet.setImage(UIImage(named: "pinkheart"), for: .normal)
        }
        
        tableView.reloadData()
        audioPlayer?.delegate = self
    }
    
    @IBAction func backToCategoryButton(_ sender: UIButton) {
        dismiss(animated: false)
    }
    
    @IBOutlet var searchBar: UISearchBar!
    
    static let identifier = "BookmarkViewController"
    
    var bookmarkList = [PhraseModel]()
    var searchingDataList = [PhraseModel]()
    
    var searching = false
    var deleting = false
    var favorite = false
    var playing = false
    var isPlayingRecordedVoice = false
    var isRecordingVoice = false
    var didRecord = false
    
    var audioPlayer: AVAudioPlayer?
    var voiceRecorder: AVAudioRecorder?
    var voicePlayer: AVAudioPlayer?
    
    var selectedIndex = -1
    var fileName = "sound.m4a"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(VietnameseTableViewCell.nib(), forCellReuseIdentifier: VietnameseTableViewCell.identifier)
        tableView.register(FullPhraseTableViewCell.nib(), forCellReuseIdentifier: FullPhraseTableViewCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.backgroundColor = .clear
        searchBar.layer.cornerRadius = 14
        
        audioPlayer?.delegate = self
        voicePlayer?.delegate = self
        voiceRecorder?.delegate = self
                
        setupRecorder()
        
        getData()
        
        tableView.showsHorizontalScrollIndicator = false
        tableView.showsVerticalScrollIndicator = false
        
        if bookmarkList.count == 0 {
            markOutlet.alpha = 0.5
            markOutlet.setImage(UIImage(named: "grayheart"), for: .normal)
        } else {
            markOutlet.alpha = 1.0
            markOutlet.setImage(UIImage(named: "pinkheart"), for: .normal)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getData()
        tableView.reloadData()
        
        isPlayingRecordedVoice = false
        playing = false
        isRecordingVoice = false
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
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.enableRate = true
            audioPlayer?.rate = rate
            audioPlayer?.play()
            
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
    
    func getData() {
        bookmarkList = PhraseService.shared.getFavouriteData()
    }
}

// MARK: - LearningViewController Delegate and DataSource Methods
extension BookmarkViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searching {
            return searchingDataList.count
        }
        return bookmarkList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Show full phrase cell
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
                
                if didRecord {
                    cell.playBtn.isEnabled = true
                }
                
                cell.vietnameseLabel.text = searchingDataList[indexPath.item].vietnamesePhrases
                cell.chineseLabel.text = searchingDataList[indexPath.item].chinesePhrases
                cell.pinyinLabel.text = searchingDataList[indexPath.item].pinyin
                
                if searchingDataList[indexPath.item].favorite == 1 {
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
            cell.vietnameseLabel?.text = searchingDataList[indexPath.item].vietnamesePhrases
            
            if searchingDataList[indexPath.item].favorite == 1 {
                cell.markOutlet.setImage(UIImage(named: "pinkstar"), for: .normal)
            }
            else {
                cell.markOutlet.setImage(UIImage(named: "graystar"), for: .normal)
            }
            
            cell.selectionStyle = .none
            
            return cell
        } else {
            if selectedIndex == indexPath.row {
                let cell = tableView.dequeueReusableCell(withIdentifier: FullPhraseTableViewCell.identifier, for: indexPath) as! FullPhraseTableViewCell
                cell.markOutlet.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(updateBookmarkOutlet(_:))))
                
                cell.recordBtn.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(recordOurVoice(_:))))
                
                cell.playBtn.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(playOurVoice(_:))))
                
                cell.playSystemSoundBtn.addGestureRecognizer(UIGestureRecognizer(target: self, action: #selector(playSystemSound(_:))))
                
                cell.playSlowlySystemSoundBtn.addGestureRecognizer(UIGestureRecognizer(target: self, action: #selector(playSlowlySystemSound(_:))))
                
                if didRecord {
                    cell.playBtn.isEnabled = true
                }
                
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
                                
                cell.selectionStyle = .none
                
                return cell
            }
            
            // Show Vietnamese phrase cell
            let cell = tableView.dequeueReusableCell(withIdentifier: VietnameseTableViewCell.identifier, for: indexPath) as! VietnameseTableViewCell
            cell.markOutlet.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(updateBookmarkOutlet(_:))))
            cell.vietnameseLabel.text = bookmarkList[indexPath.item].vietnamesePhrases
            
            if bookmarkList[indexPath.item].favorite == 1 {
                cell.vietnameseLabel?.text = bookmarkList[indexPath.item].vietnamesePhrases
                cell.markOutlet.setImage(UIImage(named: "pinkstar"), for: .normal)
            }
            else {
                cell.vietnameseLabel?.text = bookmarkList[indexPath.item].vietnamesePhrases
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
            
            // Update favoriteStatus by selected phraseId
            searchingDataList.remove(at: indexPath!.row)
            tableView.deleteRows(at: [IndexPath(row: indexPath!.row, section: 0)], with: .top)
            PhraseService.shared.updateFavoriteData(phraseId: phraseId, favoriteStatus: favoriteStatus)
            getData()
            tableView.reloadData()
            
            if bookmarkList.count == 0 {
                markOutlet.alpha = 0.5
                markOutlet.setImage(UIImage(named: "grayheart"), for: .normal)
            } else {
                markOutlet.alpha = 1.0
                markOutlet.setImage(UIImage(named: "pinkheart"), for: .normal)
            }
        } else {
            let phraseId = bookmarkList[indexPath!.row].id
            let favoriteStatus = bookmarkList[indexPath!.row].favorite
            
            // Update favoriteStatus by selected phraseId
            bookmarkList.remove(at: indexPath!.row)
            tableView.deleteRows(at: [IndexPath(row: indexPath!.row, section: 0)], with: .left)
            PhraseService.shared.updateFavoriteData(phraseId: phraseId, favoriteStatus: favoriteStatus)
            getData()
            tableView.reloadData()
            
            if bookmarkList.count == 0 {
                markOutlet.alpha = 0.5
                markOutlet.setImage(UIImage(named: "grayheart"), for: .normal)
            } else {
                markOutlet.alpha = 1.0
                markOutlet.setImage(UIImage(named: "pinkheart"), for: .normal)
            }
        }
    }
    
    @objc func recordOurVoice(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: self.tableView)
        let indexPath = self.tableView.indexPathForRow(at: location)
        
        let cell = tableView.dequeueReusableCell(withIdentifier: FullPhraseTableViewCell.identifier, for: indexPath!) as! FullPhraseTableViewCell
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
        cell.playBtn.isEnabled = true
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
        
        if playing {
            audioPlayer?.stop()
            playing = false
        }
        
        isPlayingRecordedVoice = false
        isRecordingVoice = false
        
        voicePlayer = nil
        
        if searching {
            if playing == false {
                playCurrentVoice(soundName: searchingDataList[indexPath!.row].voice, rate: 1.0)
                playing = !playing
            } else {
                playing = !playing
                stopCurrentVoice(soundName: searchingDataList[indexPath!.row].voice)
            }
        } else {
            if playing == false {
                playCurrentVoice(soundName: bookmarkList[indexPath!.row].voice, rate: 1.0)
                playing = !playing
            } else {
                playing = !playing
                stopCurrentVoice(soundName: bookmarkList[indexPath!.row].voice)
            }
        }
    }
    
    @objc func playSlowlySystemSound(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: self.tableView)
        let indexPath = self.tableView.indexPathForRow(at: location)
        
        if playing {
            audioPlayer?.stop()
            playing = false
        }
        
        isPlayingRecordedVoice = false
        isRecordingVoice = false
        
        voicePlayer = nil
        
        if searching {
            if playing == false {
                playCurrentVoice(soundName: searchingDataList[indexPath!.row].voice, rate: 0.7)
                playing = !playing
            } else {
                playing = !playing
                stopCurrentVoice(soundName: searchingDataList[indexPath!.row].voice)
            }
        } else {
            if playing == false {
                playCurrentVoice(soundName: bookmarkList[indexPath!.row].voice, rate: 0.7)
                playing = !playing
            } else {
                playing = !playing
                stopCurrentVoice(soundName: bookmarkList[indexPath!.row].voice)
            }
        }
        
    }
}

extension BookmarkViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
                playCurrentVoice(soundName: bookmarkList[indexPath.row].voice, rate: 1.0)
                playing = !playing
            }
        }
        
        searchBar.endEditing(true)
        selectedIndex = indexPath.row
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
        audioPlayer?.delegate = self
        audioPlayer?.stop()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searching = true
        searchBar.endEditing(true)
        self.tableView.reloadData()
        audioPlayer?.delegate = self
        audioPlayer?.stop()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        searchBar.endEditing(true)
    }
}

// MARK: - AudioPlayer Delegate Methods
extension BookmarkViewController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playing = false
        player.stop()
        
        voicePlayer?.stop()
        isPlayingRecordedVoice = false
        print("Stop playing my voice!")
    }
}

extension BookmarkViewController: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        voiceRecorder?.stop()
        isRecordingVoice = false
    }
}

extension BookmarkViewController {
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
