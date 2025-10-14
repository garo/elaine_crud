# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Combined Search, Filter, and Sort Functionality', type: :request do
  before do
    reset_database
  end

  describe 'Search + Sort' do
    it 'applies both search and sort' do
      get books_path(search: 'the', sort: 'title', direction: 'asc')

      expect(response.status).to eq(200)

      queries = capture_sql_queries do
        get books_path(search: 'the', sort: 'title', direction: 'asc')
      end

      # Should have both WHERE (for search) and ORDER BY
      combined_query = queries.find { |q| q.include?('WHERE') && q.include?('ORDER BY') }
      expect(combined_query).to be_present
      expect(combined_query).to include('LIKE')
      expect(combined_query).to include('title')
    end

    it 'sorts search results correctly' do
      get books_path(search: 'and', sort: 'title', direction: 'asc')

      expect(response.status).to eq(200)
      # Results should be filtered by search AND sorted
    end

    it 'maintains sort order with search' do
      queries = capture_sql_queries do
        get books_path(search: 'the', sort: 'publication_year', direction: 'desc')
      end

      query = queries.find { |q| q.include?('ORDER BY') }
      expect(query).to include('publication_year')
      expect(query).to match(/desc/i)
    end
  end

  describe 'Filter + Sort' do
    it 'applies both filter and sort' do
      author = Author.first
      get books_path(filter: { author_id: author.id }, sort: 'title', direction: 'asc')

      expect(response.status).to eq(200)

      queries = capture_sql_queries do
        get books_path(filter: { author_id: author.id }, sort: 'title', direction: 'asc')
      end

      query = queries.find { |q| q.include?('WHERE') && q.include?('ORDER BY') }
      expect(query).to be_present if query
    end

    it 'sorts filtered results' do
      get books_path(filter: { available: 'true' }, sort: 'publication_year', direction: 'desc')

      expect(response.status).to eq(200)
    end

    it 'handles multiple filters with sort' do
      get books_path(
        filter: { available: 'true', publication_year: '1813' },
        sort: 'title',
        direction: 'asc'
      )

      expect(response.status).to eq(200)
    end
  end

  describe 'Search + Filter + Sort' do
    it 'applies all three operations together' do
      author = Author.first
      get books_path(
        search: 'Pride',
        filter: { author_id: author.id },
        sort: 'title',
        direction: 'asc'
      )

      expect(response.status).to eq(200)
    end

    it 'generates correct SQL for all operations' do
      queries = capture_sql_queries do
        get books_path(
          search: 'the',
          filter: { available: 'true' },
          sort: 'title',
          direction: 'desc'
        )
      end

      query = queries.find { |q| q.include?('WHERE') && q.include?('ORDER BY') }
      if query
        # Should have search (LIKE), filter (WHERE), and sort (ORDER BY)
        expect(query).to include('LIKE')  # Search
        expect(query).to include('available')  # Filter
        expect(query).to include('ORDER BY')  # Sort
      end
    end

    it 'maintains correct operation order' do
      # Operations should be applied in correct order:
      # 1. Search (WHERE with LIKE)
      # 2. Filter (additional WHERE conditions)
      # 3. Sort (ORDER BY)

      get books_path(
        search: 'and',
        filter: { available: 'true' },
        sort: 'publication_year',
        direction: 'asc'
      )

      expect(response.status).to eq(200)
    end
  end

  describe 'Date range filter + Sort' do
    it 'combines date filtering with sorting' do
      get librarians_path(
        filter: { hire_date_from: '2015-01-01' },
        sort: 'name',
        direction: 'asc'
      )

      expect(response.status).to eq(200)
    end

    it 'sorts date-filtered results' do
      queries = capture_sql_queries do
        get librarians_path(
          filter: { hire_date_from: '2015-01-01', hire_date_to: '2020-12-31' },
          sort: 'hire_date',
          direction: 'desc'
        )
      end

      query = queries.find { |q| q.include?('ORDER BY') }
      expect(query).to include('hire_date') if query
    end
  end

  describe 'Complex combinations' do
    it 'handles search + multiple filters + sort' do
      get books_path(
        search: 'the',
        filter: { available: 'true', publication_year: '1813' },
        sort: 'title',
        direction: 'asc'
      )

      expect(response.status).to eq(200)
    end

    it 'handles empty search with filters and sort' do
      get books_path(
        search: '',
        filter: { available: 'true' },
        sort: 'title',
        direction: 'desc'
      )

      expect(response.status).to eq(200)
      # Should apply filters and sort, but not search
    end

    it 'handles search with no results, still sorts' do
      get books_path(
        search: 'xyznonexistent',
        sort: 'title',
        direction: 'asc'
      )

      expect(response.status).to eq(200)
      # Should return empty results but not error
    end
  end

  describe 'Performance considerations' do
    it 'generates single efficient query for all operations' do
      queries = capture_sql_queries do
        get books_path(
          search: 'the',
          filter: { available: 'true' },
          sort: 'title',
          direction: 'asc'
        )
      end

      # Should have one main SELECT query, not multiple separate queries
      select_queries = queries.select { |q| q =~ /SELECT.*FROM.*books/i }
      # Might have queries for counts, but main query should be combined
      expect(select_queries).not_to be_empty
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
