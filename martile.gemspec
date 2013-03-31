Gem::Specification.new do |s|
  s.name = 'martile'
  s.version = '0.1.12'
  s.summary = 'Converts a martile string to html'
  s.authors = ['James Robertson']
  s.files = Dir['lib/**/*.rb']
  s.add_dependency('rexle-builder')
  s.add_dependency('rexle')
  s.add_dependency('rdiscount')
  s.signing_key = '../privatekeys/martile.pem'
  s.cert_chain  = ['gem-public_cert.pem']
end
