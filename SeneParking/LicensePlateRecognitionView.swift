//
//  LicensePlateRecognitionView.swift
//  SeneParking
//
//  Created by Pablo Pastrana on 7/10/24.
//

import SwiftUI
import AVFoundation
import Vision

struct LicensePlateRecognitionView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var camera = CameraModel()
    @State private var recognizedText = ""
    @State private var parkingStatus = ""
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all) // Black background
            
            CameraPreview(camera: camera)
                .mask(CameraPreviewMask())
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    Button(action: {
                        camera.takePicture()
                    }) {
                        Image(systemName: "camera")
                            .font(.largeTitle)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.black)
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.bottom)
                
                Text("Recognized Plate: \(recognizedText)")
                    .foregroundColor(.white)
                    .padding()
                
                Text("Status: \(parkingStatus)")
                    .foregroundColor(.white)
                    .padding()
            }
            
            VStack {
                HStack {
                    Button(action: {
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                Spacer()
            }
            .padding()
        }
        .onReceive(camera.$capturedImage) { image in
            if let image = image {
                recognizeText(in: image)
            }
        }
    }
    
    private func recognizeText(in image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            DispatchQueue.main.async {
                self.recognizedText = recognizedStrings.joined(separator: " ")
                simulateParking(plate: self.recognizedText)
            }
        }
        
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform text recognition: \(error)")
        }
    }
    
    private func simulateParking(plate: String) {
        // Simulate parking process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.parkingStatus = "Vehicle with plate \(plate) entered. Barrier opened."
            
            // Simulate exit after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                let parkingDuration = 5 // seconds, for demo purposes
                let parkingFee = Double(parkingDuration) * 10 // $
                self.parkingStatus = "Vehicle with plate \(plate) exited. Parking duration: \(parkingDuration)s. Fee: $\(String(format: "%.2f", parkingFee))"
            }
        }
    }
}

class CameraModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var isTaken = false
    @Published var session = AVCaptureSession()
    @Published var alert = false
    @Published var output = AVCapturePhotoOutput()
    @Published var preview: AVCaptureVideoPreviewLayer!
    @Published var capturedImage: UIImage?

    override init() {
        super.init()
        checkPermissions()
    }
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setUp()
            return
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] status in
                if status {
                    self?.setUp()
                }
            }
        default:
            alert = true
            return
        }
    }
    
    func setUp() {
        do {
            self.session.beginConfiguration()
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
            let input = try AVCaptureDeviceInput(device: device!)
            if self.session.canAddInput(input) {
                self.session.addInput(input)
            }
            
            if self.session.canAddOutput(self.output) {
                self.session.addOutput(self.output)
            }
            
            self.session.commitConfiguration()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func takePicture() {
        DispatchQueue.global(qos: .background).async {
            self.output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
            DispatchQueue.main.async {
                withAnimation { self.isTaken = true }
            }
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) {
            self.capturedImage = image
        } else {
            print("Error: no image data found")
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    @ObservedObject var camera: CameraModel
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        camera.preview = AVCaptureVideoPreviewLayer(session: camera.session)
        camera.preview.frame = view.bounds
        camera.preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(camera.preview)
        camera.session.startRunning()
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        camera.preview.frame = uiView.bounds
    }
}

struct CameraPreviewMask: Shape {
    func path(in rect: CGRect) -> Path {
        let heightFraction: CGFloat = 0.3 // Adjust this value to change the height of the camera view
        let yOffset = (rect.height - (rect.height * heightFraction)) / 2
        let maskRect = CGRect(x: 0, y: yOffset, width: rect.width, height: rect.height * heightFraction)
        return Path(maskRect)
    }
}
