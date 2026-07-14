import SwiftUI
import AVFoundation

struct BarcodeScannerView: UIViewControllerRepresentable {
    var onScan: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onScan: onScan) }

    func makeUIViewController(context: Context) -> ScannerVC {
        let vc = ScannerVC()
        vc.delegate = context.coordinator
        return vc
    }
    func updateUIViewController(_ vc: ScannerVC, context: Context) {}
}

// MARK: - Coordinator

extension BarcodeScannerView {
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var onScan: (String) -> Void
        var didScan = false

        init(onScan: @escaping (String) -> Void) { self.onScan = onScan }

        func metadataOutput(_ output: AVCaptureMetadataOutput,
                            didOutput objects: [AVMetadataObject],
                            from connection: AVCaptureConnection) {
            guard !didScan,
                  let obj = objects.first as? AVMetadataMachineReadableCodeObject,
                  let code = obj.stringValue else { return }
            didScan = true
            DispatchQueue.main.async {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                self.onScan(code)
            }
        }
    }
}

// MARK: - Camera VC

class ScannerVC: UIViewController {
    weak var delegate: AVCaptureMetadataOutputObjectsDelegate?

    private var session: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupSession()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session?.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session?.stopRunning()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    private func setupSession() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .denied || status == .restricted {
            showPermissionDenied(); return
        }
        if status == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted { self?.configureCapture() }
                    else { self?.showPermissionDenied() }
                }
            }
            return
        }
        configureCapture()
    }

    private func configureCapture() {
        let session = AVCaptureSession()
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
                        ?? AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            showError("Camera not available."); return
        }
        session.addInput(input)

        // Barcodes are held close to the lens; restricting autofocus to the
        // near range makes focus lock much faster (blurry frames never decode).
        if (try? device.lockForConfiguration()) != nil {
            if device.isAutoFocusRangeRestrictionSupported {
                device.autoFocusRangeRestriction = .near
            }
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            device.unlockForConfiguration()
        }

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { showError("Capture error."); return }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(delegate, queue: .main)
        output.metadataObjectTypes = [.ean13, .ean8, .upce, .code128, .code39, .itf14, .qr]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.addSublayer(preview)
        self.previewLayer = preview
        self.session = session

        addOverlay()

        DispatchQueue.global(qos: .userInitiated).async { session.startRunning() }
    }

    private func addOverlay() {
        // Viewfinder frame
        let size: CGFloat = 240
        let frame = CGRect(
            x: (view.bounds.width - size) / 2,
            y: (view.bounds.height - size) / 2 - 40,
            width: size, height: size
        )
        let box = UIView(frame: frame)
        box.layer.borderColor = UIColor(red: 0.3, green: 0.69, blue: 0.31, alpha: 1).cgColor
        box.layer.borderWidth = 2
        box.layer.cornerRadius = 12
        view.addSubview(box)

        let label = UILabel()
        label.text = "Point at a barcode"
        label.textColor = .white
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textAlignment = .center
        label.frame = CGRect(x: 0, y: frame.maxY + 20, width: view.bounds.width, height: 30)
        view.addSubview(label)

        // Close button
        let closeBtn = UIButton(type: .system)
        closeBtn.setTitle("Cancel", for: .normal)
        closeBtn.setTitleColor(.white, for: .normal)
        closeBtn.frame = CGRect(x: 0, y: view.bounds.height - 80, width: view.bounds.width, height: 44)
        closeBtn.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeBtn)
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    private func showPermissionDenied() {
        showError("Camera access denied. Enable it in Settings → Privacy → Camera.")
    }

    private func showError(_ msg: String) {
        let label = UILabel()
        label.text = msg
        label.textColor = .white
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 15)
        label.frame = CGRect(x: 20, y: 0, width: view.bounds.width - 40, height: view.bounds.height)
        view.addSubview(label)

        let btn = UIButton(type: .system)
        btn.setTitle("Close", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.frame = CGRect(x: 0, y: view.bounds.height - 80, width: view.bounds.width, height: 44)
        btn.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(btn)
    }
}
