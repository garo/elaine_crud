# frozen_string_literal: true

module TestHelpers
  # Helper to reset and reseed the database
  def reset_database
    # Delete in correct order to avoid foreign key constraints
    # Delete children first, then parents
    ActiveRecord::Base.connection.execute('DELETE FROM loans')
    ActiveRecord::Base.connection.execute('DELETE FROM book_copies')  # References books and libraries
    ActiveRecord::Base.connection.execute('DELETE FROM profiles')
    ActiveRecord::Base.connection.execute('DELETE FROM books_tags')  # HABTM join table
    ActiveRecord::Base.connection.execute('DELETE FROM librarians')
    ActiveRecord::Base.connection.execute('DELETE FROM members')
    ActiveRecord::Base.connection.execute('DELETE FROM books')
    ActiveRecord::Base.connection.execute('DELETE FROM tags')
    ActiveRecord::Base.connection.execute('DELETE FROM authors')
    ActiveRecord::Base.connection.execute('DELETE FROM libraries')

    # Reset sequences
    ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name='loans'")
    ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name='book_copies'")
    ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name='profiles'")
    ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name='librarians'")
    ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name='members'")
    ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name='books'")
    ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name='tags'")
    ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name='authors'")
    ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name='libraries'")

    # Reload seeds in quiet mode (suppress output during tests)
    ENV['SEED_QUIET'] = 'true'
    load Rails.root.join('db/seeds.rb')
    ENV.delete('SEED_QUIET')
  end

  # Helper to verify no errors on page
  def expect_no_errors
    expect(page).not_to have_content('Exception')
    expect(page).not_to have_content('Error')
    expect(page.status_code).to eq(200)
  end

  # Helper to count table rows
  def count_table_rows
    # Count turbo-frames with record_ IDs (one frame per row)
    page.all('turbo-frame[id^="record_"]').count
  end
end

RSpec.configure do |config|
  config.include TestHelpers, type: :request
  config.include TestHelpers, type: :feature
end
