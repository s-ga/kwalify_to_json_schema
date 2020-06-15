Gem::Specification.new do |s|
  s.name = "kwalify_to_json_schema"
  s.version = "0.3.0"
  s.date = "2020-06-10"
  s.summary = "Kwalify schemas to JSON schemas conversion"
  s.description = "Allows to convert Kwalify schemas to JSON schemas"
  s.authors = ["Sylvain Gamot"]
  s.email = ""
  s.files = Dir.chdir(File.join(__dir__, "lib")) {
    Dir.glob("**/*.rb").map { |f| File.join("lib", f) }
  }
  s.bindir = "bin"
  s.executables << "kwalify_to_json_schema"
  s.homepage = "https://github.com/s-ga/kwalify_to_json_schema"
  s.license = "MIT"

  s.metadata = {
    "bug_tracker_uri" => "https://github.com/s-ga/kwalify_to_json_schema/issues",
    "source_code_uri" => "https://github.com/s-ga/kwalify_to_json_schema",
  }

  s.add_runtime_dependency "thor", "~>1.0"
  s.add_runtime_dependency "coderay", "~>1.0"
  s.add_development_dependency "kwalify", "~>0.7.2"
  s.add_development_dependency "json-schema", "~>2.0"
  s.add_development_dependency "rake", "~> 12.3.0"
end
