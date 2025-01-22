//
//  ContentView.swift
//  Instafilter
//
//  Created by iOS Dev Ninja on 4/1/2025.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import PhotosUI
import SwiftUI
import StoreKit

struct FilterSettings {
    var intensity = 0.5
    var radius = 0.5
}

struct ContentView: View {
    @AppStorage("filterCount") var filterCount = 0
    @Environment(\.requestReview) var requestReview
    
    @State private var settings = FilterSettings()
    @State private var processedImage: Image?
    @State private var selectedItem: PhotosPickerItem?

    @State private var currentFilter: CIFilter = CIFilter.sepiaTone()
    let context = CIContext()
    
    @State private var showingFilters = false

    var body: some View {
        NavigationStack {
            VStack {
                PhotoPickerView(selectedItem: $selectedItem,
                                processedImage: processedImage,
                                onLoadImage: loadImage)

                FilterView(settings: $settings,
                           onApplyProcessing: applyProcessing,
                           onDisable: disable)
                
                FooterView(processedImage: processedImage,
                           onChangeFilter: changeFilter,
                           onDisable: disable)
                
            }
            .padding([.horizontal, .bottom])
            .navigationTitle("Instafilter")
            .confirmationDialog("Select a filter", isPresented: $showingFilters) {
                Button("Crystallize") { setFilter(CIFilter.crystallize() )}
                Button("Edges") { setFilter(CIFilter.edges() )}
                Button("Gaussian Blur") { setFilter(CIFilter.gaussianBlur() )}
                Button("Pixellate") { setFilter(CIFilter.pixellate() )}
                Button("Sepia Tone") { setFilter(CIFilter.sepiaTone() )}
                Button("Unsharp Mask") { setFilter(CIFilter.unsharpMask() )}
                Button("Vignette") { setFilter(CIFilter.vignette() )}
                Button("Cancel", role: .cancel) { }
            }
        }
    }
    
    func changeFilter() {
        showingFilters = true
    }
    
    func loadImage() {
        Task {
            guard let imageData = try await selectedItem?.loadTransferable(type: Data.self) else { return }
            guard let inputImage = UIImage(data: imageData) else { return }
            
            let beginImage = CIImage(image: inputImage)
            currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
            applyProcessing()
        }
    }
    
    func applyProcessing() {
        let inputKeys = currentFilter.inputKeys

        if inputKeys.contains(kCIInputIntensityKey) { currentFilter.setValue(settings.intensity, forKey: kCIInputIntensityKey) }
        if inputKeys.contains(kCIInputRadiusKey) { currentFilter.setValue(settings.radius * 200, forKey: kCIInputRadiusKey) }
        if inputKeys.contains(kCIInputScaleKey) { currentFilter.setValue(settings.intensity * 10, forKey: kCIInputScaleKey) }

        guard let outputImage = currentFilter.outputImage else { return }
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return }

        let uiImage = UIImage(cgImage: cgImage)
        processedImage = Image(uiImage: uiImage)
    }
    
    @MainActor func setFilter(_ filter: CIFilter) {
        currentFilter = filter
        loadImage()
        
        filterCount += 1
        if filterCount >= 5 {
            requestReview()
        }
    }
    func disable() -> Bool {
        return processedImage == nil
    }
}

struct PhotoPickerView: View {
    @Binding var selectedItem: PhotosPickerItem?
    let processedImage: Image?
    let onLoadImage: () -> Void

    var body: some View {
        PhotosPicker(selection: $selectedItem) {
            if let processedImage {
                processedImage
                    .resizable()
                    .scaledToFit()
            } else {
                ContentUnavailableView("No picture", systemImage: "photo.badge.plus", description: Text("Tap to import a photo"))
            }
        }
        .buttonStyle(.plain)
        .onChange(of: selectedItem, onLoadImage)
    }
}

struct FilterView: View {
    @Binding var settings: FilterSettings
    let onApplyProcessing: () -> Void
    let onDisable: () -> Bool
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text("Intensity")
                    .font(.headline)
                HStack {
                    Slider(value: $settings.intensity)
                        .onChange(of: settings.intensity, onApplyProcessing)
                        .disabled(onDisable())
                    Text("\(Int(settings.intensity * 100))%")
                        .monospacedDigit()
                        .frame(width: 48)
                }
            }
            VStack(alignment: .leading) {
                Text("Radius")
                    .font(.headline)
                HStack {
                    Slider(value: $settings.radius)
                        .onChange(of: settings.radius, onApplyProcessing)
                        .disabled(onDisable())
                    Text("\(Int(settings.radius * 100))%")
                        .monospacedDigit()
                        .frame(width: 48)
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
    }
}

struct FooterView: View {
    let processedImage: Image?
    let onChangeFilter: () -> Void
    let onDisable: () -> Bool
    
    var body: some View {
        HStack {
            Button("Change Filter", action: onChangeFilter)
                .disabled(onDisable())
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                }
            Spacer()
            
            if let processedImage {
                ShareLink(item: processedImage, preview: SharePreview("Instafilter image", image: processedImage))
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    }
            }
        }
    }
}

struct ImagePreviewView: View {
    let processedImage: Image?
    let onTap: () -> Void
    @Binding var selectedItem: PhotosPickerItem?
    
    var body: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            ZStack {
                if let processedImage {
                    processedImage
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 8)
                        .padding()
                        .transition(.opacity) // 添加過渡動畫
                } else {
                    ContentUnavailableView {
                        Label("No Picture", systemImage: "photo.badge.plus")
                    } description: {
                        Text("點擊選擇照片開始編輯")
                    } actions: {
                        Button("選擇照片", action: onTap)
                            .buttonStyle(.bordered)
                    }
                    .frame(height: 300)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}


