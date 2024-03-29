//
//  PlaylistsView.swift
//  CycleMusicTimer2
//
//  Created by Stewart French on 2/2/23.
//

import SwiftUI

//--------------------------------------------
// PlaylistsView() presents a scrollable, selectable list of Playlists.
// The user will tap a playlist and we will transition to the
// TracksView() which presents all the tracks associated with this
// playlist in order.
// On an iPad PlaylistsView() is the first, leftmost column presented
// (the "sidebar").  On an iPhone it is presented first and takes the
// whole screen.
// In the NavigationBar we see two icons, The leftmost can be tapped
// to hide this view (it will slide off to the left).  The rightmost
// icon (called "filemenu.and.selection") is tapped to bring the
// currently selected playlist back into view (in case the user has
// scrolled the column such that the current selection is no longer
// visible).
//
// When this view first appears it checks the whether the user has
// been granted access to the music library.  If so, it quietly reads
// the playlists and continues.  If not, it pops an alert to let the
// user select whether to permit access.
//
// PlaylistsView() uses the MusicViewModel() to access the Apple Music
// Library on this device.  
//--------------------------------------------


//--------------------------------------------
struct PlaylistsView: View 
{
  @EnvironmentObject var musicVM : MusicViewModel
  
  @State private var tSelectedPlaylist: Int? = nil
  
  @State private var scrollToCurrentPlaylist : Bool = false
  
  @State private var thumbedPlaylist : Int = 0
  
  @State var notAuthorized : Bool = false

  @Binding var musicStateChanged : Bool

  private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }


  //-------------------
  var body: some View
  {
    HStack
    {
      ScrollView( showsIndicators: true )
      {
        ScrollViewReader
        { proxy in

          ForEach( musicVM.MMPlaylists.indices, id: \.self )
          { feIndex in

            NavigationLink(
              destination: TracksView( 
                              musicStateChanged: $musicStateChanged ),
              label:
                {
                  VStack
                  {
                    Text(musicVM.getPlaylistName(index: feIndex))
                      .font(.system(size: 36.0))
                      .frame(
                        maxWidth: .infinity,
                        minHeight: 50,
                        maxHeight: .infinity,
                        alignment: .leading )
                      .multilineTextAlignment(.leading)
                      .lineLimit( 3 )
                      .foregroundColor( .primary )
                      .background(
                        tSelectedPlaylist==feIndex ?
                        Color( UIColor.lightGray ) :
                          Color(UIColor.systemBackground) )
                      .padding( .leading, 5 )
                    Divider()
                  } // VStack
                } ) // NavigationLink
            .id( feIndex )
            .simultaneousGesture(
              TapGesture().onEnded
              {
                musicVM.setSelectedPlaylist(
                  index: feIndex )

                musicVM.retrieveTracksFromPlaylist(
                  playlistIndex: feIndex )

                musicVM.prepareTracksToPlay()
                       // This call seems to cause a hiccup in the
                       // playback.  ( WHY IS IT HERE ANYWAY!? )
//                musicVM.zeroCurrentPlaybackTime()

                tSelectedPlaylist = feIndex

              } ) // simultaneousGesture

          } // Foreach

          .onChange(
            of: scrollToCurrentPlaylist )
              { old, new in
                withAnimation(.spring() )
                {
                  proxy.scrollTo(tSelectedPlaylist, anchor: .center)
                }

              } // onChange

          .onChange(
           of: thumbedPlaylist )
              { old, new in
                withAnimation(.spring() )
                {
                  proxy.scrollTo( thumbedPlaylist, anchor: .center )
                }

              } // onChange

        } // ScrollViewReader
      } // ScrollView

      Divider()

      Spacer()

    } // HStack



    //-------------------------------------------
    // Navigation Bar

    .navigationBarTitle( "Playlists", displayMode: .inline )
    .font(.largeTitle)

    .navigationBarItems(
      leading:

        Link(
          destination: URL(string: "https://cyclemusictimer.com")! )
        {
          Image( "goto_website" )
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(width: 30, height: 30)
        },
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
              scrollToCurrentPlaylist.toggle()
            },
          label:
            {
              Image( systemName: "filemenu.and.selection" )
            } ) // Button

        } ) // navigationBarItems
    
    .onAppear
    {
      notAuthorized = !musicVM.authorizedToAccessMusic

      if musicVM.selectedPlaylistIndex != nil
      {
        tSelectedPlaylist = musicVM.selectedPlaylistIndex
      }
    } // .onAppear

    .alert( isPresented: $notAuthorized )
    {
      Alert(
        title: Text( "Not Allowed to Access the Music Library." ),
        message: Text( "Go to Settings > CycleTimer2\nto Allow Access to Apple Music" ) )
    } // .alert

  } // var body
  
} // PlaylistsView
//--------------------------------------------
