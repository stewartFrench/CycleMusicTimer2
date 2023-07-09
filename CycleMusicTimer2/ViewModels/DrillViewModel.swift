//
//  DrillViewModel.swift
//  CycleMusicTimer2
//
//  Created by Stewart French on 5/17/23.
//

import Foundation
import SwiftUI

//--------------------------------------------
// The class DrillViewModel() is a SwiftUI View Model whose purpose is
// to act as an interface with the DrillModel(), providing the
// necessary data, properly cleaned and formatted (if required) for
// the various Views in the app.
// 
// The various Views in the app can use a DrillViewModel() to -
//   o Create a drill assocated with an Artist+Track+Playlist (the
//     playlist is optional)
//   o Retrieve the drill associated with the current track
//   o Retrieve the drill associated with the next track, if there is one
//   o determine if this drill is unique to the current playlist
//   o Retrieve the first line of the drill associated with the
//     umbered track
//   o Handle the user loading a drill file as part of a "share"
//     action.
//--------------------------------------------


//--------------------------------------------
class DrillViewModel : ObservableObject
{
  var drillM : DrillModel = DrillModel()

            // WARNING!  HORRIBLE HACK 1!!
            // I have to initialize musicVM either here or as part of
            // an init() function.  Either way, when used as part of a
            // SwiftUI environment where I'm going to make it visible
            // through a .environmentObject(drillVM) I can't fully
            // initialize musicVM it because the compiler will not
            // allow it.  I have created an empty initializer so that
            // I can create the object, then I replace the object with
            // the correct environmentObject MusicViewModel().
            // grep for "HORRIBLE HACK 1!!" to see all the ugly parts.

  var musicVM : MusicViewModel = MusicViewModel( empty: true )



  //-----------------------------------------------------------
//  init( musicVM musicVMP : MusicViewModel )
//  {
//    self.musicVM = musicVMP
//  } // init


  //-----------------------------------------------------------
  func CreateDrill(
       playlistTitle playlistTitleP    : String,
          artistName artistNameP       : String,
           trackName trackNameP        : String,
          drillNotes drillNotesP       : String,
    thisPlaylistOnly thisPlaylistOnlyP : Bool = false )
  {
    drillM.CreateDrill(
       playlistTitle : playlistTitleP,
          artistName : artistNameP,
           trackName : trackNameP,
          drillNotes : drillNotesP,
    thisPlaylistOnly : thisPlaylistOnlyP )

  } // CreateDrill


  //-----------------------------------------------------------
  func getCurrentDrill() -> String
  {

    if musicVM.selectedPlaylistIndex == nil ||
          musicVM.selectedTrackIndex == nil
    {
      return ""
    }

    let tDrill = 
      drillM.getDrill(
        playlistTitle :
              musicVM.getPlaylistName(
                 index: musicVM.selectedPlaylistIndex! ),
           artistName : 
              musicVM.trackArtist(
                 trackIndex: musicVM.selectedTrackIndex! ),
            trackName :
          musicVM.trackName( 
                 trackIndex: musicVM.selectedTrackIndex! ) )

    if tDrill == nil
    {
      return ""
    }

    return tDrill!

  } // getCurrentDrill


  //-----------------------------------------------------------
  func getNextDrill() -> String
  {

    if musicVM.selectedPlaylistIndex == nil ||
          musicVM.selectedTrackIndex == nil
    {
      return ""
    }

    let tTrackIndex = musicVM.selectedTrackIndex! + 1

    if tTrackIndex == musicVM.MMTracks.count
    {
      return ""
    }

    let tPl = musicVM.getPlaylistName(
                 index: musicVM.selectedPlaylistIndex! )
    let tAr =
              musicVM.trackArtist(
                 trackIndex: tTrackIndex )
    let tTr =
          musicVM.trackName( 
                 trackIndex: tTrackIndex )

    let nextDrill = 
      drillM.getDrill(
        playlistTitle : tPl,
           artistName : tAr,
            trackName : tTr )

    if nextDrill == nil
    {
      return ""
    }

    let combinedDrills = 
          "\n______ Next Drill ______\n" +
          nextDrill!

    return combinedDrills

  } // getNextDrill


  //-----------------------------------------------------------
  func drillIsForPlaylist() -> Bool
  {

    let playlistT = 
      musicVM.getPlaylistName(
         index: musicVM.selectedPlaylistIndex! )
    let artistT =
      musicVM.trackArtist(
         trackIndex: musicVM.selectedTrackIndex! )
    let trackT =
      musicVM.trackName( 
         trackIndex: musicVM.selectedTrackIndex! )

    return 
      drillM.drillIsForPlaylist(
         playlistTitle : playlistT,
            artistName : artistT,
             trackName : trackT )
    
  } // drillIsForPlaylist


  //-----------------------------------------------------------
  func getFirstLine( trackIndex trackIndexP : Int ) -> String
  {
    let tDrillString = 
        drillM.getDrill(
          playlistTitle :
                musicVM.getPlaylistName(
                   index: musicVM.selectedPlaylistIndex! ),
             artistName : 
                musicVM.trackArtist(
                   trackIndex: trackIndexP ),
              trackName :
                musicVM.trackName(
                   trackIndex: trackIndexP ) )

      let tDrillArray = 
         tDrillString?.components( separatedBy: "\n" )

      if tDrillArray != nil
      {
        return tDrillArray![ 0 ]
      }
      else
      {
        return ""
      }

  } // getFirstLine


  //-----------------------------------------------------------
  func getShareData() -> URL
  {
     let tData = drillM.getShareData()
     return tData

  } // getShareData


} // DrillViewModel
//--------------------------------------------
