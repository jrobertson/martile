Gem::Specification.new do |s|
  s.name = 'martile'
  s.version = '0.1.10'
  s.summary = 'Converts a martile string to html'
  s.authors = ['James Robertson']
  s.files = Dir['lib/**/*.rb']
  s.add_dependency('rexle-builder')
  s.add_dependency('rexle')
  s.add_dependency('martile') 
  s.signing_key = '../privatekeys/martile.pem'
  s.cert_chain  = ['gem-public_cert.pem']
end
