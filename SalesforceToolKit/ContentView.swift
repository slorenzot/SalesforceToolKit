//
//  ContentView.swift
//  SalesforceToolKit
//
//  Created by Soulberto Lorenzo on 18/07/23.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
        }
        .padding()
        
//        super.init(contentRect: NSRect(x: 0, y: 0, width: 480, height: 300), styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView], backing: .buffered, defer: false)
//        makeKeyAndOrderFront(nil)
//        isReleasedWhenClosed = false
//        styleMask.insert(NSWindow.StyleMask.fullSizeContentView)
//        title = "title placeholder"
//        contentView = NSHostingView(rootView: ContentView())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
