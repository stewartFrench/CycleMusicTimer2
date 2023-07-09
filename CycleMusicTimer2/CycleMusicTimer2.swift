//
//  CycleMusicTimer2.swift
//  CycleMusicTimer2
//
//  Created by Stewart French on 3/31/23.
//

import SwiftUI

//--------------------------------------------
// The app CycleMusicTimer2 implements what is described on this
// website - 
// 
//   https://cyclemusictimer.com/
// 
//--------------------------------------------


//--------------------------------------------
@main
struct CycleMusicTimer2 : App
{
  var musicVM : MusicViewModel = MusicViewModel()
  var drillVM : DrillViewModel = DrillViewModel()

  var body: some Scene
  {
        WindowGroup
        {
            ContentView()
              .environmentObject(musicVM)
              .environmentObject(drillVM)
              .onOpenURL
              { (urlIn) in

                // Handle drills being passed in (shared)

                drillVM.drillM.readDrillsFromURL( url : urlIn )
              }

        } // WindowGroup
    } // var body
} // CycleMusicTimer2
//--------------------------------------------
