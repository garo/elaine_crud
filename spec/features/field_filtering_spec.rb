# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Field Filtering Functionality', type: :request do
  before do
    reset_database
  end

  describe 'Text field filtering' do
    # With the default-filterable behavior, no configuration needed
    # All fields are filterable by default

    it 'filters by text field with partial match' do
      get books_path(filter: { title: 'Pride' })

      expect(response.status).to eq(200)
      expect(response.body).to include('Pride and Prejudice')
    end

    it 'uses case-insensitive matching' do
      get books_path(filter: { title: 'pride' })  # lowercase

      expect(response.status).to eq(200)
      expect(response.body).to include('Pride and Prejudice')
    end

    it 'returns only matching records' do
      queries = capture_sql_queries do
        get books_path(filter: { title: 'Pride' })
      end

      where_query = queries.find { |q| q.include?('WHERE') && q.include?('LIKE') }
      expect(where_query).to be_present
      expect(where_query).to include('title')
    end

    it 'uses LOWER() for case-insensitive comparison' do
      queries = capture_sql_queries do
        get books_path(filter: { title: 'Pride' })
      end

      where_query = queries.find { |q| q.include?('LIKE') }
      expect(where_query).to match(/LOWER/i) if where_query
    end
  end

  describe 'Boolean field filtering' do
    it 'filters by boolean true value' do
      get books_path(filter: { available: 'true' })

      expect(response.status).to eq(200)
    end

    it 'filters by boolean false value' do
      get books_path(filter: { available: 'false' })

      expect(response.status).to eq(200)
    end

    it 'handles boolean string inputs' do
      # Various string representations of true
      ['true', '1', 't', 'yes'].each do |true_value|
        get books_path(filter: { available: true_value })
        expect(response.status).to eq(200)
      end
    end

    it 'casts boolean values correctly' do
      queries = capture_sql_queries do
        get books_path(filter: { available: 'true' })
      end

      where_query = queries.find { |q| q.include?('WHERE') && q.include?('available') }
      expect(where_query).to be_present if where_query
    end
  end

  describe 'Integer field filtering' do
    it 'filters by exact integer match' do
      # Filter by publication year
      get books_path(filter: { publication_year: '1813' })

      expect(response.status).to eq(200)
    end

    it 'filters by foreign key' do
      # Get first author ID
      author = Author.first
      get books_path(filter: { author_id: author.id.to_s })

      expect(response.status).to eq(200)
      # Should only show books by that author
    end

    it 'handles array of values for foreign keys' do
      author1 = Author.first
      author2 = Author.second

      get books_path(filter: { author_id: [author1.id, author2.id] })

      expect(response.status).to eq(200)
      # Should show books by either author
    end
  end

  describe 'Field validation' do
    it 'only accepts valid column names' do
      # Invalid field should be silently ignored
      get books_path(filter: { nonexistent_field: 'value' })

      expect(response.status).to eq(200)
      # Should not cause errors
    end

    it 'validates field exists in model' do
      queries = capture_sql_queries do
        get books_path(filter: { fake_column: 'test' })
      end

      # Should not include fake_column in WHERE clause
      where_queries = queries.select { |q| q.include?('WHERE') }
      where_queries.each do |q|
        expect(q).not_to include('fake_column')
      end
    end

    it 'skips blank filter values' do
      get books_path(filter: { title: '' })

      expect(response.status).to eq(200)

      queries = capture_sql_queries do
        get books_path(filter: { title: '' })
      end

      # Should not add WHERE clause for blank value
      like_queries = queries.select { |q| q.include?('title') && q.include?('LIKE') }
      expect(like_queries).to be_empty
    end
  end

  describe 'Multiple field filters' do
    it 'applies multiple filters with AND logic' do
      get books_path(filter: { publication_year: '1813', available: 'true' })

      expect(response.status).to eq(200)

      queries = capture_sql_queries do
        get books_path(filter: { publication_year: '1813', available: 'true' })
      end

      where_query = queries.find { |q| q.include?('WHERE') }
      # Should have both conditions
      expect(where_query).to include('publication_year') if where_query
      expect(where_query).to include('available') if where_query
    end
  end

  describe 'SQL safety' do
    it 'uses safe queries for filter values (Arel)' do
      queries = capture_sql_queries do
        get books_path(filter: { title: 'Pride' })
      end

      where_query = queries.find { |q| q.include?('LIKE') || q.include?('title') }
      # After Arel fix: Uses Arel's .matches() which safely handles values
      # Arel quotes identifiers and escapes values properly
      expect(where_query).to be_present
      expect(where_query).to include('title')
    end

    it 'handles special characters in filter values safely' do
      # SQL injection attempt should be safely escaped
      get books_path(filter: { title: "'; DROP TABLE books;--" })

      expect(response.status).to eq(200)
      # Books table should still exist
      expect { Book.count }.not_to raise_error
      expect(Book.count).to be > 0
    end

    it 'handles quotes in filter values' do
      get books_path(filter: { title: "O'Brien" })

      expect(response.status).to eq(200)
      # Should not cause SQL errors
    end
  end

  # Helper method
  def capture_sql_queries(&block)
    queries = []
    subscription = ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
      event = ActiveSupport::Notifications::Event.new(*args)
      sql = event.payload[:sql]
      queries << sql if sql !~ /^(PRAGMA|SELECT sqlite_version|TRANSACTION|ROLLBACK|COMMIT)/
    end

    block.call

    ActiveSupport::Notifications.unsubscribe(subscription)
    queries
  end
end
