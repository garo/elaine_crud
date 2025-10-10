# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Librarians CRUD', type: :feature do
  before(:each) do
    reset_database
  end

  describe 'Index page' do
    it 'displays all librarians' do
      visit '/librarians'
      expect_no_errors
      expect(page).to have_content('Librarians')
      expect(count_table_rows).to eq(Librarian.count)
    end

    it 'displays role dropdown values' do
      librarian = Librarian.first
      visit '/librarians'
      expect(page).to have_content(librarian.role)
    end

    it 'displays salary formatted as currency' do
      librarian = Librarian.first
      visit '/librarians'
      # Check for dollar sign (currency formatting)
      expect(page.text).to match(/\$\d+/)
    end

    it 'displays hire date formatted' do
      librarian = Librarian.first
      visit '/librarians'
      formatted_date = librarian.hire_date.strftime("%B %d, %Y")
      expect(page).to have_content(formatted_date)
    end
  end

  describe 'Creating a librarian' do
    it 'shows new librarian form with role dropdown' do
      visit '/librarians/new'
      expect_no_errors
      # Check that role select exists with expected options
      expect(page).to have_select('librarian[role]')
      %w[Manager Assistant Clerk Archivist].each do |option|
        expect(page).to have_select('librarian[role]', with_options: [option])
      end
    end

    it 'creates a new librarian successfully' do
      visit '/librarians/new'

      fill_in 'librarian[name]', with: 'Test Librarian'
      fill_in 'librarian[email]', with: 'test@librarian.com'
      select 'Clerk', from: 'librarian[role]'
      select Library.first.name, from: 'librarian[library_id]'
      fill_in 'librarian[salary]', with: '45000'

      initial_count = Librarian.count
      click_button 'Create Librarian'

      expect(Librarian.count).to eq(initial_count + 1)
    end

    it 'redirects to show page after creating librarian' do
      visit '/librarians/new'

      fill_in 'librarian[name]', with: 'Redirect Test Librarian'
      fill_in 'librarian[email]', with: 'redirect@test.com'
      select 'Assistant', from: 'librarian[role]'
      select Library.first.name, from: 'librarian[library_id]'
      fill_in 'librarian[salary]', with: '48000'

      click_button 'Create Librarian'

      # Should redirect to the show page of the newly created librarian
      new_librarian = Librarian.find_by(email: 'redirect@test.com')
      expect(current_path).to eq("/librarians/#{new_librarian.id}")
      expect(page).to have_content('Redirect Test Librarian')
      expect(page).to have_content('successfully created')
    end
  end

  describe 'Editing a librarian' do
    it 'updates librarian successfully' do
      librarian = Librarian.first
      visit "/librarians/#{librarian.id}/edit"

      select 'Manager', from: 'librarian[role]'
      fill_in 'librarian[salary]', with: '65000'
      click_button 'Save Changes'

      librarian.reload
      expect(librarian.role).to eq('Manager')
      expect(librarian.salary).to eq(65000)
    end
  end

  describe 'Deleting a librarian' do
    it 'deletes librarian successfully' do
      librarian = Librarian.create!(
        name: 'Librarian to Delete',
        email: 'delete@librarian.com',
        role: 'Clerk',
        library: Library.first,
        salary: 40000
      )

      visit '/librarians'
      initial_count = Librarian.count

      # Find delete link within the turbo-frame for this record
      within("turbo-frame#record_#{librarian.id}") do
        click_link 'Delete'
      end

      expect(Librarian.count).to eq(initial_count - 1)
    end
  end
end
