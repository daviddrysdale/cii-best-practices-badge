task(:default).clear.enhance %w(
  rbenv_rvm_setup
  bundle
  bundle_audit
  test
  rubocop
  markdownlint
  rails_best_practices
  brakeman
  license_check
  whitespace_check
)

# Simple smoke test to avoid development environment misconfiguration
desc 'Ensure that rbenv or rvm are set up in PATH'
task :rbenv_rvm_setup do
  path = ENV['PATH']
  if !path.include?('.rbenv') && !path.include?('.rvm')
    fail 'Must have rbenv or rvm in PATH'
  end
end

desc 'Run Rubocop with options'
task :rubocop do
  sh 'bundle exec rubocop -D --format offenses --format progress || true'
end

desc 'Run rails_best_practices with options'
task :rails_best_practices do
  sh 'bundle exec rails_best_practices ' \
      '--features --spec --without-color || true'
end

desc 'Run brakeman'
task :brakeman do
  sh 'bundle exec brakeman --quiet || true'
end

desc 'Run bundle if needed'
task :bundle do
  sh 'bundle check || bundle install'
end

desc 'Run bundle-audit - check for known vulnerabilities in dependencies'
task :bundle_audit do
  sh 'bundle exec bundle-audit update && bundle exec bundle-audit check'
end

desc 'Run markdownlint (mdl) - check for markdown problems'
task :markdownlint do
  style_file = 'config/markdown_style.rb'
  sh "bundle exec mdl -s #{style_file} *.md doc/*.md"
end

# Apply JSCS to look for issues in Javascript files.
# To use, must install jscs; the easy way is to use npm, and at
# the top directory of this project run "npm install jscs".
# This presumes that the jscs executable is installed in "node_modules/.bin/".
# See http://jscs.info/overview
#
# This not currently included in default "rake"; it *works* but is very
# noisy.  We need to determine which ruleset to apply,
# and we need to fix the Javascript to match that.
# We don't scan 'app/assets/javascripts/application.js';
# it is primarily auto-generated code + special directives.
desc 'Run jscs - Javascript style checker'
task :jscs do
  jscs_exe = 'node_modules/.bin/jscs'
  jscs_options = '--preset=node-style-guide -m 9999'
  jscs_files = 'app/assets/javascripts/project-form.js'
  sh "#{jscs_exe} #{jscs_options} #{jscs_files}"
end

desc 'Load current self.json'
task :load_self_json do
  require 'open-uri'
  require 'json'
  url = 'https://master.bestpractices.coreinfrastructure.org/projects/1.json'
  contents = open(url).read
  pretty_contents = JSON.pretty_generate(JSON.parse(contents))
  File.write('doc/self.json', pretty_contents)
end

desc 'Examine licenses of reused components; see license_finder docs.'
task license_check:
       ['license_finder_report.html', 'license_finder_summary.txt']

file 'license_finder_report.html' => 'Gemfile.lock' do
  sh 'bundle exec license_finder report --format html ' \
     '> license_finder_report.html'
end

desc 'Check for trailing whitespace in latest proposed (git) patch.'
task :whitespace_check do
  sh 'git diff --check'
end

file 'license_finder_summary.txt' => 'Gemfile.lock' do
  # This will error-out if there's a license problem.
  sh 'bundle exec license_finder | tee license_finder_summary.txt'
end

desc 'Create visualization of gem dependencies (requires graphviz)'
task :bundle_viz do
  sh 'bundle viz --version --requirements --format svg'
end
