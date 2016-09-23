set :application, 'your_app_name'
set :repo_url, 'git@bitbucket.org:your_app_name.git'

# Default branch is :master
ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, '/www/your_app_name'

# Default value for :scm is :git
set :scm, :git

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: 'log/capistrano.log', color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
append :linked_files, 'docker.env'

# Default value for linked_dirs is []
append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'public/system', 'letsencrypt', 'certs'

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
set :keep_releases, 3

namespace :deploy do

  desc 'Running a docker containers for this project.'
  task :dockerize do
    on roles(:web) do
      previous = capture("ls -Ct #{releases_path} | awk '{print $2}'").to_s.strip
      execute "cd #{releases_path}/#{previous} && docker-compose stop; true"
      execute "cd #{releases_path}/#{previous} && docker-compose rm -f; true"
      execute "cd #{release_path} && docker build --rm -t your_docker_image_name ."
      execute "cd #{release_path} && docker-compose up -d"
    end
  end

  desc 'Precompile Assets'
  task :precompile do
    on roles(:web) do
      execute "docker exec your_docker_image_name rake -f /home/app/Rakefile assets:precompile RAILS_ENV=production"
    end
  end

  desc 'Migrate Database'
  task :migrate do
    on roles(:db) do
      execute "docker exec your_docker_image_name rake -f /home/app/Rakefile db:migrate RAILS_ENV=production"
    end
  end

  desc 'Seed Database'
  task :seed do
    on roles(:db) do
      execute "docker exec your_docker_image_name rake -f /home/app/Rakefile db:seed RAILS_ENV=production"
    end
  end

  after 'deploy:published', 'deploy:dockerize'
  after 'deploy:dockerize', 'deploy:precompile'
  after 'deploy:precompile', 'deploy:migrate'

end