Pod::Spec.new do |s|
  s.name             = 'QXMusicInterface'
  s.version          = '0.0.1'
  s.summary          = '启蒙乐谱 — 纯协议定义层，零实现代码'
  s.description      = '定义 QXScoreProtocol、QXPlayerProtocol、QXScanProtocol、QXStorageProtocol。所有协议继承 LXAnnotationProtocol，通过 LXAnnotation 注册/发现。'
  s.homepage         = 'https://github.com/HamajiNov/qimeng-music'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'LX' => 'lx@mail.com' }
  s.source           = { :git => 'https://github.com/HamajiNov/qimeng-music.git', :tag => s.version.to_s }
  s.ios.deployment_target = '18.0'
  s.swift_versions = ['5.0']
  s.source_files = 'QXMusicInterface/Classes/**/*'
  s.dependency 'LXAnnotation'
end
