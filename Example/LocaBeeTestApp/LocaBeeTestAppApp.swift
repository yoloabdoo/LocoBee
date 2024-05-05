//
//  LocaBeeTestAppApp.swift
//  LocaBeeTestApp
//
//  Created by Abdoelrahman Eaita on 02/05/2024.
//

import SwiftUI
import LocoBee

@main
struct LocaBeeTestAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(LocoBee.shared)
        }
    }
}
