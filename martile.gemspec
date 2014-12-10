Gem::Specification.new do |s|
  s.name = 'martile'
  s.version = '0.4.1'
  s.summary = 'Converts a martile string to html'
  s.authors = ['James Robertson']
  s.files = Dir['lib/**/*.rb']
  s.add_runtime_dependency('rexle-builder', '~> 0.1', '>=0.1.9')
  s.add_runtime_dependency('rexle', '~> 1.0', '>=1.0.33')
  s.add_runtime_dependency('rdiscount', '~> 2.1', '>=2.1.7.1')
  s.add_runtime_dependency('dynarex', '~> 1.2', '>=1.2.90')
  s.signing_key = '../privatekeys/martile.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@r0bertson.co.uk'
  s.homepage = 'https://github.com/jrobertson/martile'
  s.required_ruby_version = '>= 2.1.0'
end
