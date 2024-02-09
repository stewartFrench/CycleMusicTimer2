//
//  TracksView.swift
//  CycleMusicTimer2
//
//  Created by Stewart French on 3/8/23.
//

import SwiftUI

//--------------------------------------------
// TracksView() presents a scrollable, selectable list of tracks
// (songs) from the selected playlist.
// The user will tap a track and we will transition to the
// SongTimerView() which presents a coundown timer, exercise drills,
// and all the controls.
// 
// Each track is shown with -
//   o in blue is the remaining time left in the playlist
//   o in the primary color is the name of the track
//   o in red is the first line of the drill associated with this
//     track, if any.
// 
// In the NavigationBar we see one icon on an iPad, and two icons on
// an iPhone.  The rightmost icon (called "filemenu.and.selection") is
// tapped to bring the currently selected playlist back into view (in
// case the user has scrolled the column such that the current
// selection is no longer visible).  On an iPhone, the leftmost icon
// (called "waveform") will cause a transition to the SongView() so
// the user can continue with the drill and control playback.
// 
// On an iPad TracksView() is the second, middle column presented
// (the "content").  On an iPhone it is presented second and takes the
// whole screen.
// 
// TracksView() relies on the MusicViewModel() to access the
// Device Music Library.
//
// TracksView() relies on the DrillViewModel() to access the
// exercise drills.
//--------------------------------------------


//--------------------------------------------
struct TracksView: View
{
  @EnvironmentObject var musicVM : MusicViewModel
  @EnvironmentObject var drillVM : DrillViewModel
  
  @State var localTrackSelected : Int? = nil

//  @State var musicStateChanged : Bool = false
  @Binding var musicStateChanged : Bool
  
  @State var elapsedTrackTime : Float = 0
  
  @State var scrollToCurrentTrack : Bool = false

  private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }


  //---------------------------------------------
  //---------------------------------------------
  var body: some View
  {
    VStack(spacing: 0)
    {
      
      //-------------------------------------------
      // Tracks Listing
      
      ScrollView
      {
        ScrollViewReader
        { proxy in
          ForEach( musicVM.MMTracks.indices, id: \.self )
          { feTrack in
            
            // This can't be the proper way to do this!!
            // I created a State var that indicates music went
            // from playing to paused and viceVersa so that these
            // images and fields would get updated.  Works, but...
            // yuk!
            NavigationLink(
              destination: SongTimerView( musicStateChanged: $musicStateChanged ) )
            {
              VStack
              {
                ZStack
                {
                  Text( musicStateChanged ? "" : "" )
                  
                  HStack
                  {
                    Text( 
                      musicVM.remainingDurationString( trackIndex: feTrack ) )
                    .foregroundColor( .blue )
                     .frame(
                        alignment: .leading )

                    VStack( spacing: 0 )
                    {
                        Text( musicVM.trackName(
                          trackIndex:feTrack ) )
                        .font(.system(size: 36.0))
                        .multilineTextAlignment(.leading)
                        .lineLimit( 3 )
                        .frame(
                            maxWidth: .infinity, 
                           alignment: .leading )

                        Text( 
                          drillVM.getFirstLine( trackIndex: feTrack ) )
                        .font(.system(size: 24.0))
                        .multilineTextAlignment(.leading)
                        .lineLimit( 1 )
                        .foregroundColor( .red )
                        .frame(
                            maxWidth: .infinity, 
                           alignment: .leading )

                    } // VStack
                  } // HStack
                  .padding( .leading, 5 )
                  
                  .frame(
                    maxWidth: .infinity,
                    minHeight: 75,
                    maxHeight: .infinity,
                    alignment: .leading )
                  .foregroundColor( .primary )
                  .background(
                    ( localTrackSelected != nil &&
                      localTrackSelected == feTrack ) ?
                    Color(uiColor: .lightGray) :
                      Color(UIColor.systemBackground) )
                } // ZStack
                
                Divider()
              } // VStack
            } // NavigationLink

            .id( feTrack )
            .simultaneousGesture(
              TapGesture().onEnded
              {
                localTrackSelected = feTrack
                musicVM.setSelectedTrack( trackIndex: feTrack )
                musicVM.pauseSelectedTrack()

                proxy.scrollTo( feTrack )
                
              } ) // simultaneousGesture
          } // ForEach
          
          .onChange(
            of: localTrackSelected )
              { old, new in
                withAnimation(.spring() )
                {
                  musicVM.setSelectedTrack( trackIndex: localTrackSelected! )
                  musicVM.saveTrackInfoToAppStorage()
                  proxy.scrollTo(localTrackSelected, anchor: .center)
                }
              } // onChange
          
          .onChange(
            of: scrollToCurrentTrack )
              { old, new in
                withAnimation(.spring() )
                {
                  proxy.scrollTo(localTrackSelected, anchor: .center)
                }
              } // onChange
          
          .onChange(
            of: musicVM.selectedTrackIndex )
              { old, new in
                localTrackSelected = musicVM.selectedTrackIndex
              } // onChange
          
        }  // ScrollViewReader
        
      } // ScrollView
      .border( .primary )
      
      Spacer()
      
      
      
    } // VStack
    
    
    //-------------------------------------------
    // Navigation Bar
    
    .navigationBarTitle(
      musicVM.getCollectionName(),
      displayMode: .inline )
    .navigationBarItems(
      trailing:
        HStack
      {
        NavigationLink(
          destination: SongTimerView( musicStateChanged: $musicStateChanged ),
          label:
            {
              Image( systemName: "waveform" )
            } )
        .disabled( musicVM.selectedTrackIndex == nil )
        .opacity( idiom == .pad ? 0 : 1 )
        
        Button(
          action:
            {
              scrollToCurrentTrack.toggle()
            },
          label:
            {
              Image( systemName: "filemenu.and.selection" )
            } )
      } ) // HStack
    
    
    //-------------------------------------------
    // When the View appears
    
    .onAppear
    {
      localTrackSelected = musicVM.getSelectedTrackIndex()
//      musicVM.saveTrackInfoToAppStorage()
      elapsedTrackTime = 0
      musicStateChanged = !musicStateChanged
    }
    
  } // var body
  
} // TracksView
//--------------------------------------------
