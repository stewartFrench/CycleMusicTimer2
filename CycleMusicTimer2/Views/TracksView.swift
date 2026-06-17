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
  
  @State var showingSettings : Bool = false
  @AppStorage("showPlaylistElapsedTimeInTracks") private var showPlaylistElapsedTime : Bool = false

  @State private var pdfURL : URL? = nil
  @State private var showingPDFShare : Bool = false
  @State private var showingPDFError : Bool = false

  private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }


  //---------------------------------------------
  //---------------------------------------------
  var body: some View
  {
    VStack(spacing: 0)
    {
      
      //-------------------------------------------
      // Playlist Name Header (fixed, non-scrolling)
      
      Text(musicVM.getCollectionName())
        .font(.title2)
        .fontWeight(.semibold)
        .lineLimit(2)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
      
      Divider()
      
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
                      showPlaylistElapsedTime ?
                      musicVM.elapsedDurationString( trackIndex: feTrack ) :
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
    
    .navigationBarTitleDisplayMode(.inline)
    .toolbar
    {
      ToolbarItem(placement: .navigationBarLeading)
      {
        Button(
          action:
            {
              showingSettings = true
            },
          label:
            {
              Image( systemName: "gearshape" )
            } )
      }
      
      ToolbarItem(placement: .navigationBarTrailing)
      {
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
        }
      }
    }
    .sheet(isPresented: $showingSettings)
    {
      NavigationView
      {
        Form
        {
          Section(header: Text("Duration Display"))
          {
            Toggle("Show Playlist Elapsed Time", isOn: $showPlaylistElapsedTime)
            
            Text(showPlaylistElapsedTime ? 
              "Displays cumulative time elapsed" : 
              "Displays time remaining in each track")
              .font(.caption)
              .foregroundColor(.secondary)
          }

          Section(header: Text("Print"))
          {
            Button(
              action:
                {
                  // Generate PDF
                  if let url = buildPlaylistPDF()
                  {
                    // Verify file exists and is readable before showing share sheet
                    if FileManager.default.fileExists(atPath: url.path)
                    {
                      pdfURL = url
                      // Dismiss settings sheet first
                      showingSettings = false
                      // Then show share sheet after settings sheet is dismissed
                      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showingPDFShare = true
                      }
                    }
                    else
                    {
                      showingPDFError = true
                    }
                  }
                  else
                  {
                    showingPDFError = true
                  }
                },
              label:
                {
                  Label("Print Playlist as PDF", systemImage: "printer")
                } )

            Text("Creates a PDF of all tracks (time, artist, album, title, drill) and opens the Share sheet so you can message, email, or save it.")
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }
        .navigationBarTitle("Settings", displayMode: .inline)
        .navigationBarItems(trailing: Button("Done")
        {
          showingSettings = false
        })
        .alert("PDF Generation Failed", isPresented: $showingPDFError)
        {
          Button("OK", role: .cancel) { }
        } message: {
          Text("Unable to create the PDF. Please try again.")
        }
      }
    }
    .sheet(isPresented: $showingPDFShare, onDismiss: {
      // Clean up URL when sheet is dismissed
      pdfURL = nil
    })
    {
      if let url = pdfURL
      {
        PlaylistPDFShareSheet(activityItems: [url])
          .presentationDetents([.medium, .large])
          .interactiveDismissDisabled(false)
      }
      else
      {
        Text("Loading PDF...")
          .onAppear {
            // If URL becomes nil, dismiss the sheet
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
              showingPDFShare = false
            }
          }
      }
    }
    
    
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


  //---------------------------------------------
  // Build the printable PDF for the currently selected playlist
  // and return its temporary file URL.
  //---------------------------------------------
  private func buildPlaylistPDF() -> URL?
  {
    var entries : [PlaylistPDFTrack] = []

            // Match the in-app toggle:
            //   ON  -> show cumulative elapsed time through end of track
            //   OFF -> show remaining time from this track to end
    let plTimeLabel = showPlaylistElapsedTime ? "Elapsed" : "Remaining"

    for tIndex in musicVM.MMTracks.indices
    {
      let tDrill = drillVM.getFullDrill( trackIndex: tIndex )

      let tPlTime = showPlaylistElapsedTime
                    ? musicVM.elapsedDurationString( trackIndex: tIndex )
                    : musicVM.remainingDurationString( trackIndex: tIndex )

      let tPlTimeTrim = tPlTime.trimmingCharacters( in: .whitespaces )

      entries.append(
        PlaylistPDFTrack(
                    index : tIndex + 1,
                     time : musicVM.trackDurationString( trackIndex: tIndex ),
         playlistTimeLabel : plTimeLabel,
              playlistTime : tPlTimeTrim,
                   artist : musicVM.trackArtist( trackIndex: tIndex ),
                    album : musicVM.trackAlbum( trackIndex: tIndex ),
                    title : musicVM.trackName( trackIndex: tIndex ),
                    drill : tDrill.isEmpty ? nil : tDrill ) )
    }

    return PlaylistPDFGenerator.generate(
              playlistName: musicVM.getCollectionName(),
                    tracks: entries )

  } // buildPlaylistPDF

} // TracksView
//--------------------------------------------
