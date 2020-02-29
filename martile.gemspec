Gem::Specification.new do |s|
  s.name = 'martile'
  s.version = '1.4.1'
  s.summary = 'Martile is a Markdown pre formatter which is designed to ' + 
      'format custom Markdown tags prior to being passed to the Markdown gem.'
  s.authors = ['James Robertson']
  s.files = Dir['lib/martile.rb']
  s.add_runtime_dependency('yatoc', '~> 0.3', '>=0.3.5')  
  s.add_runtime_dependency('rqrcode', '~> 1.1', '>=1.1.2')  
  s.add_runtime_dependency('mindmapdoc', '~> 0.3', '>=0.3.7')
  s.add_runtime_dependency('flowchartviz', '~> 0.1', '>=0.1.6')
  s.add_runtime_dependency('jsmenubuilder', '~> 0.2', '>=0.2.10')
  s.add_runtime_dependency('jstreebuilder', '~> 0.2', '>=0.2.2')
  s.add_runtime_dependency('htmlcom', '~> 0.2', '>=0.2.0')
  s.signing_key = '../privatekeys/martile.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@jamesrobertson.eu'
  s.homepage = 'https://github.com/jrobertson/martile'
  s.required_ruby_version = '>= 2.1.0'
end
