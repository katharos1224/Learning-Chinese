//
//  HomeViewController.swift
//  HocTiengTrung
//
//  Created by Katharos on 14/01/2023.
//

import UIKit
import AVFAudio

class HomeViewController: UIViewController {
    
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var startOutlet: UIButton!
    @IBOutlet var searchOutlet: UIButton!
    @IBOutlet var favoriteOutlet: UIButton!
    @IBOutlet var searchResultTableView: UITableView!
    @IBOutlet var welcomeOutlet: UIStackView!
    @IBOutlet var backOutlet: UIButton!
    
    @IBAction func backButton(_ sender: UIButton) {
        searchBar.endEditing(true)
        backOutlet.isHidden = true
        searchBar.isHidden = true
        backOutlet.isHidden = true
        searchResultTableView.isHidden = true
        searchOutlet.isHidden = false
        startOutlet.isHidden = false
        favoriteOutlet.isHidden = false
        welcomeOutlet.isHidden = false
        searchBar.text = ""
        searchingDataList.removeAll()
        searchResultTableView.reloadData()
        
        audioPlayer?.delegate = self
        audioPlayer?.stop()
    }
    
    @IBAction func goToSearchButton(_ sender: UIButton) {
        searchBar.becomeFirstResponder()
        searchBar.isHidden = false
        backOutlet.isHidden = false
        searchResultTableView.isHidden = false
        searchOutlet.isHidden = true
        startOutlet.isHidden = true
        favoriteOutlet.isHidden = true
        welcomeOutlet.isHidden = true
    }
    
    @IBAction func startButton(_ sender: UIButton) {
        let vc = storyboard?.instantiateViewController(withIdentifier: CategoryViewController.identifier) as! CategoryViewController
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: false)
    }
    
    @IBAction func goToFavoriteButton(_ sender: UIButton) {
        let vc = storyboard?.instantiateViewController(withIdentifier: BookmarkViewController.identifier) as! BookmarkViewController
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: false)
    }
    
    static let identifier = "HomeViewController"
    
    var playingAllVoices = false
    var playing = false
    var favorite = false
    var searching = false
    var isRecordingVoice = false
    var isPlayingRecordedVoice = false
    var didRecord = false
    
    var phraseList: [PhraseModel] = [PhraseModel]()
    var searchingDataList: [PhraseModel] = [PhraseModel]()
    
    var selectedIndex = -1
    
    var audioPlayer: AVAudioPlayer?
    
    var voiceRecorder: AVAudioRecorder?
    var voicePlayer: AVAudioPlayer?
    
    var fileName: String = "sound.m4a"
        
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.layer.cornerRadius = 14
        startOutlet.layer.cornerRadius = 10
        favoriteOutlet.layer.cornerRadius = 10
        searchOutlet.layer.cornerRadius = 10
        searchBar.isHidden = true
        backOutlet.isHidden = true
        searchResultTableView.backgroundColor = .clear
        searchResultTableView.isHidden = true
        
        searchResultTableView.register(VietnameseTableViewCell.nib(), forCellReuseIdentifier: VietnameseTableViewCell.identifier)
        searchResultTableView.register(FullPhraseTableViewCell.nib(), forCellReuseIdentifier: FullPhraseTableViewCell.identifier)
        searchResultTableView.delegate = self
        searchResultTableView.dataSource = self
        searchResultTableView.showsHorizontalScrollIndicator = false
        searchResultTableView.showsVerticalScrollIndicator = false
        
        searchBar.delegate = self
        
        audioPlayer?.delegate = self
        voiceRecorder?.delegate = self
        voicePlayer?.delegate = self
        
        setupRecorder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getData()
        searchResultTableView.reloadData()
        
        isPlayingRecordedVoice = false
        playing = false
        isRecordingVoice = false
    }
        
    func getData() {
        phraseList = PhraseService.shared.getData()
        for item in searchingDataList {
            for item2 in phraseList {
                if item.id == item2.id {
                    item.favorite = item2.favorite
                }
            }
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
}

// MARK: - HomeViewController Delegate and DataSource Methods
extension HomeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searching {
            return searchingDataList.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if playing == true {
            playing = false
        }
        
        if searching {
            if selectedIndex == indexPath.row {
                let cell = searchResultTableView.dequeueReusableCell(withIdentifier: FullPhraseTableViewCell.identifier, for: indexPath) as! FullPhraseTableViewCell
                
                cell.markOutlet.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(updateBookmarkOutlet(_:))))
                
                cell.recordBtn.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(recordOurVoice(_:))))
                
                cell.playBtn.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(playOurVoice(_:))))
                
                cell.playSystemSoundBtn.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(playSystemSound(_:))))
                
                cell.playSlowlySystemSoundBtn.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(playSlowlySystemSound(_:))))
                
                cell.playBtn.isEnabled = false
                
                if didRecord {
                    cell.playBtn.isEnabled = true
                }
                
                if searchingDataList[indexPath.item].favorite == 0 {
                    cell.markOutlet.setImage(UIImage(named: "graystar"), for: .normal)
                } else {
                    cell.markOutlet.setImage(UIImage(named: "pinkstar"), for: .normal)
                }
                
                cell.vietnameseLabel.text = searchingDataList[indexPath.item].vietnamesePhrases
                cell.chineseLabel.text = searchingDataList[indexPath.item].chinesePhrases
                cell.pinyinLabel.text = searchingDataList[indexPath.item].pinyin
                
                selectedIndex = -1
                
                cell.selectionStyle = .none
                return cell
            }
            
            let cell = searchResultTableView.dequeueReusableCell(withIdentifier: VietnameseTableViewCell.identifier, for: indexPath) as! VietnameseTableViewCell
            cell.markOutlet.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(updateBookmarkOutlet(_:))))
            cell.vietnameseLabel?.text = searchingDataList[indexPath.item].vietnamesePhrases

            if searchingDataList[indexPath.item].favorite == 0 {
                cell.markOutlet.setImage(UIImage(named: "graystar"), for: .normal)
            } else {
                cell.markOutlet.setImage(UIImage(named: "pinkstar"), for: .normal)
            }
            
            cell.selectionStyle = .none
            return cell
        }
        
        let cell = searchResultTableView.dequeueReusableCell(withIdentifier: VietnameseTableViewCell.identifier, for: indexPath) as! VietnameseTableViewCell
        return cell
    }
    
    // MARK: - Button Recognizer
    @objc func updateBookmarkOutlet(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: self.searchResultTableView)
        let indexPath = self.searchResultTableView.indexPathForRow(at: location)
        
        let phraseId = searchingDataList[indexPath!.row].id
        let favoriteStatus = searchingDataList[indexPath!.row].favorite
        
        PhraseService.shared.updateFavoriteData(phraseId: phraseId, favoriteStatus: favoriteStatus)
        getData()
        searchResultTableView.reloadData()
    }
    
    @objc func recordOurVoice(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: self.searchResultTableView)
        let indexPath = self.searchResultTableView.indexPathForRow(at: location)
        
        let cell = self.searchResultTableView.cellForRow(at: indexPath!) as! FullPhraseTableViewCell
        
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
        let location = sender.location(in: self.searchResultTableView)
        let indexPath = self.searchResultTableView.indexPathForRow(at: location)
        
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
        let location = sender.location(in: self.searchResultTableView)
        let indexPath = self.searchResultTableView.indexPathForRow(at: location)
        
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

extension HomeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if didRecord == true {
            didRecord = false
        }
        
        if playing {
            audioPlayer?.stop()
            playing = false
        }
        
        if searching {
            print(didRecord)
            if playing == false {
                playCurrentVoice(soundName: searchingDataList[indexPath.row].voice, rate: 1.0)
                playing = !playing
            }
            
            if selectedIndex == indexPath.row {
                let cell = self.searchResultTableView.cellForRow(at: indexPath) as! FullPhraseTableViewCell
                
                
                if didRecord == false {
                    cell.playBtn.isEnabled = false
                } else {
                    cell.playBtn.isEnabled = true
                }
                
                fileName = "\(indexPath.row).m4a"
                setupRecorder()
                setupPlayer()
            }
        } else {
            if playing == false {
                playCurrentVoice(soundName: phraseList[indexPath.row].voice, rate: 1.0)
                playing = !playing
            }
        }
                
        selectedIndex = indexPath.row
        tableView.reloadData()
    }
}

// MARK: - SearchBar Delegate Methods
extension HomeViewController: UISearchBarDelegate {
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
        } else {
            searching = false
        }
        
        searchResultTableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searching = true
        searchBar.endEditing(true)
        self.searchResultTableView.reloadData()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        searchBar.endEditing(true)
    }
}

// MARK: - AudioPlayer Delegate Methods
extension HomeViewController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playing = false
        player.stop()
        
        voicePlayer?.stop()
        isPlayingRecordedVoice = false
        print("Stop playing my voice!")
    }
}

extension HomeViewController: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        voiceRecorder?.stop()
        isRecordingVoice = false
    }
}

extension HomeViewController {
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
