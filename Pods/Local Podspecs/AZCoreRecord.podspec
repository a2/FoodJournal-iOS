Pod::Spec.new do |s|
  s.name     = 'AZCoreRecord'
  s.version   = '1.0'
  s.license  = 'MIT'
  s.summary  = 'Effortless fetching, saving, importing , and ubiquity for Core Data.'
  s.homepage = 'http://github.com/zwaldowski/AZCoreRecord'
  s.author   = { 'Zachary Waldowski' => 'zwaldowski@gmail.com',
		  'Alexsander Akers' => 'a2@pandamonia.us' }
  s.source   = { :git => 'https://github.com/zwaldowski/AZCoreRecord.git', :commit => 'origin/master' }
  s.source_files = 'AZCoreRecord'
  s.framework    = 'CoreData'
  s.requires_arc = true
  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.7'
end
