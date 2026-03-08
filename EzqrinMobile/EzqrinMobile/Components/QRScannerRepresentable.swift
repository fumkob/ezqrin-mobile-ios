import AVFoundation
import SwiftUI

struct QRScannerRepresentable: UIViewControllerRepresentable {
    let onCodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.onCodeScanned = onCodeScanned
        return controller
    }

    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {
        uiViewController.onCodeScanned = onCodeScanned
    }
}

final class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCodeScanned: ((String) -> Void)?

    private static let scanCooldownInterval: TimeInterval = 3.0
    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var lastScannedCode: String?
    private var cooldownTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startScanning()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopScanning()
        cooldownTimer?.invalidate()
        cooldownTimer = nil
    }

    private func setupCamera() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        let output = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.qr]
        }

        let layer = AVCaptureVideoPreviewLayer(session: captureSession)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.layer.bounds
        view.layer.addSublayer(layer)
        previewLayer = layer
    }

    func startScanning() {
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
            }
        }
    }

    func stopScanning() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    /// Resets the cooldown after a scan, allowing the next QR code to be read
    func resetForNextScan() {
        lastScannedCode = nil
    }

    // MARK: - AVCaptureMetadataOutputObjectsDelegate

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let metadata = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              metadata.type == .qr,
              let code = metadata.stringValue else {
            return
        }

        // Prevent consecutive scanning of the same code
        guard code != lastScannedCode else { return }
        lastScannedCode = code

        // Reset after 3 seconds (allows re-scanning the same QR code)
        cooldownTimer?.invalidate()
        cooldownTimer = Timer.scheduledTimer(withTimeInterval: Self.scanCooldownInterval, repeats: false) { [weak self] _ in
            self?.lastScannedCode = nil
        }

        onCodeScanned?(code)
    }
}
