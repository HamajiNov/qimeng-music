//
//  QXScanViewController.swift
//  QXMusicApp
//

import UIKit
import LXAnnotation
import QXMusicInterface

/// 拍照识别页
final class QXScanViewController: UIViewController {

    private var selectedImage: UIImage?
    private var scanState: QXScanState = .idle
    private var errorMessage: String?

    // MARK: - UI Elements

    private let cameraIcon = UIImageView(image: UIImage(systemName: "camera.viewfinder"))
    private let titleLabel = UILabel()
    private let cameraButton = UIButton(type: .system)
    private let albumButton = UIButton(type: .system)
    private let imagePreview = UIImageView()
    private let confirmLabel = UILabel()
    private let retakeButton = UIButton(type: .system)
    private let recognizeButton = UIButton(type: .system)
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let statusLabel = UILabel()
    private let cancelButton = UIButton(type: .system)
    private let errorLabel = UILabel()

    private let idleStack = UIStackView()
    private let previewStack = UIStackView()
    private let progressStack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "拍照识别"
        view.backgroundColor = .systemBackground
        setupIdleUI()
        setupPreviewUI()
        setupProgressUI()
        renderState()
    }

    // MARK: - Setup

    private func setupIdleUI() {
        cameraIcon.contentMode = .scaleAspectFit
        cameraIcon.tintColor = .systemBlue
        cameraIcon.heightAnchor.constraint(equalToConstant: 80).isActive = true

        titleLabel.text = "拍摄或选择乐谱照片"
        titleLabel.font = UIFont.preferredFont(forTextStyle: .title2)
        titleLabel.textAlignment = .center

        cameraButton.setTitle("拍照", for: .normal)
        cameraButton.setImage(UIImage(systemName: "camera.fill"), for: .normal)
        cameraButton.addTarget(self, action: #selector(openCamera), for: .touchUpInside)

        albumButton.setTitle("从相册选择", for: .normal)
        albumButton.setImage(UIImage(systemName: "photo.on.rectangle"), for: .normal)
        albumButton.addTarget(self, action: #selector(openAlbum), for: .touchUpInside)

        idleStack.axis = .vertical; idleStack.spacing = 24; idleStack.alignment = .center
        idleStack.translatesAutoresizingMaskIntoConstraints = false
        idleStack.addArrangedSubview(UIView()) // spacer
        idleStack.addArrangedSubview(cameraIcon)
        idleStack.addArrangedSubview(titleLabel)
        idleStack.addArrangedSubview(cameraButton)
        idleStack.addArrangedSubview(albumButton)
        idleStack.addArrangedSubview(UIView()) // spacer
        view.addSubview(idleStack)
        NSLayoutConstraint.activate([
            idleStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            idleStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            idleStack.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
        ])
    }

    private func setupPreviewUI() {
        imagePreview.contentMode = .scaleAspectFit
        imagePreview.clipsToBounds = true; imagePreview.layer.cornerRadius = 12

        confirmLabel.text = "确认使用此图片？"
        confirmLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        confirmLabel.textAlignment = .center

        retakeButton.setTitle("重新选择", for: .normal)
        retakeButton.addTarget(self, action: #selector(retakeImage), for: .touchUpInside)

        recognizeButton.setTitle("开始识别", for: .normal)
        recognizeButton.addTarget(self, action: #selector(startRecognition), for: .touchUpInside)

        errorLabel.font = UIFont.preferredFont(forTextStyle: .callout)
        errorLabel.textColor = .systemRed
        errorLabel.numberOfLines = 0; errorLabel.textAlignment = .center

        previewStack.axis = .vertical; previewStack.spacing = 16; previewStack.alignment = .center
        previewStack.translatesAutoresizingMaskIntoConstraints = false
        previewStack.addArrangedSubview(imagePreview)
        previewStack.addArrangedSubview(confirmLabel)
        previewStack.addArrangedSubview(retakeButton)
        previewStack.addArrangedSubview(recognizeButton)
        previewStack.addArrangedSubview(errorLabel)
        previewStack.isHidden = true
        view.addSubview(previewStack)
        NSLayoutConstraint.activate([
            previewStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            previewStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            previewStack.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.85),
        ])
    }

    private func setupProgressUI() {
        statusLabel.font = UIFont.preferredFont(forTextStyle: .body)
        statusLabel.textColor = .secondaryLabel
        statusLabel.numberOfLines = 0; statusLabel.textAlignment = .center

        cancelButton.setTitle("取消", for: .normal)
        cancelButton.setTitleColor(.systemRed, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelScan), for: .touchUpInside)

        progressStack.axis = .vertical; progressStack.spacing = 24; progressStack.alignment = .center
        progressStack.translatesAutoresizingMaskIntoConstraints = false
        progressStack.addArrangedSubview(progressView)
        progressStack.addArrangedSubview(statusLabel)
        progressStack.addArrangedSubview(cancelButton)
        progressStack.isHidden = true
        view.addSubview(progressStack)
        NSLayoutConstraint.activate([
            progressStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            progressStack.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
        ])
    }

    // MARK: - State

    private func renderState() {
        idleStack.isHidden = true
        previewStack.isHidden = true
        progressStack.isHidden = true

        switch scanState {
        case .idle:
            if selectedImage == nil {
                idleStack.isHidden = false
                errorLabel.isHidden = true
            } else {
                previewStack.isHidden = false
                errorLabel.text = errorMessage
                errorLabel.isHidden = errorMessage?.isEmpty ?? true
            }

        case .uploading, .waiting, .downloading:
            progressStack.isHidden = false
            progressView.progress = Float(getProgressValue())
            statusLabel.text = statusText(for: scanState)

        case .completed:
            idleStack.isHidden = false

        case .failed(let msg):
            errorLabel.text = msg; errorLabel.isHidden = false
            idleStack.isHidden = false
        }
    }

    private func getProgressValue() -> Double {
        guard let scanner = LXAnnotation.getInstance(
            forProtocolType: QXScanProtocol.self) as? QXScanProtocol else { return 0 }
        return scanner.progress
    }

    private func statusText(for state: QXScanState) -> String {
        switch state {
        case .uploading: return "正在上传图片..."
        case .waiting(let id): return "正在识别乐谱...\n\(id.prefix(8))..."
        case .downloading: return "正在下载结果..."
        default: return ""
        }
    }

    // MARK: - Actions

    @objc private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }
        let picker = UIImagePickerController()
        picker.sourceType = .camera; picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func openAlbum() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary; picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func retakeImage() {
        selectedImage = nil
        scanState = .idle
        errorMessage = nil
        renderState()
    }

    @objc private func startRecognition() {
        guard let img = selectedImage,
              let data = img.jpegData(compressionQuality: 0.85),
              let scanner = LXAnnotation.getInstance(
                forProtocolType: QXScanProtocol.self) as? QXScanProtocol else { return }

        scanner.onStateChanged = { [weak self] in
            DispatchQueue.main.async {
                guard let self else { return }
                self.scanState = scanner.state
                self.progressView.progress = Float(scanner.progress)
                self.renderState()

                if case .completed(let item) = scanner.state {
                    let detail = QXScoreDetailViewController(score: item)
                    self.navigationController?.pushViewController(detail, animated: true)
                    self.resetState()
                }
                if case .failed(let msg) = scanner.state {
                    self.errorMessage = msg
                    self.scanState = .idle
                    self.renderState()
                }
            }
        }

        scanState = .uploading
        renderState()
        Task { try? await scanner.recognize(imageData: data) }
    }

    @objc private func cancelScan() {
        resetState()
        renderState()
    }

    private func resetState() {
        selectedImage = nil
        scanState = .idle
        errorMessage = nil
        guard let scanner = LXAnnotation.getInstance(
            forProtocolType: QXScanProtocol.self) as? QXScanProtocol else { return }
        scanner.onStateChanged = nil
    }
}

// MARK: - UIImagePickerControllerDelegate

extension QXScanViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let img = info[.originalImage] as? UIImage {
            selectedImage = img
            imagePreview.image = img
            scanState = .idle
            renderState()
        }
        picker.dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
