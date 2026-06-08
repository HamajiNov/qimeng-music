//
//  QXLibraryViewController.swift
//  QXMusicApp
//

import UIKit
import LXAnnotation
import QXMusicInterface

/// 乐谱库列表页
final class QXLibraryViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var scores: [QXScoreItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "我的乐谱"
        view.backgroundColor = .systemBackground

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }

    private func loadData() {
        guard let storage = LXAnnotation.getInstance(
            forProtocolType: QXStorageProtocol.self) as? QXStorageProtocol else { return }
        scores = storage.loadScores()
        tableView.reloadData()
    }

    private func removeScore(at index: Int) {
        guard let storage = LXAnnotation.getInstance(
            forProtocolType: QXStorageProtocol.self) as? QXStorageProtocol else { return }
        try? storage.removeScore(scores[index])
        scores.remove(at: index)
    }
}

// MARK: - UITableViewDataSource

extension QXLibraryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        scores.isEmpty ? 1 : scores.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if scores.isEmpty {
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            var config = UIListContentConfiguration.cell()
            config.text = "还没有乐谱"
            config.secondaryText = "切换到「拍照识别」标签页拍摄你的第一份乐谱"
            config.image = UIImage(systemName: "music.note.list")
            config.imageProperties.tintColor = .secondaryLabel
            config.textProperties.alignment = .center
            config.secondaryTextProperties.alignment = .center
            cell.contentConfiguration = config
            cell.selectionStyle = .none
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let score = scores[indexPath.row]
        var config = cell.defaultContentConfiguration()
        config.text = score.title
        config.secondaryText = score.artist
        config.image = UIImage(systemName: "music.note")
        config.imageProperties.tintColor = .systemBlue
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete, !scores.isEmpty else { return }
        removeScore(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
        if scores.isEmpty { tableView.reloadData() }
    }
}

// MARK: - UITableViewDelegate

extension QXLibraryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !scores.isEmpty else { return }
        let detail = QXScoreDetailViewController(score: scores[indexPath.row])
        navigationController?.pushViewController(detail, animated: true)
    }
}
