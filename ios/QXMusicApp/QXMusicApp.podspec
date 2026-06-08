Pod::Spec.new do |s|
  s.name             = 'QXMusicApp'
  s.version          = '0.0.1'
  s.summary          = '启蒙乐谱 — 主工程（页面 + 组装）'
  s.description      = 'Tab 页面结构 + 路由，通过 LXAnnotation 组装各业务模块。'
  s.homepage         = 'https://github.com/HamajiNov/qimeng-music'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'LX' => 'lx@mail.com' }
  s.source           = { :git => 'https://github.com/HamajiNov/qimeng-music.git', :tag => s.version.to_s }
  s.ios.deployment_target = '18.0'
  s.swift_versions = ['5.0']
  s.source_files = 'QXMusicApp/Classes/**/*'
  s.dependency 'LXProtocol'
  s.dependency 'LXAnnotation'
  s.dependency 'LXFoundation'
  s.dependency 'QXMusicInterface'
  s.dependency 'QXMusicStore'
  s.dependency 'QXScoreKit'
  s.dependency 'QXPlayerKit'
  s.dependency 'QXScanKit'
end
