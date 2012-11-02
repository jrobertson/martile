Gem::Specification.new do |s|
  s.name = 'martile'
  s.version = '0.1.9'
  s.summary = 'Converts a martile string to html'
  s.authors = ['James Robertson']
  s.files = Dir['lib/**/*.rb']
  s.add_dependency('rexle-builder')
  s.add_dependency('rexle')
  s.add_dependency('martile')
end
