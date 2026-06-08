//
//  QXProfileViewController.swift
//  QXMusicApp
//

import UIKit
import LXAnnotation
import QXMusicInterface

/// 设置页
final class QXProfileViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var cacheSize = ""
    private var scores: [QXScoreItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "我的"
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
        cacheSize = storage.cacheSizeFormatted
        scores = storage.loadScores()
        tableView.reloadData()
    }

    private func clearAll() {
        guard let storage = LXAnnotation.getInstance(
            forProtocolType: QXStorageProtocol.self) as? QXStorageProtocol else { return }
        for s in scores { try? storage.removeScore(s) }
        loadData()
    }
}

// MARK: - UITableViewDataSource

extension QXProfileViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "存储" : "关于"
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 2 : 2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var config = cell.defaultContentConfiguration()

        if indexPath.section == 0 {
            if indexPath.row == 0 {
                config.text = "缓存大小"
                config.secondaryText = cacheSize
            } else {
                config.text = "清除所有缓存"
                config.textProperties.color = .systemRed
            }
        } else {
            config.text = indexPath.row == 0 ? "版本" : "应用"
            config.secondaryText = indexPath.row == 0 ? "1.0.0" : "启蒙乐谱"
        }
        cell.contentConfiguration = config
        return cell
    }
}

// MARK: - UITableViewDelegate

extension QXProfileViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 && indexPath.row == 1 {
            let alert = UIAlertController(
                title: "确认清除",
                message: "将删除所有已下载的乐谱和音频文件，不可撤销。",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            alert.addAction(UIAlertAction(title: "确认清除", style: .destructive) { [weak self] _ in
                self?.clearAll()
            })
            present(alert, animated: true)
        }
    }
}
