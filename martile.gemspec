Gem::Specification.new do |s|
  s.name = 'martile'
  s.version = '0.7.2'
  s.summary = 'Martile is a Markdown pre formatter which is designed to format custom Markdown tags prior to being passed to the Markdown gem.'
  s.authors = ['James Robertson']
  s.files = Dir['lib/martile.rb']
  s.add_runtime_dependency('rdiscount', '~> 2.2', '>=2.2.0.1')
  s.add_runtime_dependency('dynarex', '~> 1.7', '>=1.7.24')
  s.add_runtime_dependency('kvx', '~> 0.6', '>=0.6.4')
  s.signing_key = '../privatekeys/martile.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@jamesrobertson.eu'
  s.homepage = 'https://github.com/jrobertson/martile'
  s.required_ruby_version = '>= 2.1.0'
end
