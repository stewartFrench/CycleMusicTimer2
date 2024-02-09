//
//  SongTimerView.swift
//  CycleMusicTimer2
//
//  Created by Stewart French on 4/19/23.
//

import SwiftUI

//--------------------------------------------
// SongTimerView() is the detail view (rightmost) of our 3-column
// NavigationSplitView().  This views main displays are a large
// count-down timer, and the drill associated with the current music
// track (song).  Also, the user can -
//   o backup 15 seconds in the song
//   o jump forward 15 seconds in the song
//   o increase the speed of the song up to 1.25x
//   o decrease the speed of the song up to -0.75x
//   o view, scroll, and edit the drill associated with this song
//   o jump to the beginning of this song (or the previous song if the
//     time is less than 3 seconds)
//   o pause/play the song
//   o jump to the next song
// 
// SongTimerView() will adjust the size of the countdown time (in a
// rudimentary way) based on whether this device is an iPad or
// iPhone.  
// 
// This view also support sharing of drills by tapping the share icon
// in the upper right corner.
// 
// SongTimerView() relies on the MusicViewModel() to access the
// Device Music Library.
//
// SongTimerView() relies on the DrillViewModel() to access the
// exercise drills.
//--------------------------------------------


//--------------------------------------------
struct SongTimerView: View 
{
  @EnvironmentObject var musicVM : MusicViewModel
  @EnvironmentObject var drillVM : DrillViewModel

//  @State var musicStateChanged : Bool = false

  @Binding var musicStateChanged : Bool
  
            // I added showDrills as a debug/info tool.  If you
            // longPress the countdown timer (touch the actual numbers
            // themselves) it will toggle between Drills and the Music
            // Library track details.
            
  @State var showDrills : Bool = true

  @State var elapsedTrackTime : Float = 0
  @State var countdownTime : Double = 0
  
  @State var trackPlaybackRate : Float = 1.0
  
  @State var showSheet : Bool = false


  @State var timer = Timer.publish(
    every: 0.5,
    on: .main,
    in: .common ).autoconnect()
  
  private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }

  
  //---------------------------------------
  func adjustedFontSize( 
       frameHeight frameHeightP : CGFloat,
        frameWidth  frameWidthP : CGFloat ) -> CGFloat
  {
//    print( "Frame frameHeight == \(frameHeightP)" )
//    print( "Frame frameWidth == \(frameWidthP)" )

          // I could not find a "standard" way (that actually worked)
          // to resize a font based on the column visibility (1, 2, or
          // 3 in NavigationSplitView) and orientation (landscape or
          // portrait).  So I experimentally determined these values
          // and tested them on various devices for acceptability.

    if frameWidthP < 440
    {
      return 100.0
    }
    if frameWidthP < 900
    {
      return 160.0
    }

    return 240.0
  } // setFontSize


  //----------
  func adjustedFontFrameHeight( 
       frameHeight frameHeightP : CGFloat,
        frameWidth  frameWidthP : CGFloat ) -> CGFloat
  {
//    print( "Font frameHeight == \(frameHeightP)" )
//    print( "Font frameWidth == \(frameWidthP)" )

    if frameWidthP < 440
    {
      return 100
    }
    if frameWidthP < 900
    {
      return 120
    }
    return 240
  } // adjustedFontFrameHeight



  //---------------------------------------
  func stopTimer()
  {
    timer.upstream.connect().cancel()
  } // stopTimer
  
  
  //----------
  func startTimer()
  {
    timer = Timer.publish(
      every: 0.5,
      on: .main,
      in: .common ).autoconnect()
  } // startTimer
  
  
  
  //-------------------------------------------
  func countdownTimeMinutes( time: Double ) -> String
  {
    let tMinutes = Int(time) / 60
    let s = String( format: "%02d", tMinutes )
    return s
  } // countdownTimeMinutes
  
  
  //-------------------------------------------
  func countdownTimeSeconds( time: Double ) -> String
  {
    let tSeconds = Int(time) % 60
    let s = String( format: "%02d", tSeconds )
    return s
  } // countdownTimeSeconds
  
  
  
  //-------------------------------------------
  //-------------------------------------------
  var body: some View
  {
    GeometryReader
    { screenGeometry in
      VStack
      {
        Text(
          musicVM.trackArtist(
            trackIndex: musicVM.selectedTrackIndex! ) )
          .lineLimit( 1 )
        
        VStack( spacing: 0 )
        {
          // -------------
          // Song Title
          
          Text(
            musicVM.trackName(
              trackIndex: musicVM.selectedTrackIndex! ) )
          .foregroundColor( Color.white )
          .lineLimit( 2...2 )  // exactly 2 lines so it won't shift
                               // the other views when going from 1 to
                               // 2 lines.
          
          // -------------
          // Countdown Timer and Controls
          
          HStack( alignment: .bottom )
          {
            Spacer()
            Text(
              countdownTimeMinutes(
                time: countdownTime ) )
            Text( ":" )
            Text(
              countdownTimeSeconds(
                time: countdownTime ) )

            Spacer()
          } // HStack
          .font(
            .system( 
              size: adjustedFontSize( 
                      frameHeight: screenGeometry.size.height,
                       frameWidth: screenGeometry.size.width ) )
          .monospacedDigit() )
          .frame(
              maxWidth: .infinity,
             minHeight: 75,
             maxHeight: 
               adjustedFontFrameHeight( 
                      frameHeight: screenGeometry.size.height,
                       frameWidth: screenGeometry.size.width ),
             alignment: .leading )

          .onLongPressGesture
           { 
             showDrills.toggle()
           }

          HStack
          {
            // -------------
            // Minus 15 Seconds Button

            Button(
              action:
                {
                  musicVM.skipBack15SecondsInTrack()
                  musicStateChanged = !musicStateChanged
                }, 
              label: 
                {
                  Image( "minus_15_v1" )
                } ) // Button
            
            Spacer()
            
            // -------------
            // Rate Change Slider
            
            ZStack
            {
              HStack
              {
                Spacer()
                Text( "|" )
                Spacer()
              }

              Slider( value: $trackPlaybackRate,
                      in: 0.75...1.25,
                      step: 0.05 )
            }
            
            Spacer()
            
            // -------------
            // Plus 15 Seconds Button
            
            Button(
              action:
                {
                  musicVM.skipForward15SecondsInTrack()
                  musicStateChanged = !musicStateChanged
                }, 
              label: 
                {
                  Image( "plus_15_v1" )
                } ) // Button
            
          } // HStack
          .padding( 5 )
          
          // -------------
          // Workout Drills
          
          ZStack
          {
            ScrollView( [.vertical] )
            {
//                      // We'll either show the drills or the track
//                      // details info
//              ZStack
//              {
                VStack( spacing: 0 )
                {
                  Text( drillVM.getCurrentDrill() )
                  .font( .title )
                  .multilineTextAlignment(.center)
                  .foregroundColor( Color.red )
  
                  Text( drillVM.getNextDrill() )
                  .font( .title )
                  .multilineTextAlignment(.center)
                  .foregroundColor( Color.blue )
                  Spacer()
                } // VStack
//                .opacity( showDrills ? 1 : 0 )
//
//                VStack
//                {
//                  Text( 
//                     musicVM.RetrieveMediaItemProperties( 
//                      trackIndex : musicVM.selectedTrackIndex! ) )
//                  .font( .system( size : 10 ) )
//                  .monospaced()
//                  .multilineTextAlignment(.leading)
//                  .foregroundColor( Color.red )
//                  Spacer()
//                } // VStack
//                .opacity( showDrills ? 0 : 1 )
//
//              } // ZStack


            } // ScrollView
            .frame( minWidth: 200,
                    maxWidth: .infinity,
                    minHeight: screenGeometry.size.height * 0.50 )
            .background( Color.white )


            VStack
            {
              HStack
              {
                Spacer()
                Button(
                  action:
                  {
                    showSheet.toggle()
                  },
                  label:
                  {
                    Image( "slf_edit" )
                  } ) // Button

              }
              Spacer()
            } // VStack
          } // ZStack
            .sheet(
              isPresented: $showSheet,
              content:
              {
                NavigationView
                {
                  DrillEditView()
                }

              } ) // sheet
          
          Spacer()
          
          //-------------------------------------------
          // Playback Controls
          
          // -------------
          // Previous Track Button
          
          HStack
          {
            Button(
              action:
                {
                  musicVM.previousTrackPressed()
                  
                  musicStateChanged = !musicStateChanged
                }, label: {
                  Image( "slf_rewind" )
                } ) // Button
            
            Spacer()
            
            
            
            // -------------
            // Play/Pause Button
            
            Button(
              action:
                {
                  if musicVM.isPlaying()
                  {
                    musicVM.pauseSelectedTrack()
                  } 
                  else 
                  {
                    musicVM.playSelectedTrack()
                  }
                  musicStateChanged = !musicStateChanged
                },
              label:
                {
                  ZStack
                  {
                    Text( musicStateChanged ? "" : "" )
                    Image( musicVM.isPlaying() ? "slf_pause" : "slf_play" )
                  }
                } ) // Button
            
            Spacer()
            
            
            
            // -------------
            // Forward Track Button
            
            Button(
              action:
                {
                  musicVM.nextTrackPressed()
                  
                  musicStateChanged = !musicStateChanged
                }, label: {
                  Image( "slf_fastforward" )
                  
                } ) // Button
          } // HStack
          .padding( 5 )
          
        } // VStack
        .frame( minWidth: 200,
                maxWidth: .infinity,
                maxHeight: .infinity)
        .padding( 5 )
        .foregroundColor( Color.white )
        .background( Color.black )
        
      } // VStack
    } // GeometryReader    
    
    //-------------------------------------------
    // Navigation Bar

    .navigationBarItems(
      trailing:
        HStack
        {
          ShareLink( item: drillVM.getShareData() )
          {
            Image( systemName: "square.and.arrow.up" )
          }
         } ) // navigationBarItems

    
    //-------------------------------------------
    // When the View appears
    
    .onAppear
    {
      startTimer()
      musicStateChanged = !musicStateChanged
    }
    
    //-------------------------------------------
    // When the View disappears
    
    .onDisappear()
    {
      stopTimer()
    }
    
    .onReceive( timer,
          perform:
    { _ in

      elapsedTrackTime =
        Float( musicVM.elapsedTimeOfSelectedTrack() /
               musicVM.durationOfSelectedTrack() )
      
      countdownTime =
        musicVM.durationOfSelectedTrack() -
          musicVM.elapsedTimeOfSelectedTrack()

      musicStateChanged = !musicStateChanged

    } )  // onReceive
    

    .onChange(
      of: musicVM.selectedTrackIndex )
        {
          countdownTime =
            musicVM.durationOfSelectedTrack()
          trackPlaybackRate = 1.0
        } // onChange
    

    .onChange(
      of: trackPlaybackRate )
        {
          musicVM.setPlaybackRate( playbackRate: trackPlaybackRate )
        } // onChange
    
  } // var body
} // SongTimerView
//--------------------------------------------
