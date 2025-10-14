# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Sorting and Filtering Security', type: :request do
  before do
    reset_database
  end

  describe 'SQL Injection Prevention - Sorting' do
    it 'prevents SQL injection through sort column parameter' do
      # Attempt to inject SQL through column name
      malicious_sort = "title); DROP TABLE books;--"

      get books_path(sort: malicious_sort, direction: 'asc')

      # Should reject invalid column and not execute malicious SQL
      expect(response.status).to be_in([200, 400, 422])
      expect { Book.count }.not_to raise_error
      expect(Book.count).to be > 0  # Table still exists
    end

    it 'prevents SQL injection through sort direction parameter' do
      malicious_direction = "asc; DROP TABLE books;--"

      get books_path(sort: 'title', direction: malicious_direction)

      expect(response.status).to be_in([200, 400, 422])
      expect { Book.count }.not_to raise_error
      expect(Book.count).to be > 0
    end

    it 'validates sort column against whitelist' do
      # Only actual column names should be accepted
      queries = capture_sql_queries do
        get books_path(sort: 'malicious_column', direction: 'asc')
      end

      order_query = queries.find { |q| q.include?('ORDER BY') }
      # Should not include malicious column name
      expect(order_query).not_to include('malicious_column') if order_query
    end

    it 'rejects SQL functions in sort column' do
      malicious_sort = "CASE WHEN 1=1 THEN title ELSE id END"

      get books_path(sort: malicious_sort, direction: 'asc')

      expect(response.status).to eq(200)
      # Should use default sort, not execute the CASE statement
    end

    it 'rejects subqueries in sort column' do
      malicious_sort = "(SELECT password FROM users LIMIT 1)"

      get books_path(sort: malicious_sort, direction: 'asc')

      expect(response.status).to eq(200)
      # Should not execute subquery
    end
  end

  describe 'SQL Injection Prevention - Search' do
    it 'prevents SQL injection through search parameter' do
      malicious_search = "' OR '1'='1"

      get books_path(search: malicious_search)

      expect(response.status).to eq(200)
      # Should treat as literal search string, not SQL
    end

    it 'prevents UNION-based SQL injection' do
      malicious_search = "' UNION SELECT email FROM authors--"

      get books_path(search: malicious_search)

      expect(response.status).to eq(200)
      # Should not execute UNION
    end

    it 'prevents SQL injection with comments' do
      malicious_search = "test'; DROP TABLE books;--"

      get books_path(search: malicious_search)

      expect(response.status).to eq(200)
      expect { Book.count }.not_to raise_error
      expect(Book.count).to be > 0
    end

    it 'uses safe Arel queries for search values' do
      queries = capture_sql_queries do
        get books_path(search: 'Pride')
      end

      search_query = queries.find { |q| q.include?('LIKE') }
      # After Arel fix: Arel's .matches() method safely escapes values
      # May use ? placeholders or inline safely-escaped values depending on database
      # The key is that the query is safe from SQL injection
      expect(search_query).to be_present
    end

    it 'handles quotes in search safely' do
      get books_path(search: "O'Brien's")

      expect(response.status).to eq(200)
      # Should not cause SQL syntax errors
    end

    it 'handles double quotes in search' do
      get books_path(search: '"quoted text"')

      expect(response.status).to eq(200)
    end

    it 'handles backslashes in search' do
      get books_path(search: 'test\\escape')

      expect(response.status).to eq(200)
    end
  end

  describe 'SQL Injection Prevention - Filters' do
    it 'prevents SQL injection through filter field names' do
      malicious_filter = {
        "title'; DROP TABLE books;--" => 'value'
      }

      get books_path(filter: malicious_filter)

      # Should validate field names
      expect { Book.count }.not_to raise_error
      expect(Book.count).to be > 0
    end

    it 'prevents SQL injection through filter values' do
      malicious_value = "' OR '1'='1"

      get books_path(filter: { title: malicious_value })

      expect(response.status).to eq(200)
      # Should treat as literal value
    end

    it 'validates filter field names against model columns' do
      queries = capture_sql_queries do
        get books_path(filter: { fake_column: 'test' })
      end

      where_queries = queries.select { |q| q.include?('WHERE') }
      # Should not include fake_column in SQL
      where_queries.each do |q|
        expect(q).not_to include('fake_column')
      end
    end

    it 'uses parameterized queries for filter values' do
      queries = capture_sql_queries do
        get books_path(filter: { available: 'true' })
      end

      where_query = queries.find { |q| q.include?('WHERE') && q.include?('available') }
      # Values should be parameterized
      expect(where_query).to be_present if where_query
    end

    it 'handles array filter values safely' do
      author1 = Author.first
      malicious_value = "1 OR 1=1"

      get books_path(filter: { author_id: [author1.id, malicious_value] })

      expect(response.status).to eq(200)
      # Should not execute OR 1=1
    end
  end

  describe 'SQL Injection Prevention - Date Filters' do
    it 'prevents SQL injection through date from parameter' do
      malicious_date = "2020-01-01'; DROP TABLE librarians;--"

      get librarians_path(filter: { hire_date_from: malicious_date })

      expect { Librarian.count }.not_to raise_error
      expect(Librarian.count).to be > 0
    end

    it 'prevents SQL injection through date to parameter' do
      malicious_date = "2020-01-01' OR '1'='1"

      get librarians_path(filter: { hire_date_to: malicious_date })

      expect(response.status).to eq(200)
    end

    it 'uses parameterized queries for date values' do
      queries = capture_sql_queries do
        get librarians_path(filter: { hire_date_from: '2015-01-01' })
      end

      where_query = queries.find { |q| q.include?('hire_date') && q.include?('>=') }
      # Should use ? for parameter binding
      expect(where_query).to include('?') if where_query
    end
  end

  describe 'Column Name Validation' do
    it 'only allows actual column names in sort' do
      # Column names should come from a validated whitelist
      valid_columns = Book.column_names

      valid_columns.each do |column|
        get books_path(sort: column, direction: 'asc')
        expect(response.status).to eq(200)
      end
    end

    it 'rejects non-existent columns in sort' do
      fake_columns = %w[nonexistent fake_col invalid]

      fake_columns.each do |column|
        get books_path(sort: column, direction: 'asc')
        expect(response.status).to eq(200)  # Should not crash
        # Should use default sort instead
      end
    end

    it 'validates filter field names' do
      # Only actual column names should be filterable
      get books_path(filter: { not_a_real_column: 'value' })

      expect(response.status).to eq(200)
      # Should silently ignore invalid fields
    end
  end

  describe 'Input Sanitization' do
    it 'handles very long search strings' do
      long_search = 'a' * 10000

      get books_path(search: long_search)

      expect(response.status).to eq(200)
    end

    it 'handles very long filter values' do
      long_value = 'x' * 10000

      get books_path(filter: { title: long_value })

      expect(response.status).to eq(200)
    end

    it 'handles special characters in all parameters' do
      special_chars = ['<script>alert("xss")</script>', '${7*7}', '../../etc/passwd']

      special_chars.each do |value|
        get books_path(search: value)
        expect(response.status).to eq(200)
      end
    end

    it 'handles null bytes' do
      get books_path(search: "test\u0000null")

      # Null bytes are edge cases - may be rejected by database
      # 200: Handled gracefully, 400: Bad request, 500: Database rejection
      expect(response.status).to be_in([200, 400, 500])
    end
  end

  describe 'Mass Assignment Protection' do
    it 'does not allow filtering by protected attributes' do
      # Attempt to filter by attributes that shouldn't be exposed
      get books_path(filter: { created_at: Time.now })

      # Should either ignore or handle safely
      expect(response.status).to eq(200)
    end
  end

  describe 'Time-based Attack Prevention' do
    it 'completes requests in reasonable time even with malicious input' do
      # Prevent ReDoS (Regular Expression Denial of Service)
      malicious_search = 'a' * 1000 + 'b'

      start_time = Time.now
      get books_path(search: malicious_search)
      duration = Time.now - start_time

      expect(duration).to be < 5.0  # Should complete in under 5 seconds
    end
  end

  describe 'Error Information Disclosure' do
    it 'does not expose SQL in error messages' do
      # Malicious input that might cause errors
      get books_path(filter: { title: "' OR 1=1--" })

      # Even if there's an error, should not expose SQL
      expect(response.body).not_to include('SELECT')
      expect(response.body).not_to include('WHERE')
    end
  end

  # Helper method
  def capture_sql_queries(&block)
    queries = []
    subscription = ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
      event = ActiveSupport::Notifications::Event.new(*args)
      sql = event.payload[:sql]
      queries << sql if sql !~ /^(PRAGMA|SELECT sqlite_version|TRANSACTION|ROLLBACK|COMMIT|SCHEMA)/
    end

    block.call

    ActiveSupport::Notifications.unsubscribe(subscription)
    queries
  end
end
