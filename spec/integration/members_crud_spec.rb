# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Members CRUD', type: :feature do
  before(:each) do
    reset_database
  end

  describe 'Index page' do
    it 'displays all members' do
      visit '/members'
      expect_no_errors
      expect(page).to have_content('Members')
      expect(count_table_rows).to eq(Member.count)
    end

    it 'displays membership type dropdown options' do
      member = Member.first
      visit '/members'
      expect(page).to have_content(member.membership_type)
    end

    it 'displays active status' do
      visit '/members'
      expect(page).to have_content('Active')
    end

    it 'displays email as mailto link' do
      member = Member.first
      visit '/members'
      expect(page).to have_selector("a[href='mailto:#{member.email}']")
    end
  end

  describe 'Creating a member' do
    it 'shows new member form with membership type dropdown' do
      visit '/members/new'
      expect_no_errors
      # Check that membership type select exists with expected options
      expect(page).to have_select('member[membership_type]')
      %w[Standard Premium Student Senior].each do |option|
        expect(page).to have_select('member[membership_type]', with_options: [option])
      end
    end

    it 'creates a new member successfully' do
      visit '/members/new'

      fill_in 'member[name]', with: 'Test Member'
      fill_in 'member[email]', with: 'test@member.com'
      fill_in 'member[phone]', with: '555-0000'
      select 'Premium', from: 'member[membership_type]'
      select Library.first.name, from: 'member[library_id]'
      check 'member[active]'

      initial_count = Member.count
      click_button 'Create Member'

      expect(Member.count).to eq(initial_count + 1)
    end
  end

  describe 'Editing a member' do
    it 'updates member successfully' do
      member = Member.first
      visit "/members/#{member.id}/edit"

      select 'Student', from: 'member[membership_type]'
      click_button 'Save Changes'

      member.reload
      expect(member.membership_type).to eq('Student')
    end
  end

  describe 'Deleting a member' do
    it 'deletes member successfully' do
      member = Member.create!(
        name: 'Member to Delete',
        email: 'delete@member.com',
        phone: '555-9999',
        membership_type: 'Standard',
        library: Library.first,
        active: true
      )

      visit '/members'
      initial_count = Member.count

      # Find delete link within the turbo-frame for this record
      within("turbo-frame#record_#{member.id}") do
        click_button 'Delete'
      end

      expect(Member.count).to eq(initial_count - 1)
    end
  end
end
