//
//  DrillEditView.swift
//  CycleMusicTimer2
//
//  Created by Stewart French on 5/16/23.
//

import SwiftUI

//--------------------------------------------
// DrillEditView() presents a scrollable, editable sheet (pops up from
// the bottom) to permit a user to create and edit the exercise drill
// associated with this Artist+Track.
// 
// The default is to apply the drill to the Artist+Track such that
// if the user includes this same Artist+Track in another playlist the
// drill tags along.  However, the user can choose to apply this drill
// to this playlist only ( Artist+Track+Playlist ) by flipping the
// switch at the bottom.
// 
// When the user taps "Save Drill" the drill is saved on the
// device and will presist across app and device restarts.
// 
// DrillEditView() relies on the MusicViewModel() to access the
// Device Music Library.
//
// DrillEditView() relies on the DrillViewModel() to access the
// exercise drills.
//--------------------------------------------


//--------------------------------------------
struct DrillEditView: View 
{
  @EnvironmentObject var musicVM : MusicViewModel
  @EnvironmentObject var drillVM : DrillViewModel
  
  @State var playlist : String = ""
  @State var   artist : String = ""
  @State var    track : String = ""
  
  @Environment( \.presentationMode ) var presentationMode
  
  @State var drillText: String = ""
      
  @State var onlyThisPlaylist: Bool = false
  

  //-------------------------------------------
  //-------------------------------------------
  
  var body: some View 
  {
    ZStack
    {
      Color.black
      
      VStack
      {
              // Artist Name
        Text( artist )
          .font( .largeTitle )
          .foregroundColor( .white )
        
              // Track (Song) Name
        Text( track )
          .font( .largeTitle )
          .foregroundColor( .white )
        
        HStack
        {
          Text( "Enter/Edit Drill:" )
            .foregroundColor( .white )
          Spacer()

              // Cancel button to dismiss this sheet without saving
              // the drill.  Can also "swipe down" to dismiss it.

          Button(
            action:
            {
              presentationMode.wrappedValue.dismiss()
            },
            label:
            {
              Text( "Cancel" )
              .foregroundColor( .red )
//              .padding( 10 )

            } ) // Button
        } // HStack
        
        TextEditor( text: $drillText )
          .multilineTextAlignment( .leading )
          .disableAutocorrection( true )
          .padding( 8 )
          .foregroundColor( .primary )
        
        Spacer()
        
        HStack
        {

          Text( " " )

          Toggle( "", isOn: $onlyThisPlaylist )
            .labelsHidden()
            .padding( 10 )
            .background( 
               onlyThisPlaylist ?
                 Color.green.cornerRadius( 40 ) :
                 Color.gray.cornerRadius( 40 ) )

            Text( "Apply to this playlist only" )
          
          Spacer()
          
          Button(
            action:
              {
                // Save the drill text
                
                drillVM.CreateDrill(
                    playlistTitle : playlist,
                       artistName : artist,
                        trackName : track,
                       drillNotes : drillText,
                 thisPlaylistOnly : onlyThisPlaylist )

                presentationMode.wrappedValue.dismiss()
              },
            label:
              {
                Text( "Save Drill" )
                  .font( .headline )
                  .padding( 20 )
                  .background( Color.green.cornerRadius( 10 ) )
              } ) // Button
              .padding( 20 )
          
        } // HStack
        
        Spacer()
        
      } // VStack
    } // ZStack

    .onAppear
    {
      playlist = 
        musicVM.getPlaylistName(
           index: musicVM.selectedPlaylistIndex! )
      artist =
        musicVM.trackArtist(
           trackIndex: musicVM.selectedTrackIndex! )
      track =
        musicVM.trackName( 
           trackIndex: musicVM.selectedTrackIndex! )

      drillText = 
        drillVM.getCurrentDrill()

      onlyThisPlaylist = 
        drillVM.drillIsForPlaylist()

    } // onAppear
    
  } // var body
  
} // DrillEditView
//--------------------------------------------
