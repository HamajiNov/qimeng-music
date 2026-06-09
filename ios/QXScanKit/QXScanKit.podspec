Pod::Spec.new do |s|
  s.name             = 'QXScanKit'
  s.version          = '0.0.1'
  s.summary          = '启蒙乐谱 — 拍照扫描模块'
  s.description      = '实现 QXScanProtocol，相机/相册调用 + 上传识别 + 结果下载。'
  s.homepage         = 'https://github.com/HamajiNov/qimeng-music'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'LX' => 'lx@mail.com' }
  s.source           = { :git => 'https://github.com/HamajiNov/qimeng-music.git', :tag => s.version.to_s }
  s.ios.deployment_target = '18.0'
  s.swift_versions = ['5.0']
  s.source_files = 'QXScanKit/Classes/**/*'
  s.dependency 'LXProtocol'
  s.dependency 'LXAnnotation'
  s.dependency 'QXMusicInterface'
end
