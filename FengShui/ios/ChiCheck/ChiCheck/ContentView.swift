//
//  ContentView.swift
//  ChiCheck
//
//  Created by Benjamin Friesen on 2026-01-17.
//

import SwiftUI
import RealityKit

// ContentView.swift (Main Menu)
struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                NavigationLink(destination: PageOneView()) {
                    Text("Go to Page One")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                NavigationLink(destination: PageTwoView()) {
                    Text("Go to Page Two")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .navigationTitle("Main Menu")
        }
    }
}

// PageOneView.swift (Separate Page)
struct PageOneView: View {
    var body: some View {
        Text("Welcome to Page One!")
            .navigationTitle("Page One")
    }
}

// PageTwoView.swift (Another Page)
struct PageTwoView: View {
    var body: some View {
        Text("Welcome to Page Two!")
            .navigationTitle("Page Two")
    }
}
