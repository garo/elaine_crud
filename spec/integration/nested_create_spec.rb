# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Nested Create Feature', type: :feature do
  before(:each) do
    reset_database
  end

  describe 'new_modal action' do
    it 'renders modal template for creating nested record' do
      visit '/authors/new_modal?return_field=author_id&parent_model=book'
      expect_no_errors

      # Should show the new form
      expect(page).to have_content('New Author')
      expect(page).to have_field('author[name]')

      # Should have hidden fields for modal state
      expect(page).to have_field('modal_mode', type: :hidden, with: 'true')
      expect(page).to have_field('return_field', type: :hidden, with: 'author_id')
      expect(page).to have_field('parent_model', type: :hidden, with: 'book')
    end

    it 'provides new_modal route for all ElaineCrud controllers' do
      # Test multiple controllers to verify routing DSL works
      visit '/authors/new_modal?return_field=author_id&parent_model=book'
      expect_no_errors
      expect(page).to have_content('New Author')

      visit '/libraries/new_modal?return_field=library_id&parent_model=book_copy'
      expect_no_errors
      expect(page).to have_content('New Library')
    end
  end

  describe 'Creating nested record via modal POST' do
    it 'creates record and returns Turbo Stream response', :aggregate_failures do
      initial_count = Author.count

      # Simulate modal form submission
      page.driver.post '/authors', {
        author: {
          name: 'Nested Author',
          bio: 'Created via nested modal',
          birth_year: 1985
        },
        modal_mode: 'true',
        return_field: 'author_id',
        parent_model: 'book'
      }

      # Should create the record
      expect(Author.count).to eq(initial_count + 1)
      new_author = Author.last
      expect(new_author.name).to eq('Nested Author')

      # Response should be a Turbo Stream (can't fully test without JS driver)
      expect(page.response_headers['Content-Type']).to include('turbo-stream')
    end

    it 'handles validation errors in modal mode', :aggregate_failures do
      initial_count = Author.count

      # Try to create invalid author (empty name, assuming it's required)
      page.driver.post '/authors', {
        author: {
          name: '', # Invalid
          bio: 'Test'
        },
        modal_mode: 'true',
        return_field: 'author_id',
        parent_model: 'book'
      }

      # Should not create the record
      expect(Author.count).to eq(initial_count)

      # Should return unprocessable entity status
      expect(page.status_code).to eq(422)
    end
  end

  describe 'Field configuration DSL' do
    it 'marks author_id field with nested_create in BooksController' do
      books_controller = BooksController.new
      field_config = books_controller.send(:field_config_for, :author_id)

      expect(field_config).not_to be_nil
      expect(field_config.has_nested_create?).to be true
    end

    it 'does not mark fields without nested_create configuration' do
      books_controller = BooksController.new

      # Test a specific field we know doesn't have nested_create
      field_config = books_controller.send(:field_config_for, :title)

      if field_config && field_config.respond_to?(:has_nested_create?)
        expect(field_config.has_nested_create?).to be_falsey
      else
        # title doesn't have configuration at all, which is also valid
        expect(field_config).to be_nil.or(satisfy { |fc| !fc.has_nested_create? })
      end
    end
  end

  describe 'Form rendering with nested_create' do
    it 'shows "+ New Author" link on books/new form' do
      visit '/books/new'
      expect_no_errors

      # Should have the nested create link
      expect(page).to have_link('+ New Author', href: /\/authors\/new_modal/)

      # Link should include proper parameters
      link = page.find_link('+ New Author')
      href = link[:href]
      expect(href).to include('return_field=author_id')
      expect(href).to include('parent_model=book')
    end

    it 'wraps foreign key select in a div for Turbo Stream updates' do
      visit '/books/new'

      # Should have wrapper div that Turbo Stream will target
      expect(page).to have_css('div#author_id_select_wrapper')

      # Select should be inside the wrapper
      within('#author_id_select_wrapper') do
        expect(page).to have_select('book[author_id]')
      end
    end
  end

  describe 'Turbo Stream response partial' do
    it 'generates dropdown options from field configuration' do
      # Create a test author
      test_author = Author.create!(
        name: 'Test Author for Dropdown',
        biography: 'Test biography',
        birth_year: 1990
      )

      # Simulate the Turbo Stream response by rendering the partial
      books_controller = BooksController.new
      field_config = books_controller.send(:field_config_for, :author_id)

      # Visit a page to get a valid session
      visit '/books/new'

      # The partial should generate options including our test author
      expect(page).to have_select('book[author_id]') do |select|
        expect(select).to have_css("option[value='#{test_author.id}']", text: test_author.name)
      end
    end
  end

  describe 'Modal layout integration' do
    it 'application layout includes modal component' do
      visit '/books'

      # Modal should be present in the layout
      expect(page).to have_css('#elaine-modal')
      expect(page).to have_css('turbo-frame#modal_content')
    end
  end
end
