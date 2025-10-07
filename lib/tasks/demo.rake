namespace :demo do
  desc "Run the demo application server"
  task :server do
    puts "Starting ElaineCrud Demo Application..."
    puts "=" * 60
    puts "Navigate to: http://localhost:3000"
    puts "=" * 60

    Dir.chdir(File.expand_path('../../test/dummy_app', __dir__)) do
      exec "bin/rails server"
    end
  end

  desc "Setup demo database (migrate and seed)"
  task :setup do
    puts "Setting up demo database..."
    Dir.chdir(File.expand_path('../../test/dummy_app', __dir__)) do
      puts "\n1. Creating database..."
      system("bin/rails db:create") || abort("Database creation failed")

      puts "\n2. Running migrations..."
      system("bin/rails db:migrate") || abort("Migration failed")

      puts "\n3. Seeding database with sample data..."
      system("bin/rails db:seed") || abort("Seeding failed")

      puts "\n" + "=" * 60
      puts "Demo setup complete!"
      puts "Run: rake demo:server"
      puts "=" * 60
    end
  end

  desc "Reset demo database (drop, create, migrate, seed)"
  task :reset do
    puts "Resetting demo database..."
    Dir.chdir(File.expand_path('../../test/dummy_app', __dir__)) do
      puts "\n1. Dropping database..."
      system("bin/rails db:drop")

      puts "\n2. Creating database..."
      system("bin/rails db:create") || abort("Database creation failed")

      puts "\n3. Running migrations..."
      system("bin/rails db:migrate") || abort("Migration failed")

      puts "\n4. Seeding database with sample data..."
      system("bin/rails db:seed") || abort("Seeding failed")

      puts "\n" + "=" * 60
      puts "Demo database reset complete!"
      puts "Run: rake demo:server"
      puts "=" * 60
    end
  end

  desc "Run Rails console in demo app context"
  task :console do
    puts "Starting Rails console for demo app..."
    Dir.chdir(File.expand_path('../../test/dummy_app', __dir__)) do
      exec "bin/rails console"
    end
  end

  desc "Open Rails database console for demo app"
  task :dbconsole do
    puts "Starting database console for demo app..."
    Dir.chdir(File.expand_path('../../test/dummy_app', __dir__)) do
      exec "bin/rails dbconsole"
    end
  end

  desc "Display demo app information and available routes"
  task :info do
    puts "\n" + "=" * 60
    puts "ElaineCrud Demo Application Information"
    puts "=" * 60

    puts "\nAvailable Resources:"
    puts "  - Libraries (has_many books, members, librarians)"
    puts "  - Authors (has_many books)"
    puts "  - Books (belongs_to author, library | has_many loans)"
    puts "  - Members (belongs_to library | has_many loans)"
    puts "  - Loans (belongs_to book, member)"
    puts "  - Librarians (belongs_to library)"

    puts "\nFeatures Demonstrated:"
    puts "  ✓ Automatic foreign key detection and dropdowns"
    puts "  ✓ Has-many relationships with counts"
    puts "  ✓ Custom field display (currency, dates, booleans)"
    puts "  ✓ Dropdown options for enums"
    puts "  ✓ Status badges with colors"
    puts "  ✓ Parent-child filtering"
    puts "  ✓ Sorting by columns"
    puts "  ✓ Inline editing with Turbo"

    puts "\nRake Tasks:"
    puts "  rake demo:setup     - Initial database setup"
    puts "  rake demo:reset     - Reset database with fresh data"
    puts "  rake demo:server    - Start the demo server"
    puts "  rake demo:console   - Open Rails console"
    puts "  rake demo:dbconsole - Open database console"
    puts "  rake demo:info      - Show this information"

    puts "\n" + "=" * 60
  end
end

# Set demo:info as the default demo task
desc "Show ElaineCrud demo information"
task :demo => 'demo:info'
