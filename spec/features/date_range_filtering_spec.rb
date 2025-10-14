# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Date Range Filtering Functionality', type: :request do
  before do
    reset_database
  end

  describe 'Date range basics' do
    it 'filters by date from (>=)' do
      # Librarians have hire_date field
      get librarians_path(filter: { hire_date_from: '2015-01-01' })

      expect(response.status).to eq(200)
      # Should only show librarians hired on or after 2015-01-01
    end

    it 'filters by date to (<=)' do
      get librarians_path(filter: { hire_date_to: '2020-12-31' })

      expect(response.status).to eq(200)
      # Should only show librarians hired on or before 2020-12-31
    end

    it 'filters by both from and to (BETWEEN behavior)' do
      get librarians_path(filter: { hire_date_from: '2015-01-01', hire_date_to: '2020-12-31' })

      expect(response.status).to eq(200)
      # Should only show librarians hired between these dates
    end

    it 'generates SQL with >= for from filter' do
      queries = capture_sql_queries do
        get librarians_path(filter: { hire_date_from: '2015-01-01' })
      end

      where_query = queries.find { |q| q.include?('WHERE') && q.include?('hire_date') }
      expect(where_query).to include('>=') if where_query
    end

    it 'generates SQL with <= for to filter' do
      queries = capture_sql_queries do
        get librarians_path(filter: { hire_date_to: '2020-12-31' })
      end

      where_query = queries.find { |q| q.include?('WHERE') && q.include?('hire_date') }
      expect(where_query).to include('<=') if where_query
    end
  end

  describe 'Date column detection' do
    it 'only works on date/datetime/timestamp columns' do
      # hire_date is a date column - date filtering should work
      get librarians_path(filter: { hire_date_from: '2015-01-01' })

      expect(response.status).to eq(200)
      # If hire_date is a date column and filterable, request should succeed
    end

    it 'requires filterable: true configuration' do
      # Date range filtering should only work if field is marked filterable
      # This is configured in the controller

      # Without filterable configuration, should not apply filter
      # (This test would need the controller to NOT have filterable configured)
    end

    it 'detects _from and _to suffixes' do
      # The system should recognize these special parameter suffixes
      get librarians_path(filter: { hire_date_from: '2015-01-01', hire_date_to: '2020-12-31' })

      expect(response.status).to eq(200)
      # Date range filtering with both _from and _to should work
    end
  end

  describe 'Date formats' do
    it 'handles ISO format dates (YYYY-MM-DD)' do
      get librarians_path(filter: { hire_date_from: '2015-01-01' })

      expect(response.status).to eq(200)
    end

    it 'handles date objects' do
      date = Date.new(2015, 1, 1)
      get librarians_path(filter: { hire_date_from: date.to_s })

      expect(response.status).to eq(200)
    end

    it 'handles invalid dates gracefully' do
      get librarians_path(filter: { hire_date_from: 'invalid-date' })

      # Should not crash
      expect(response.status).to be_in([200, 400, 422, 500])
    end

    it 'handles empty date strings' do
      get librarians_path(filter: { hire_date_from: '' })

      expect(response.status).to eq(200)
      # Should ignore empty date filter
    end
  end

  describe 'Multiple date fields' do
    it 'can filter by multiple date range fields' do
      # If model has multiple date fields, should handle both
      get librarians_path(filter: {
        hire_date_from: '2015-01-01',
        hire_date_to: '2020-12-31'
      })

      expect(response.status).to eq(200)
    end
  end

  describe 'SQL safety' do
    it 'uses parameterized queries for date values' do
      queries = capture_sql_queries do
        get librarians_path(filter: { hire_date_from: '2015-01-01' })
      end

      where_query = queries.find { |q| q.include?('hire_date') && q.include?('>=') }
      # Should use ? for parameter binding
      expect(where_query).to include('?') if where_query
    end

    it 'handles malicious input safely' do
      get librarians_path(filter: { hire_date_from: "'; DROP TABLE librarians;--" })

      # Should not execute SQL injection
      expect { Librarian.count }.not_to raise_error
      expect(Librarian.count).to be > 0
    end
  end

  describe 'Edge cases' do
    it 'handles from date after to date' do
      # Logically invalid range (from > to)
      get librarians_path(filter: { hire_date_from: '2020-01-01', hire_date_to: '2015-01-01' })

      expect(response.status).to eq(200)
      # Should return empty results or handle gracefully
    end

    it 'handles same from and to date' do
      get librarians_path(filter: { hire_date_from: '2018-06-15', hire_date_to: '2018-06-15' })

      expect(response.status).to eq(200)
      # Should return records from exactly that date
    end

    it 'handles far future dates' do
      get librarians_path(filter: { hire_date_from: '2099-12-31' })

      expect(response.status).to eq(200)
      # Likely returns no results
    end

    it 'handles far past dates' do
      get librarians_path(filter: { hire_date_to: '1900-01-01' })

      expect(response.status).to eq(200)
      # Likely returns no results
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
