//
//  QXPlayerManager.swift
//  QXPlayerKit
//

import AVFoundation
import LXProtocol
import LXAnnotation
import QXMusicInterface
import QXMusicStore

/// KTV 播放器 — 实现 QXPlayerProtocol
final class QXPlayerManager: NSObject, ObservableObject, QXPlayerProtocol {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var currentLyricIndex: Int = 0
    @Published var lyrics: [QXLRCLine] = []
    @Published var isLoading = false

    public var onStateChanged: (() -> Void)?

    private var player: AVPlayer?
    private var timeObserver: Any?

    public func load(score: QXScoreItem) async {
        isLoading = true

        // 加载 LRC
        let lrcURL = QXScoreLibraryManager.shared.scoresDirectory
            .appendingPathComponent(score.id).appendingPathComponent("lyrics.lrc")
        if let lrcText = try? String(contentsOf: lrcURL, encoding: .utf8) {
            lyrics = QXLRCParser.parse(lrcText)
        }

        // 加载 MP3
        let mp3URL = QXScoreLibraryManager.shared.scoresDirectory
            .appendingPathComponent(score.id).appendingPathComponent("audio.mp3")
        let item = AVPlayerItem(url: mp3URL)
        player = AVPlayer(playerItem: item)

        if let cmDuration = try? await item.asset.load(.duration) {
            duration = CMTimeGetSeconds(cmDuration)
        }

        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] t in
            guard let self else { return }
            let secs = CMTimeGetSeconds(t)
            self.currentTime = secs
            self.updateLyricIndex(for: secs)
            self.onStateChanged?()
        }

        isLoading = false
        onStateChanged?()
    }

    public func togglePlayPause() {
        guard let player else { return }
        if player.rate > 0 { player.pause(); isPlaying = false }
        else { player.play(); isPlaying = true }
        onStateChanged?()
    }

    public func seek(to time: TimeInterval) {
        let cm = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cm)
        currentTime = time
    }

    public func skipBackward(_ seconds: TimeInterval = 10) { seek(to: max(0, currentTime - seconds)) }
    public func skipForward(_ seconds: TimeInterval = 10) { seek(to: min(duration, currentTime + seconds)) }

    public func stop() {
        player?.pause()
        if let obs = timeObserver { player?.removeTimeObserver(obs) }
        timeObserver = nil; player = nil; isPlaying = false
    }

    private func updateLyricIndex(for time: TimeInterval) {
        guard !lyrics.isEmpty else { return }
        var lo = 0, hi = lyrics.count - 1
        while lo < hi {
            let mid = (lo + hi + 1) / 2
            if lyrics[mid].timestamp <= time { lo = mid } else { hi = mid - 1 }
        }
        if lyrics[lo].timestamp <= time { currentLyricIndex = lo }
    }

    public var formattedCurrentTime: String {
        let m = Int(currentTime) / 60, s = Int(currentTime) % 60
        return String(format: "%02d:%02d", m, s)
    }
    public var formattedDuration: String {
        let m = Int(duration) / 60, s = Int(duration) % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - LRC Parser

public enum QXLRCParser {
    public static func parse(_ content: String) -> [QXLRCLine] {
        var lines: [QXLRCLine] = []
        for raw in content.components(separatedBy: .newlines) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            guard line.contains("[") && line.contains("]") else { continue }
            guard let closeBracket = line.firstIndex(of: "]") else { continue }
            let timeStr = String(line[line.index(after: line.startIndex)..<closeBracket])
            let parts = timeStr.components(separatedBy: ":")
            guard parts.count == 2, let min = Double(parts[0]), let sec = Double(parts[1]) else { continue }
            let text = String(line[line.index(after: closeBracket)...])
            lines.append(QXLRCLine(timestamp: min * 60 + sec, text: text))
        }
        return lines.sorted { $0.timestamp < $1.timestamp }
    }
}

// MARK: - KTV Lyrics View (UIKit)

public final class QXKTVLyricsView: UIView {
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private var lineLabels: [UILabel] = []

    public var lyrics: [QXLRCLine] = [] {
        didSet { rebuildLabels() }
    }

    public var currentIndex: Int = 0 {
        didSet { updateHighlight() }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 32),
            stackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -32),
        ])
    }

    private func rebuildLabels() {
        lineLabels.forEach { $0.removeFromSuperview() }
        lineLabels.removeAll()

        // 顶部留白
        let topSpacer = UIView(); topSpacer.heightAnchor.constraint(equalToConstant: 60).isActive = true
        stackView.addArrangedSubview(topSpacer)

        for line in lyrics {
            let label = UILabel()
            label.text = line.text
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 16)
            label.textColor = .secondaryLabel
            label.numberOfLines = 0
            stackView.addArrangedSubview(label)
            lineLabels.append(label)
        }

        // 底部留白
        let bottomSpacer = UIView(); bottomSpacer.heightAnchor.constraint(equalToConstant: 100).isActive = true
        stackView.addArrangedSubview(bottomSpacer)
    }

    private func updateHighlight() {
        for (i, label) in lineLabels.enumerated() {
            let isActive = i == currentIndex
            UIView.animate(withDuration: 0.3) {
                label.font = isActive ? .boldSystemFont(ofSize: 20) : .systemFont(ofSize: 16)
                label.textColor = isActive ? .label : .secondaryLabel
                label.transform = isActive ? CGAffineTransform(scaleX: 1.1, y: 1.1) : CGAffineTransform(scaleX: 0.95, y: 0.95)
            }
        }

        guard currentIndex < lineLabels.count else { return }
        let targetLabel = lineLabels[currentIndex]
        let targetFrame = targetLabel.convert(targetLabel.bounds, to: scrollView)
        let offsetY = targetFrame.midY - scrollView.bounds.height / 2
        let maxOffset = scrollView.contentSize.height - scrollView.bounds.height
        scrollView.setContentOffset(CGPoint(x: 0, y: max(0, min(offsetY, maxOffset))), animated: true)
    }
}

// MARK: - Playback Bar (UIKit)

public final class QXPlaybackBar: UIView {
    public var player: QXPlayerProtocol? {
        didSet { startTimer() }
    }

    private let currentTimeLabel = UILabel()
    private let durationLabel = UILabel()
    private let slider = UISlider()
    private let playPauseButton = UIButton(type: .system)
    private let backwardButton = UIButton(type: .system)
    private let forwardButton = UIButton(type: .system)
    private var timer: Timer?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = .systemBackground.withAlphaComponent(0.9)

        [currentTimeLabel, durationLabel].forEach {
            $0.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
            $0.textColor = .secondaryLabel
            $0.text = "00:00"
        }

        let timeStack = UIStackView(arrangedSubviews: [currentTimeLabel, slider, durationLabel])
        timeStack.spacing = 8; timeStack.alignment = .center

        backwardButton.setImage(UIImage(systemName: "gobackward.10"), for: .normal)
        forwardButton.setImage(UIImage(systemName: "goforward.10"), for: .normal)
        playPauseButton.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        playPauseButton.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 48), forImageIn: .normal)

        backwardButton.addTarget(self, action: #selector(didTapBackward), for: .touchUpInside)
        forwardButton.addTarget(self, action: #selector(didTapForward), for: .touchUpInside)
        playPauseButton.addTarget(self, action: #selector(didTapPlayPause), for: .touchUpInside)
        slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)

        let btnStack = UIStackView(arrangedSubviews: [backwardButton, playPauseButton, forwardButton])
        btnStack.spacing = 40; btnStack.alignment = .center; btnStack.distribution = .equalCentering

        let vStack = UIStackView(arrangedSubviews: [timeStack, btnStack])
        vStack.axis = .vertical; vStack.spacing = 8
        vStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(vStack)
        NSLayoutConstraint.activate([
            vStack.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            vStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            vStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            vStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
        ])
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            guard let self, let p = self.player else { return }
            self.currentTimeLabel.text = self.format(p.currentTime)
            self.durationLabel.text = self.format(p.duration)
            if !self.slider.isTracking {
                self.slider.maximumValue = Float(max(p.duration, 0.1))
                self.slider.value = Float(p.currentTime)
            }
            let icon = p.isPlaying ? "pause.circle.fill" : "play.circle.fill"
            self.playPauseButton.setImage(UIImage(systemName: icon), for: .normal)
        }
    }

    @objc private func didTapPlayPause() { player?.togglePlayPause() }
    @objc private func didTapBackward() { player?.skipBackward(10) }
    @objc private func didTapForward() { player?.skipForward(10) }
    @objc private func sliderChanged() { player?.seek(to: TimeInterval(slider.value)) }

    private func format(_ t: TimeInterval) -> String {
        let m = Int(t) / 60, s = Int(t) % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - LXProtocol 模块注册

@objc class QXPlayerKitModule: NSObject, LXProtocol {
    @objc class func swift_priority() -> LXPriority { LXPriorityMedium }
    @objc class func swift_load() {
        LXAnnotation.register(
            instance: QXPlayerManager(),
            forProtocolType: QXPlayerProtocol.self
        )
    }
}
