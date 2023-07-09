//
//  ContentView.swift
//  CycleMusicTimer2
//
//  Created by Stewart French on 3/31/23.
//

import SwiftUI

//--------------------------------------------
// ContentView() is the topmost, main view of the app.  Here we define
// a 3-column NavigationSplitView() with the sidebar column (leftmost)
// being the PlaylistsView(), the content column (middle) is the
// TracksView(), and the detail column (rightmost) being the
// SongTimerView().
// 
// We mark the navigationSplitView columnVisibility as .all so that
// all three columns will appear.  The user can choose to hide/restore
// the content column (leftmost).
// 
// It is here that we instantiate the MusicViewModel() to access the
// Device Music Library.
//
// It is here that we instantiate the DrillViewModel() to access the
// exercise drills.
//--------------------------------------------


//--------------------------------------------
struct ContentView: View
{
  @EnvironmentObject var musicVM : MusicViewModel
  @EnvironmentObject var drillVM : DrillViewModel

  @State var musicStateChanged : Bool = false

  @State private var columnVisibilityV = 
      NavigationSplitViewVisibility.all

  var body: some View
  {
            // NavigationSplitView - Three columns : Playlists, tracks
            // for the selected playlist, and a song timer display.

    NavigationSplitView( columnVisibility: $columnVisibilityV )
    {
      PlaylistsView( musicStateChanged: $musicStateChanged )
    }
    content:
    {
      Text( "Select a Playlist..." )
      .font(.system(size: 36.0))
      .opacity( 0.6 )

    }
  detail:
    {
      if musicVM.selectedTrackIndex == nil
      {
        Text( "then select a Track." )
        .font(.system(size: 36.0))
        .opacity( 0.6 )
      }
      else
      {
        SongTimerView( musicStateChanged: $musicStateChanged )
      }

    } // NavigationSplitView
    .navigationSplitViewStyle(.balanced)
    .onAppear
    {
            // WARNING!  HORRIBLE HACK 1!!
            // I have already instantiated an empty drillVM.musicVM in
            // order to get the environmentObject setup correctly.
            // Now everything is in place so I must set it to the
            // correct MusicViewModel().
            // grep for "HORRIBLE HACK 1!!" to see all the ugly parts.

      drillVM.musicVM = musicVM
    }

    } // var body
} // ContentView
//--------------------------------------------
