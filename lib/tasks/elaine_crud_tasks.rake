# frozen_string_literal: true

namespace :elaine_crud do
  desc "Build precompiled CSS for ElaineCrud gem"
  task :build_css do
    require 'open3'

    gem_root = File.expand_path('../..', __dir__)
    input_css = File.join(gem_root, 'app/assets/stylesheets/elaine_crud.source.css')
    output_css = File.join(gem_root, 'vendor/assets/stylesheets/elaine_crud.css')
    config_file = File.join(gem_root, 'tailwind.config.js')

    puts "Building ElaineCrud CSS..."
    puts "  Input:  #{input_css}"
    puts "  Output: #{output_css}"
    puts "  Config: #{config_file}"
    puts

    # Check for tailwindcss standalone binary (not the Ruby gem binstub)
    # Look in common installation locations
    tailwind_bin = nil
    ['/usr/local/bin/tailwindcss', '/opt/homebrew/bin/tailwindcss', "#{ENV['HOME']}/.local/bin/tailwindcss"].each do |path|
      if File.executable?(path)
        # Verify it's the standalone binary, not Ruby gem
        test_output = `#{path} --help 2>&1`
        if test_output.include?('tailwindcss') && !test_output.include?('Gem::Exception')
          tailwind_bin = path
          break
        end
      end
    end

    if tailwind_bin.nil?
      puts "✗ Tailwind CSS CLI not found"
      puts
      puts "To install Tailwind CSS standalone CLI:"
      puts

      # Detect platform
      platform = case RUBY_PLATFORM
                 when /darwin.*arm64/ then 'macos-arm64'
                 when /darwin/ then 'macos-x64'
                 when /linux.*x86_64/ then 'linux-x64'
                 when /linux.*aarch64/ then 'linux-arm64'
                 else 'unknown'
                 end

      if platform != 'unknown'
        puts "  curl -sLO https://github.com/tailwindlabs/tailwindcss/releases/latest/download/tailwindcss-#{platform}"
        puts "  chmod +x tailwindcss-#{platform}"
        puts "  sudo mv tailwindcss-#{platform} /usr/local/bin/tailwindcss"
      else
        puts "  Visit: https://github.com/tailwindlabs/tailwindcss/releases/latest"
        puts "  Download the appropriate binary for your platform"
      end

      puts
      puts "Or use npx (no installation required):"
      puts "  npx -y tailwindcss@latest -i ./app/assets/stylesheets/elaine_crud.source.css -o ./vendor/assets/stylesheets/elaine_crud.css --minify -c ./tailwind.config.js"
      puts
      exit 1
    end

    puts "✓ Found Tailwind CSS: #{tailwind_bin}"
    puts

    # Build CSS
    cmd = "#{tailwind_bin} -i #{input_css} -o #{output_css} --minify -c #{config_file}"

    stdout, stderr, status = Open3.capture3(cmd)

    if status.success?
      file_size = File.size(output_css)
      puts "✓ CSS built successfully (#{file_size} bytes)"
      puts "  Generated: #{output_css}"

      # Add header comment
      css_content = File.read(output_css)

      # Get Tailwind version
      version_stdout, = Open3.capture3("#{tailwind_bin} --help")
      version = version_stdout[/tailwindcss v([\d.]+)/, 1] || 'Latest'

      header = <<~HEADER
        /**
         * ElaineCrud - Precompiled Tailwind CSS
         * Generated: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}
         * Tailwind CSS version: #{version}
         *
         * This file contains all Tailwind utility classes used by ElaineCrud.
         * Safe to include alongside your app's Tailwind styles.
         *
         * For customization, see: https://github.com/garo/elaine_crud#customization
         */

      HEADER

      File.write(output_css, header + css_content)
      puts "✓ Added header comment"
      puts
      puts "Done! CSS compiled with Tailwind CSS v#{version}"
    else
      puts "✗ Failed to build CSS"
      puts "STDOUT: #{stdout}" unless stdout.empty?
      puts "STDERR: #{stderr}" unless stderr.empty?
      exit 1
    end
  end
end
