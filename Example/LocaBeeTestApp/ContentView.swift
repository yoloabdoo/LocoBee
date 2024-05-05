//
//  ContentView.swift
//  LocaBeeTestApp
//
//  Created by Abdoelrahman Eaita on 02/05/2024.
//

import SwiftUI
import LocoBee

struct ContentView: View {
    
    @EnvironmentObject
    var location: LocoBee
    
    
    var body: some View {
        VStack {
            Button("Start") {
                location.register()
            }
            
            Button("Send location") {
                try? location.startObserving()
            }
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
