Gem::Specification.new do |s|
  s.name = "kwalify_to_json_schema"
  s.version = "0.0.0"
  s.date = "2020-06-10"
  s.summary = "Kwalify schemas to JSON schemas conversion"
  s.description = "Allows to convert Kwalify schemas to JSON schemas Draft 7"
  s.authors = ["Sylvain Gamot"]
  s.email = ""
  s.files = Dir.glob(File.join(__dir__, "**/*.rb"))
  s.bindir = "bin"
  s.executables << "kwalify_to_json_schema"
  s.homepage = "https://rubygems.org/gems/kwalify_to_json_schema"
  s.license = "MIT"

  s.add_runtime_dependency "thor", "~>1.0"
  s.add_runtime_dependency "coderay", "~>1.0"
  s.add_development_dependency "kwalify", "~>0.7.2"
  s.add_development_dependency "json-schema", "~>2.0"
  s.add_development_dependency "rake", "~> 12.3.0"
end
