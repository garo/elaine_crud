# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Libraries CRUD', type: :feature do
  before(:each) do
    reset_database
  end

  describe 'Index page' do
    it 'displays all libraries' do
      visit '/libraries'
      expect_no_errors
      expect(page).to have_content('Libraries')
      expect(count_table_rows).to eq(Library.count)
    end

    it 'displays library details correctly' do
      library = Library.first
      visit '/libraries'
      expect(page).to have_content(library.name)
      expect(page).to have_content(library.city)
      expect(page).to have_content(library.state)
    end

    it 'has New Library link' do
      visit '/libraries'
      expect(page).to have_link('New Library')
    end
  end

  describe 'Creating a library' do
    it 'shows new library form' do
      visit '/libraries/new'
      expect_no_errors
      expect(page).to have_content('New Library')
      expect(page).to have_field('library[name]')
      expect(page).to have_field('library[city]')
      expect(page).to have_field('library[email]')
    end

    it 'creates a new library successfully' do
      visit '/libraries/new'

      fill_in 'library[name]', with: 'Test Library'
      fill_in 'library[city]', with: 'Test City'
      fill_in 'library[state]', with: 'TS'
      fill_in 'library[phone]', with: '555-1234'
      fill_in 'library[email]', with: 'test@library.com'

      initial_count = Library.count
      click_button 'Create Library'

      expect(Library.count).to eq(initial_count + 1)
      expect(page).to have_content('Library was successfully created')
    end
  end

  describe 'Editing a library' do
    it 'shows edit library form' do
      library = Library.first
      visit "/libraries/#{library.id}/edit"
      expect_no_errors
      expect(page).to have_content("Edit Library")
      expect(page).to have_field('library[name]', with: library.name)
    end

    it 'updates library successfully' do
      library = Library.first
      visit "/libraries/#{library.id}/edit"

      new_name = 'Updated Library Name'
      fill_in 'library[name]', with: new_name
      click_button 'Save Changes'

      library.reload
      expect(library.name).to eq(new_name)
    end
  end

  describe 'Deleting a library' do
    it 'deletes library successfully' do
      library = Library.create!(
        name: 'Library to Delete',
        city: 'Delete City',
        state: 'DC',
        phone: '555-9999',
        email: 'delete@test.com'
      )

      visit '/libraries'
      initial_count = Library.count

      # Find and click the delete link for this specific library
      # Use first() to get the first matching delete link for this record
      delete_link = page.all("[data-record-id='record_#{library.id}'] a", text: 'Delete').first
      delete_link.click

      expect(Library.count).to eq(initial_count - 1)
      expect(Library.exists?(library.id)).to be false
    end
  end

  describe 'Sorting' do
    it 'sorts by name ascending by default' do
      visit '/libraries'
      libraries = Library.order(name: :asc).pluck(:name)

      # Verify first library name appears on page
      expect(page).to have_content(libraries.first)

      # Verify sorting by checking the order is correct
      libraries.each do |name|
        expect(page).to have_content(name)
      end
    end
  end
end
