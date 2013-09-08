# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{dm-is-slug}
  s.version = "1.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Aaron Qian", "James Herdman", "Nik Radford", "Paul", "Mike Frawley", "Alexander Mankuta"]
  s.date = %q{2010-10-28}
  s.description = %q{DataMapper plugin that generates unique slugs}
  s.email = ["aq1018@gmail.com", "james.herdman@gmail.com", "nik [a] terminaldischarge [d] net", "maverick.stoklosa@gmail.com", "frawl021@gmail.com", "cheba+github@pointlessone.org"]
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc",
     "TODO"
  ]
  s.files = [
    ".gitignore",
     "Gemfile",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "TODO",
     "VERSION",
     "dm-is-slug.gemspec",
     "lib/dm-is-slug.rb",
     "lib/dm-is-slug/is/slug.rb",
     "spec/integration/slug_spec.rb",
     "spec/rcov.opts",
     "spec/spec.opts",
     "spec/spec_helper.rb",
     "tasks/ci.rake",
     "tasks/local_gemfile.rake",
     "tasks/metrics.rake",
     "tasks/spec.rake",
     "tasks/yard.rake",
     "tasks/yardstick.rake"
  ]
  s.homepage = %q{http://github.com/aq1018/dm-is-slug}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{DataMapper plugin that generates unique slugs}
  s.test_files = [
    "spec/integration/slug_spec.rb",
     "spec/spec_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3
  end

  s.add_dependency(%q<dm-core>, ["~> 1.1"])
  s.add_dependency(%q<dm-validations>, ["~> 1.1"])
  s.add_dependency(%q<unidecode>, ["~> 1.1.1"])
  s.add_dependency(%q<rspec>, ["~> 1.3"])

end

