Pod::Spec.new do |s|
  s.name             = 'QXScoreKit'
  s.version          = '0.0.1'
  s.summary          = '启蒙乐谱 — 乐谱渲染模块'
  s.description      = '实现 QXScoreProtocol，封装 alphaTab WebView 渲染 MusicXML 五线谱。'
  s.homepage         = 'https://github.com/HamajiNov/qimeng-music'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'LX' => 'lx@mail.com' }
  s.source           = { :git => 'https://github.com/HamajiNov/qimeng-music.git', :tag => s.version.to_s }
  s.ios.deployment_target = '18.0'
  s.swift_versions = ['5.0']
  s.source_files = 'QXScoreKit/Classes/**/*'
  s.dependency 'LXProtocol'
  s.dependency 'LXAnnotation'
  s.dependency 'QXMusicInterface'
end
