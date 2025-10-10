# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Profiles CRUD - has_one relationship', type: :feature do
  before(:each) do
    reset_database
  end

  describe 'Index page' do
    it 'displays all profiles' do
      visit '/profiles'
      expect_no_errors
      expect(page).to have_content('Profiles')
      expect(count_table_rows).to eq(Profile.count)
    end

    it 'displays member relationship (belongs_to)' do
      profile = Profile.first
      visit '/profiles'
      expect(page).to have_content(profile.member.name)
    end

    it 'displays bio field' do
      profile = Profile.first
      visit '/profiles'
      # Bio may be truncated in the display, so check for the first part
      expect(page).to have_content(profile.bio.truncate(50))
    end
  end

  describe 'Creating a profile' do
    it 'shows new profile form with member dropdown' do
      visit '/profiles/new'
      expect_no_errors
      # Check that member_id select exists
      expect(page).to have_select('profile[member_id]')
    end

    it 'creates a new profile successfully' do
      visit '/profiles/new'

      select Member.last.name, from: 'profile[member_id]'
      fill_in 'profile[bio]', with: 'Test bio for new profile'
      fill_in 'profile[avatar_url]', with: 'https://example.com/avatar.jpg'

      initial_count = Profile.count
      click_button 'Create Profile'

      expect(Profile.count).to eq(initial_count + 1)
    end
  end

  describe 'Editing a profile' do
    it 'updates profile successfully' do
      profile = Profile.first
      visit "/profiles/#{profile.id}/edit"

      fill_in 'profile[bio]', with: 'Updated bio content'
      click_button 'Save Changes'

      profile.reload
      expect(profile.bio).to eq('Updated bio content')
    end
  end

  describe 'Deleting a profile' do
    it 'deletes profile successfully' do
      member_without_profile = Member.where.missing(:profile).first
      profile = Profile.create!(
        member: member_without_profile,
        bio: 'Profile to delete',
        avatar_url: 'https://example.com/delete.jpg'
      )

      visit '/profiles'
      initial_count = Profile.count

      # Find delete link within the turbo-frame for this record
      within("turbo-frame#record_#{profile.id}") do
        click_link 'Delete'
      end

      expect(Profile.count).to eq(initial_count - 1)
    end
  end
end
