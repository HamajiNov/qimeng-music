Pod::Spec.new do |s|
  s.name             = 'QXPlayerKit'
  s.version          = '0.0.1'
  s.summary          = '启蒙乐谱 — KTV 播放器模块'
  s.description      = '实现 QXPlayerProtocol，AVPlayer + LRC 解析 + KTV 歌词同步播放。'
  s.homepage         = 'https://github.com/HamajiNov/qimeng-music'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'LX' => 'lx@mail.com' }
  s.source           = { :git => 'https://github.com/HamajiNov/qimeng-music.git', :tag => s.version.to_s }
  s.ios.deployment_target = '18.0'
  s.swift_versions = ['5.0']
  s.source_files = 'QXPlayerKit/Classes/**/*'
  s.dependency 'LXProtocol'
  s.dependency 'LXAnnotation'
  s.dependency 'QXMusicInterface'
  s.dependency 'QXMusicStore'
end
