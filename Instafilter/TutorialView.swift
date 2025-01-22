//
//  TutorialView.swift
//  Instafilter
//
//  Created by Gary on 22/1/2025.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import PhotosUI
import SwiftUI
import StoreKit

struct TutorialView: View {
    var body: some View {
        Text("Hello, World!")
    }
}

struct ToolbarView: View {
    let processedImage: Image?
    let onFilterTap: () -> Void

    var body: some View {
        HStack(spacing: 20) {
            Button {
                onFilterTap()
            } label: {
                Label("更換濾鏡", systemImage: "camera.filters")
            }
            .disabled(processedImage == nil)

            Spacer()

            if let processedImage {
                ShareLink(
                    item: processedImage,
                    preview: SharePreview("編輯後的照片", image: processedImage)
                )
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}


struct AppStoreReview: View {
    @Environment(\.requestReview) var requestReview

    var body: some View {
        Button("Leave a review") {
            requestReview()
        }
    }
}

struct ShareLinkView: View {
    var body: some View {
        Form {
            ShareLink(item: URL(string: "https://www.hackingwithswift.com")!)

            ShareLink(item: URL(string: "https://www.hackingwithswift.com")!, subject: Text("Learn Swift here"), message: Text("Check out the 100 Days of SwiftUI!"))

            ShareLink(item: URL(string: "https://www.hackingwithswift.com")!) {
                Label("Spread the word about Swift", systemImage: "swift")
            }

            let example = Image(.example)
            ShareLink(item: example, preview: SharePreview("Singapore Airport", image: example)) {
                Label("Click to share", systemImage: "airplane")
            }
        }

    }
}

struct PhotosPickerView: View {
    @State private var pickerItem: PhotosPickerItem?
    @State private var selectedImage: Image?
    // Multi image
    @State private var pickerItems = [PhotosPickerItem]()
    @State private var selectedImages = [Image]()

    var body: some View {
        VStack {
            ScrollView {
                ForEach(0..<selectedImages.count, id: \.self) { i in
                    selectedImages[i]
                        .resizable()
                        .scaledToFit()
                }
            }
            PhotosPicker(selection: $pickerItems, maxSelectionCount: 3, matching: .any(of: [.images, .not(.screenshots)])) {
                Label("Select a picture", systemImage: "photo")
            }
        }
        .onChange(of: pickerItems) { oldValue, newValue in
            Task {
                selectedImages.removeAll()

                for item in pickerItems {
                    if let loadedImage = try await item.loadTransferable(type: Image.self) {
                        selectedImages.append(loadedImage)
                    }
                }
            }
        }
    }
}

struct ContentUnavailable: View {
    var body: some View {
        Form {
            ContentUnavailableView("No snippets", systemImage: "swift")
            ContentUnavailableView("No snippets", systemImage: "swift", description: Text("You don't have any saved snippets yet."))
            ContentUnavailableView {
                Label("No snippets", systemImage: "swift")
            } description: {
                Text("You don't have any saved snippets yet.")
            } actions: {
                Button("Create Snippet") {
                    // create a snippet
                }
                .buttonStyle(.borderedProminent)
            }
            ContentUnavailableView.search
        }
    }
}

struct CoreImage: View {
    @State private var image: Image?

    var body: some View {
        VStack {
            image?
                .resizable()
                .scaledToFit()
        }
        .onAppear(perform: loadImage)
    }

    func loadImage() {
        let inputImage = UIImage(resource: .example)
        let beginImage = CIImage(image: inputImage)

        let context = CIContext()
        let currentFilter = CIFilter.twirlDistortion()
        currentFilter.inputImage = beginImage

        let amount = 1.0

        let inputKeys = currentFilter.inputKeys

        if inputKeys.contains(kCIInputIntensityKey) {
            currentFilter.setValue(amount, forKey: kCIInputIntensityKey) }
        if inputKeys.contains(kCIInputRadiusKey) { currentFilter.setValue(amount * 200, forKey: kCIInputRadiusKey) }
        if inputKeys.contains(kCIInputScaleKey) { currentFilter.setValue(amount * 10, forKey: kCIInputScaleKey) }

        guard let outputImage = currentFilter.outputImage else {
            return
        }
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return
        }
        let uiImage = UIImage(cgImage: cgImage)
        image = Image(uiImage: uiImage)
    }
}

struct ConfirmationDialog: View {
    @State private var showingConfirmation = false
    @State private var backgroundColor = Color.white

    var body: some View {
        Button("Hello, World!") {
            showingConfirmation = true
        }
        .frame(width: 300, height: 300)
        .background(backgroundColor)
        .confirmationDialog("Change background", isPresented: $showingConfirmation) {
            Button("Red") { backgroundColor = .red }
            Button("Green") { backgroundColor = .green }
            Button("Blue") { backgroundColor = .blue }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Select a new color")
        }
    }
}

struct WrapperValueChange: View {
    @State private var blurAmount = 0.0 {
        didSet {
            print("didSet - New value is \(blurAmount)")
        }
    }

    var body: some View {
        VStack {
            Text("Hello, World!")
                .blur(radius: blurAmount)

            Slider(value: $blurAmount, in: 0...20)
                .onChange(of: blurAmount) { oldValue, newValue in
                    print("onChange - New value is \(newValue)")
                }
            Button("Random Blur") {
                blurAmount = Double.random(in: 0...20)
            }
        }
    }
}

#Preview {
//    TutorialView()
//        WrapperValueChange()
//        ConfirmationDialog()
//        CoreImage()
//        ContentUnavailable()
        PhotosPickerView()
//        ShareLinkView()
//        AppStoreReview()
}
