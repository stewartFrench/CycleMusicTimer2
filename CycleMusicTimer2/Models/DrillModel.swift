//
//  DrillModel.swift
//  CycleMusicTimer2
//
//  Created by Stewart French on 5/9/23.
//

import Foundation

//--------------------------------------------
// The DrillModel() class defines how to map a drill to a specific
// track and the methods needed to support creating, reading, and
// writing this data.
// 
// It defines the contents stored in the filesystem as a Property
// List.  It is carefully constructed to be backward compatible with
// the app Cycle Music Timer so that existing users of CMT can import
// their drills here and have them correctly visible.
//--------------------------------------------


//--------------------------------------------
class DrillModel
{
            // All the important drill mapping data are strings so
            // they can be easily read and written as a Property
            // List.

            // in Swift the ideal representation is a struct for the
            // Drills info.  However, to be backward compatible I must
            // make the data appear as a dictionary of arrays.  Each
            // array will contain a single occurence of drill data.

            // In Objective-C it looked like this -
            //
            //     NSMutableArray *tValues =
            //      [NSMutableArray
            //        arrayWithObjects:
            //          tArtistName,             // index 0
            //          tTrackName,              // index 1
            //          drillNotes,              // index 2
            //          tPlaylistTitle,          // index 3
            //          tThisPlaylistOnly,       // index 4  - YES or NO
            //          nil];
            //
            // In Swift it would have looked like this -
            //
            //  struct DrillStruct : Codable
            //  {
            //    var playlistTitle : String = ""
            //    var artistName : String = ""
            //    var trackName : String = ""
            //    var drillNotes : String = ""
            //    var thisPlaylistOnly : String = "false"
            //  }
            //
            // Each track may have a drill note associated with it.
            // If so then this dictionary will contain the mapping of
            // a Key to the NSString drill notes.  The Key is formed
            // from the artistName string and the trackName string.

  var drillsDictionary : [ String : [String] ] = Dictionary()

            // The filename where the DrillStruct dictionary property
            // list will be stored

  var filePath : String = "CycleMusicTimerDrills.cmt"

  var fileURL : URL

  //-----------------------------------------------------------
  init()
  {
    let manager = FileManager.default

    let url = manager.urls(
                  for: .documentDirectory, 
                   in: .userDomainMask).first
    fileURL = 
    url!.appendingPathComponent(
          filePath )

    readDrillsFromFilesystem()

  } // init



  //-----------------------------------------------------------
  func CreateDrill(
       playlistTitle playlistTitleP    : String,
          artistName artistNameP       : String,
           trackName trackNameP        : String,
          drillNotes drillNotesP       : String,
    thisPlaylistOnly thisPlaylistOnlyP : Bool = false )
  {
    var tKey : String = ""

    let tDrill = 
      [
         artistNameP,
         trackNameP,
         drillNotesP,
         playlistTitleP,
         thisPlaylistOnlyP ? "YES" : "NO" ]
      
    if thisPlaylistOnlyP
    {
      tKey = 
          formDrillKeyWithPlaylist(
                   artistName : artistNameP,
                    trackName : trackNameP,
                playlistTitle : playlistTitleP )

    }
    else
    {
      tKey = 
          formDrillKey(
                   artistName : artistNameP,
                    trackName : trackNameP )

            // I create a new drill that is not unique to this
            // playlist.  Therefore I need to remove any playlist
            // specific drill.

      removePlaylistSpecificDrill(
                   artistName : artistNameP,
                    trackName : trackNameP,
                playlistTitle : playlistTitleP )
    }

            // If the user has passed a completely empty drill in, no
            // matter the playlist, lets remove the entry entirely
            // from the dictionary.

    if drillNotesP == ""
    {
      drillsDictionary.removeValue( forKey: tKey )
    }
    else
    {
      drillsDictionary[ tKey ] = tDrill
    }

    saveDrillsToFilesystem()

  } // CreateDrill


  //-----------------------------------------------------------
  func formDrillKey(
          artistName artistNameP  : String,
           trackName trackNameP   : String ) -> String
  {
    let keyString = artistNameP + "|+|" + trackNameP

    return keyString

  } // formDrillKey

  //-----------------------------------------------------------
  func formDrillKeyWithPlaylist(
               artistName artistNameP    : String,
                trackName trackNameP     : String,
            playlistTitle playlistTitleP : String ) -> String
  {
    var keyString = artistNameP + "|+|" + trackNameP
    keyString = keyString + "|+|" + playlistTitleP

    return keyString
    
  } // formDrillKey

  //-----------------------------------------------------------
  func getDrill(
      playlistTitle playlistTitleP : String,
         artistName artistNameP    : String,
          trackName trackNameP     : String ) -> String?
  {
            // If there is a drill associated with this
            // artist/track/playlist then return it.
            //
            // Otherwise, check if there is a drill associated with
            // the artist/track (no playlist).  If so, return it.
            //
            // Otherwise return nil.

    let tKeyPL = 
        formDrillKeyWithPlaylist(
                artistName : artistNameP,
                 trackName : trackNameP,
             playlistTitle : playlistTitleP )

    if let tDrillPL = self.drillsDictionary[ tKeyPL ]
    {
      return tDrillPL[ 2 ]
    }

    let tKey = 
        formDrillKey(
                artistName : artistNameP,
                 trackName : trackNameP )

    if let tDrill = self.drillsDictionary[ tKey ]
    {
      return tDrill[ 2 ]
    }

    return nil

  } // getDrill


  //-----------------------------------------------------------
  func drillIsForPlaylist(
     playlistTitle playlistTitleP : String,
        artistName artistNameP    : String,
         trackName trackNameP     : String ) -> Bool
  {

            // If there is a drill that is specific to this playlist
            // then return true, else return false.

    let tKeyPL = 
        formDrillKeyWithPlaylist(
                artistName : artistNameP,
                 trackName : trackNameP,
             playlistTitle : playlistTitleP )

    if self.drillsDictionary[ tKeyPL ] != nil
    {
      return true
    }
    else
    {
      return false
    }

  } // drillIsForPlaylist


  //-----------------------------------------------------------
  func removePlaylistSpecificDrill(
        artistName artistNameP    : String,
         trackName trackNameP     : String,
     playlistTitle playlistTitleP : String )
  {
            // Remove drill that is unique for the track in
            // the playlist.
    let tKey = 
        formDrillKeyWithPlaylist(
                 artistName : artistNameP,
                  trackName : trackNameP,
              playlistTitle : playlistTitleP )
        
    drillsDictionary.removeValue( forKey: tKey )

  } // unsetDrillIsForPlaylist


  //-----------------------------------------------------------
  func readDrillsFromFilesystem()
  {
            // Read the drills dictionary from the filesystem.

    let decoder = PropertyListDecoder()
 
    if let data = try? Data( contentsOf: fileURL ),
        let td : [String: [String]] = try? decoder.decode( 
                    [ String: [String] ].self, 
                       from: data )
    {
      drillsDictionary = td
      saveDrillsToFilesystem()
    }
  } // readDrillsFromFilesystem



  //-----------------------------------------------------------
  func readDrillsFromURL( url urlP : URL )
  {
            // Read the drills dictionary from a specified URL.
            // This can occur if as part of a share operation when the
            // app is firtst started.
            //
            //   See -  ".onOpenURL"

    let decoder = PropertyListDecoder()
 
    if let data = try? Data( contentsOf: urlP ),
       let td = try? decoder.decode( 
                    [ String: [String] ].self, 
                       from: data )
    {

            // There could be drills already in the dictionary that
            // were read in when the app started (as part of a sharing
            // scenario).
            
      drillsDictionary.merge( td )
      { ( _, new ) in
        new
      }
      saveDrillsToFilesystem()
    }
  } // readDrillsFromFilesystem



  //-----------------------------------------------------------
  func saveDrillsToFilesystem()
  {
            // Save the drills dictionary to the filesystem. It
            // will be saved as a .plist Property List.

    let manager = FileManager.default

    guard 
      let url = manager.urls(
                  for: .documentDirectory, 
                   in: .userDomainMask).first
    else { return }

    let fileURL = 
      url.appendingPathComponent(
          filePath )

    let encoder = PropertyListEncoder()
    encoder.outputFormat = .xml
    
    let encodedData = try! encoder.encode( drillsDictionary )
    
    try! encodedData.write( to: fileURL )

  } // saveDrillsToFilesystem


  //-----------------------------------------------------------
  func getShareData() -> URL
  {
    return fileURL
  } // getShareData

} // DrillModel
//--------------------------------------------
