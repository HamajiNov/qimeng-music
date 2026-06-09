//
//  QXScoreDetailViewController.swift
//  QXMusicApp
//

import UIKit
import LXAnnotation
import QXMusicInterface

/// 乐谱详情页：WKWebView 乐谱 + KTV 歌词 + 播放控制
final class QXScoreDetailViewController: UIViewController {

    private let score: QXScoreItem
    private var player: QXPlayerProtocol?
    private var renderer: QXScoreProtocol?
    private var sheetView: UIView?
    private var lyricsView: QXKTVLyricsView?
    private var playbackBar: QXPlaybackBar?

    init(score: QXScoreItem) {
        self.score = score
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = score.title
        view.backgroundColor = .systemBackground
        setupModules()
        setupLayout()
        startLoading()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player?.stop()
    }

    // MARK: - Setup

    private func setupModules() {
        player = LXAnnotation.getInstance(
            forProtocolType: QXPlayerProtocol.self) as? QXPlayerProtocol
        renderer = LXAnnotation.getInstance(
            forProtocolType: QXScoreProtocol.self) as? QXScoreProtocol

        player?.onStateChanged = { [weak self] in
            DispatchQueue.main.async { self?.refreshUI() }
        }
    }

    private func setupLayout() {
        guard let renderer, let player else { return }

        let sheetV = renderer.makeScoreView()
        let lyricsV = QXKTVLyricsView()
        let bar = QXPlaybackBar()
        bar.player = player

        [sheetV, lyricsV, bar].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            sheetV.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            sheetV.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sheetV.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sheetV.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.45),

            lyricsV.topAnchor.constraint(equalTo: sheetV.bottomAnchor, constant: 4),
            lyricsV.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            lyricsV.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            lyricsV.heightAnchor.constraint(equalToConstant: 180),

            bar.topAnchor.constraint(equalTo: lyricsV.bottomAnchor, constant: 4),
            bar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])

        self.sheetView = sheetV
        self.lyricsView = lyricsV
        self.playbackBar = bar
    }

    private func startLoading() {
        guard let renderer, let player else { return }
        guard let storage = LXAnnotation.getInstance(
            forProtocolType: QXStorageProtocol.self
        ) as? QXStorageProtocol else { return }

        let musicxmlURL = storage.scoresDirectory
            .appendingPathComponent(score.id).appendingPathComponent("score.musicxml")
        renderer.loadMusicXML(url: musicxmlURL)

        Task {
            await player.load(score: score)
            DispatchQueue.main.async { [weak self] in
                self?.lyricsView?.lyrics = player.lyrics
            }
        }
    }

    private func refreshUI() {
        guard let player else { return }
        lyricsView?.currentIndex = player.currentLyricIndex
    }
}

// MARK: - KTV Lyrics View

private final class QXKTVLyricsView: UIView {
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private var lineLabels: [UILabel] = []

    var lyrics: [QXLRCLine] = [] {
        didSet { rebuildLabels() }
    }

    var currentIndex: Int = 0 {
        didSet { updateHighlight() }
    }

    override init(frame: CGRect) {
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
        stackView.arrangedSubviews.forEach {
            stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        lineLabels.removeAll()

        let topSpacer = UIView()
        topSpacer.heightAnchor.constraint(equalToConstant: 60).isActive = true
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

        let bottomSpacer = UIView()
        bottomSpacer.heightAnchor.constraint(equalToConstant: 100).isActive = true
        stackView.addArrangedSubview(bottomSpacer)
        updateHighlight()
    }

    private func updateHighlight() {
        for (index, label) in lineLabels.enumerated() {
            let isActive = index == currentIndex
            UIView.animate(withDuration: 0.2) {
                label.font = isActive ? .boldSystemFont(ofSize: 20) : .systemFont(ofSize: 16)
                label.textColor = isActive ? .label : .secondaryLabel
                label.transform = isActive ? CGAffineTransform(scaleX: 1.08, y: 1.08) : .identity
            }
        }

        guard currentIndex < lineLabels.count else { return }
        let targetLabel = lineLabels[currentIndex]
        let targetFrame = targetLabel.convert(targetLabel.bounds, to: scrollView)
        let offsetY = targetFrame.midY - scrollView.bounds.height / 2
        let maxOffset = max(0, scrollView.contentSize.height - scrollView.bounds.height)
        scrollView.setContentOffset(CGPoint(x: 0, y: max(0, min(offsetY, maxOffset))), animated: true)
    }
}

// MARK: - Playback Bar

private final class QXPlaybackBar: UIView {
    var player: QXPlayerProtocol? {
        didSet { startTimer() }
    }

    private let currentTimeLabel = UILabel()
    private let durationLabel = UILabel()
    private let slider = UISlider()
    private let playPauseButton = UIButton(type: .system)
    private let backwardButton = UIButton(type: .system)
    private let forwardButton = UIButton(type: .system)
    private var timer: Timer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        timer?.invalidate()
    }

    private func setupViews() {
        backgroundColor = .systemBackground.withAlphaComponent(0.9)

        [currentTimeLabel, durationLabel].forEach {
            $0.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
            $0.textColor = .secondaryLabel
            $0.text = "00:00"
        }

        let timeStack = UIStackView(arrangedSubviews: [currentTimeLabel, slider, durationLabel])
        timeStack.spacing = 8
        timeStack.alignment = .center

        backwardButton.setImage(UIImage(systemName: "gobackward.10"), for: .normal)
        forwardButton.setImage(UIImage(systemName: "goforward.10"), for: .normal)
        playPauseButton.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        playPauseButton.setPreferredSymbolConfiguration(
            UIImage.SymbolConfiguration(pointSize: 48),
            forImageIn: .normal
        )

        backwardButton.addTarget(self, action: #selector(didTapBackward), for: .touchUpInside)
        forwardButton.addTarget(self, action: #selector(didTapForward), for: .touchUpInside)
        playPauseButton.addTarget(self, action: #selector(didTapPlayPause), for: .touchUpInside)
        slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)

        let buttonStack = UIStackView(arrangedSubviews: [backwardButton, playPauseButton, forwardButton])
        buttonStack.spacing = 40
        buttonStack.alignment = .center
        buttonStack.distribution = .equalCentering

        let contentStack = UIStackView(arrangedSubviews: [timeStack, buttonStack])
        contentStack.axis = .vertical
        contentStack.spacing = 8
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
        ])
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            guard let self, let player = self.player else { return }
            self.currentTimeLabel.text = self.format(player.currentTime)
            self.durationLabel.text = self.format(player.duration)
            if !self.slider.isTracking {
                self.slider.maximumValue = Float(max(player.duration, 0.1))
                self.slider.value = Float(player.currentTime)
            }
            let icon = player.isPlaying ? "pause.circle.fill" : "play.circle.fill"
            self.playPauseButton.setImage(UIImage(systemName: icon), for: .normal)
        }
    }

    @objc private func didTapPlayPause() { player?.togglePlayPause() }
    @objc private func didTapBackward() { player?.skipBackward(10) }
    @objc private func didTapForward() { player?.skipForward(10) }
    @objc private func sliderChanged() { player?.seek(to: TimeInterval(slider.value)) }

    private func format(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
