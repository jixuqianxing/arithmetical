//
//  SettingsViewController.swift
//  arithmetical
//
//  Created by Pedro Sandoval Segura on 8/4/16.
//  Copyright © 2016 Sandoval Software. All rights reserved.
//

import UIKit
import SafariServices

class SettingsViewController: UIViewController, SPTAudioStreamingDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var safariVC: SFSafariViewController?

    @IBOutlet weak var picker: UIPickerView!
    @IBOutlet weak var spotifySwitch: UISwitch!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Settings"
        
        self.picker.delegate = self
        self.picker.dataSource = self
        
        // Update spotify switch
        self.spotifySwitch.isOn = Games.spotifyActivated ? true: false
        
        //Update picker view
        if Games.selectedPlaylist != nil {
            self.picker.selectRow(Games.selectedPlaylistRow!, inComponent: 0, animated: true)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(loginSuccess), name: NSNotification.Name(rawValue: "closeSafariOnLogin"), object: nil)
    }
    

    @IBAction func onSpotifySwitch(_ sender: UISwitch) {
        if sender.isOn == false {
            Games.spotifyActivated = false
            Games.loadedPlaylists = nil
        } else {
            // TODO: Check if the access token is still valid to prevent Safari VC popup
            
            let requestedScopes = [SPTAuthStreamingScope, SPTAuthPlaylistReadPrivateScope, SPTAuthPlaylistModifyPrivateScope, SPTAuthUserLibraryReadScope, SPTAuthUserLibraryModifyScope, SPTAuthUserReadPrivateScope, SPTAuthUserReadTopScope, SPTAuthUserReadEmailScope]
            
            let loginUrl: NSURL = SPTAuth.loginURL(forClientId: SpotifyClient.CLIENT_ID, withRedirectURL: NSURL(string: SpotifyClient.CALLBACK_URL) as URL!, scopes: requestedScopes, responseType: "token") as NSURL
            
            //Open login with SafariViewController
            self.safariVC = SFSafariViewController(url: loginUrl as URL)
            self.present(self.safariVC!, animated: true, completion: nil)
        }
    }
    
    func loginSuccess() {
        self.safariVC?.dismiss(animated: true, completion: nil)
        self.activityIndicator.startAnimating()
        startStreamingController()
        loginToStreamingController()
        
        //Load user playlists for selection
        SpotifyClient.getCurrentUserPlaylists { (playlists) in
            Games.loadedPlaylists = playlists
            Games.selectedPlaylistRow = 0       //Default picker controller value
            self.picker.reloadAllComponents()
        }
    }
    
    func startStreamingController() {
        do {
            try SPTAudioStreamingController.sharedInstance().start(withClientId: SpotifyClient.CLIENT_ID)
            SPTAudioStreamingController.sharedInstance().delegate = self
        } catch is NSError {
            print("Error: Unable to start SPTAudioStreamingController")
        }
    }
    
    func loginToStreamingController() {
        SPTAudioStreamingController.sharedInstance().diskCache = SPTDiskCache(capacity: 1024 * 1024 * 64)
        SPTAudioStreamingController.sharedInstance().login(withAccessToken: SPTAuth.defaultInstance().session.accessToken)
    }
    
    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        //print("SPTAudioStreamingController logged in!")
        if SPTAudioStreamingController.sharedInstance().loggedIn {
            Games.spotifyActivated = true
            self.activityIndicator.stopAnimating()
        }
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didReceiveError error: Error!) {
        let alert = UIAlertController(title: "Oh no!", message: "An error occurred. Please verify you have a Spotify Premium Subscription.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: { (action) in
            self.activityIndicator.stopAnimating()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1 //One  column of selectable data
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if Games.loadedPlaylists != nil {
            return (Games.loadedPlaylists?.count)!
        }
        
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        //Number of rows in component should be greater than 0?
        return Games.loadedPlaylists?[row].name!
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        //Set selected playlist
        if Games.loadedPlaylists != nil {
            Games.selectedPlaylist = Games.loadedPlaylists?[row]
            Games.selectedPlaylistRow = row
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
