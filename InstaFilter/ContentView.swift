//
//  ContentView.swift
//  InstaFilter
//
//  Created by Maximilian Berndt on 2023/04/08.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI

struct ContentView: View {
    
    enum SupportedFilters: String, CaseIterable {
        case AreaAverage = "Area Average"
        case Bloom
        case Crystallize
        case Edges
        case GaussianBlur = "Gaussian Blur"
        case MorphologyGradient = "Morphology Gradient"
        case Pixellate
        case SepiaTone = "Sepia Tone"
        case UnsharpMask = "Unsharp Mask"
        case Vignette
        
        func getFilter() -> CIFilter {
            switch self {
            case .AreaAverage: return .areaAverage()
            case .Bloom: return .bloom()
            case .Crystallize: return .crystallize()
            case .Edges: return .edges()
            case .GaussianBlur: return .gaussianBlur()
            case .MorphologyGradient: return .morphologyGradient()
            case .Pixellate: return .pixellate()
            case .SepiaTone: return .sepiaTone()
            case .UnsharpMask: return .unsharpMask()
            case .Vignette: return .vignette()
            }
        }
    }
    
    @State private var image: Image?
    @State private var filterIntensity = 0.5
    @State private var filterRadius: Double = 100.0
    @State private var filterScale: Double = 10.0
    
    @State private var showingIntensitySlider = false
    @State private var showingRadiusSlider = false
    @State private var showingScaleSlider = false
    
    // Image Picker
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var processedImage: UIImage?
    
    // Filter confirmation dialog
    @State private var showingFilterDialog = false
    
    @State private var currentFilter: CIFilter = CIFilter.sepiaTone()
    let context = CIContext()
    
    var body: some View {
        NavigationView {
            VStack {
                ZStack {
                    Rectangle()
                        .fill(.secondary)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                    
                    Text("Tap to select picture")
                        .foregroundColor(.white)
                        .font(.headline)
                    
                    image?
                        .resizable()
                        .scaledToFit()
                }
                .onTapGesture {
                    showingImagePicker = true
                }
                
                VStack {
                    
                    if showingIntensitySlider {
                        HStack {
                            Text("Intensity")
                            Slider(value: $filterIntensity)
                                .onChange(of: filterIntensity) { _ in applyFilter() }
                        }
                        .padding(.vertical)
                    }
                    
                    if showingRadiusSlider {
                        HStack {
                            Text("Radius")
                            Slider(value: $filterRadius, in: 1...360)
                                .onChange(of: filterRadius) { _ in applyFilter() }
                        }
                        .padding(.vertical)
                    }
                    
                    if showingScaleSlider {
                        HStack {
                            Text("Scale")
                            Slider(value: $filterScale, in: 1...20)
                                .onChange(of: filterScale) { _ in applyFilter() }
                        }
                        .padding(.vertical)
                    }
                    
                    HStack {
                        Button("Change Filter") {
                            showingFilterDialog = true
                        }
                        
                        Spacer()
                        
                        Button("Save", action: save)
                            .disabled(inputImage == nil)
                    }
                }
            }
            .padding([.horizontal, .bottom])
            .navigationTitle("InstaFilter")
            .onChange(of: inputImage) { _ in loadImage() }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $inputImage)
            }
            .confirmationDialog("Select a filter", isPresented: $showingFilterDialog) {
                
                ForEach(SupportedFilters.allCases, id: \.self) { filter in
                    Button(filter.rawValue) {
                        setFilter(filter.getFilter())
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
        }
    }
    
    private func loadImage() {
        guard let inputImage = inputImage else { return }
        
        let beginImage = CIImage(image: inputImage)
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
        applyFilter()
    }
    
    private func applyFilter() {
        showingIntensitySlider = false
        showingRadiusSlider = false
        showingScaleSlider = false
        
        let inputKeys = currentFilter.inputKeys
        
        if inputKeys.contains(kCIInputIntensityKey) {
            showingIntensitySlider = true
            currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey)
        }
        
        if inputKeys.contains(kCIInputRadiusKey) {
            showingRadiusSlider = true
            currentFilter.setValue(Int(filterRadius), forKey: kCIInputRadiusKey)
        }
        
        if inputKeys.contains(kCIInputScaleKey) {
            showingScaleSlider = true
            currentFilter.setValue(Int(filterScale), forKey: kCIInputScaleKey)
        }
        
        guard let outputImage = currentFilter.outputImage else { return }
        
        if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
            let uiImage = UIImage(cgImage: cgimg)
            processedImage = uiImage
            image = Image(uiImage: uiImage)
        }
    }
    
    private func setFilter(_ filter: CIFilter) {
        currentFilter = filter
        loadImage()
    }
    
    private func save() {
        guard let processedImage = processedImage else { return }
        
        let imageSaver = ImageSaver()
        
        imageSaver.successHandler = {
            print("Success!")
        }
        
        imageSaver.errorHandler = {
            print("Oops! \($0.localizedDescription)")
        }
        
        imageSaver.writeToPhotoAlbum(image: processedImage)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
