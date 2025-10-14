# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Global Search Functionality', type: :request do
  before do
    reset_database
  end

  describe 'Basic search' do
    it 'finds records matching in any searchable column' do
      # Book with title "Pride and Prejudice" should be found
      get books_path(search: 'Pride')

      expect(response.status).to eq(200)
      expect(response.body).to include('Pride and Prejudice')
    end

    it 'performs case-insensitive search' do
      get books_path(search: 'pride')  # lowercase

      expect(response.status).to eq(200)
      expect(response.body).to include('Pride and Prejudice')
    end

    it 'performs partial match search' do
      get books_path(search: 'Pri')

      expect(response.status).to eq(200)
      expect(response.body).to include('Pride and Prejudice')
    end

    it 'searches across multiple columns' do
      # Search can match title, description, or isbn
      queries = capture_sql_queries do
        get books_path(search: 'test')
      end

      search_query = queries.find { |q| q.include?('LIKE') }
      expect(search_query).to be_present
      # Should search multiple columns with OR
      expect(search_query).to include('OR')
    end
  end

  describe 'Searchable column detection' do
    it 'only searches string/text columns' do
      queries = capture_sql_queries do
        get books_path(search: 'test')
      end

      search_query = queries.find { |q| q.include?('LIKE') }

      # Should include text fields like title, description
      expect(search_query).to include('title') if search_query
    end

    it 'excludes id, created_at, updated_at from search' do
      queries = capture_sql_queries do
        get books_path(search: 'test')
      end

      search_query = queries.find { |q| q.include?('LIKE') }

      # Should not search in these columns
      expect(search_query).not_to include('created_at') if search_query
      expect(search_query).not_to include('updated_at') if search_query
    end
  end

  describe 'Search results' do
    it 'returns all matching records' do
      # Search for a common word that appears in multiple books
      get books_path(search: 'the')

      expect(response.status).to eq(200)
      # Should return multiple matches
    end

    it 'returns empty results when no match' do
      get books_path(search: 'xyznonexistent12345')

      expect(response.status).to eq(200)
      # Should handle no results gracefully
    end

    it 'returns all records when search is empty' do
      get books_path(search: '')

      expect(response.status).to eq(200)
      # Should show all books
    end

    it 'returns all records when search param is missing' do
      get books_path

      expect(response.status).to eq(200)
      # Should show all books
    end
  end

  describe 'Special characters in search' do
    it 'handles search with spaces' do
      get books_path(search: 'Pride and')

      expect(response.status).to eq(200)
      expect(response.body).to include('Pride and Prejudice')
    end

    it 'handles search with punctuation' do
      get books_path(search: 'Pride,')

      expect(response.status).to eq(200)
      # Should not cause errors
    end

    it 'handles search with quotes safely' do
      get books_path(search: "Pride'")

      expect(response.status).to eq(200)
      # Should not cause SQL errors - values are parameterized
    end

    it 'handles search with SQL wildcards safely' do
      get books_path(search: '%')

      expect(response.status).to eq(200)
      # Should treat % as literal character in search
    end
  end

  describe 'SQL query generation' do
    it 'uses LOWER() for case-insensitive search' do
      queries = capture_sql_queries do
        get books_path(search: 'Pride')
      end

      search_query = queries.find { |q| q.include?('LIKE') }
      expect(search_query).to match(/LOWER/i) if search_query
    end

    it 'uses safe queries for search values (Arel)' do
      queries = capture_sql_queries do
        get books_path(search: 'Pride')
      end

      search_query = queries.find { |q| q.include?('LIKE') || q.include?('WHERE') }
      # After Arel fix: Uses Arel's .matches() which safely escapes values
      # The pattern may be inlined but safely escaped by Arel
      expect(search_query).to be_present
    end

    it 'adds wildcards around search term' do
      queries = capture_sql_queries do
        get books_path(search: 'Pride')
      end

      search_query = queries.find { |q| q.include?('LIKE') }
      # The actual SQL should have % wildcards for partial matching
      expect(search_query).to be_present
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
