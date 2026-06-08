//
//  QXScoreDetailViewController.swift
//  QXMusicApp
//

import UIKit
import LXAnnotation
import QXMusicInterface
import QXMusicStore
import QXScoreKit
import QXPlayerKit

/// 乐谱详情页：WKWebView 乐谱 + KTV 歌词 + 播放控制
final class QXScoreDetailViewController: UIViewController {

    private let score: QXScoreItem
    private var player: QXPlayerProtocol?
    private var renderer: QXSheetMusicRenderer?
    private var sheetView: QXSheetMusicView?
    private var lyricsView: QXKTVLyricsView?
    private var playbackBar: QXPlaybackBar?
    private var refreshTimer: Timer?

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
        refreshTimer?.invalidate()
        player?.stop()
    }

    // MARK: - Setup

    private func setupModules() {
        player = LXAnnotation.getInstance(
            forProtocolType: QXPlayerProtocol.self) as? QXPlayerProtocol
        renderer = LXAnnotation.getInstance(
            forProtocolType: QXScoreProtocol.self) as? QXSheetMusicRenderer

        player?.onStateChanged = { [weak self] in
            DispatchQueue.main.async { self?.refreshUI() }
        }
    }

    private func setupLayout() {
        guard let renderer, let player else { return }

        let sheetV = QXSheetMusicView(renderer: renderer)
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
        let musicxmlURL = QXScoreLibraryManager.shared.scoresDirectory
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
