# frozen_string_literal: true

module TestHelpers
  # Helper to reset and reseed the database
  def reset_database
    # Delete in correct order to avoid foreign key constraints
    # Delete children first, then parents
    ActiveRecord::Base.connection.execute('DELETE FROM loans')
    ActiveRecord::Base.connection.execute('DELETE FROM profiles')
    ActiveRecord::Base.connection.execute('DELETE FROM librarians')
    ActiveRecord::Base.connection.execute('DELETE FROM members')
    ActiveRecord::Base.connection.execute('DELETE FROM books')
    ActiveRecord::Base.connection.execute('DELETE FROM authors')
    ActiveRecord::Base.connection.execute('DELETE FROM libraries')

    # Reset sequences
    ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name='loans'")
    ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name='profiles'")
    ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name='librarians'")
    ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name='members'")
    ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name='books'")
    ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name='authors'")
    ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name='libraries'")

    # Reload seeds
    load Rails.root.join('db/seeds.rb')
  end

  # Helper to verify no errors on page
  def expect_no_errors
    expect(page).not_to have_content('Exception')
    expect(page).not_to have_content('Error')
    expect(page.status_code).to eq(200)
  end

  # Helper to count table rows
  def count_table_rows
    # Count unique record IDs (each record may have multiple cells due to grid layout)
    page.all('[data-record-id]').map { |el| el['data-record-id'] }.uniq.count
  end
end

RSpec.configure do |config|
  config.include TestHelpers, type: :request
  config.include TestHelpers, type: :feature
end
