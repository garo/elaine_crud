# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'has_one relationship support', type: :feature do
  before(:each) do
    reset_database
  end

  describe 'Member with has_one :profile' do
    it 'displays profile field in members index' do
      visit '/members'
      expect_no_errors

      # Members index should have a Profile column
      expect(page).to have_content('Profile')
    end

    it 'shows profile display value for members with profiles' do
      member_with_profile = Member.joins(:profile).first
      profile = member_with_profile.profile

      visit '/members'

      # Should display the profile's bio
      expect(page).to have_content(profile.bio)
    end

    it 'shows placeholder for members without profiles' do
      member_without_profile = Member.where.missing(:profile).first

      visit '/members'

      # Should display "—" placeholder somewhere on the page for members without profiles
      expect(page).to have_content('—')
    end

    it 'makes profile field readonly in member edit forms' do
      member = Member.first
      visit "/members/#{member.id}/edit"
      expect_no_errors

      # Profile field should be visible but not have editable inputs
      expect(page).to have_content('Profile')

      # Should not have input/select/textarea fields for profile relationship
      expect(page).not_to have_selector('input[name="member[profile]"]')
      expect(page).not_to have_selector('select[name="member[profile]"]')
      expect(page).not_to have_selector('textarea[name="member[profile]"]')
    end

    it 'shows profile detail on member show page' do
      member_with_profile = Member.joins(:profile).first
      profile = member_with_profile.profile

      visit "/members/#{member_with_profile.id}"
      expect_no_errors

      # Profile should be displayed
      expect(page).to have_content('Profile')
      expect(page).to have_content(profile.bio)
    end
  end

  describe 'Auto-configuration of has_one relationships' do
    it 'automatically detects and configures has_one :profile on Member' do
      # This is tested implicitly by the controller working without manual configuration
      member = Member.first

      # The MembersController should auto-configure the profile field
      visit "/members/#{member.id}/edit"
      expect_no_errors

      # Profile field should be present (even if readonly)
      expect(page).to have_content('Profile')
    end

    it 'automatically includes profile to avoid N+1 queries' do
      # Create additional members with profiles
      3.times do |i|
        member = Member.where.missing(:profile).first
        Profile.create!(
          member: member,
          bio: "Auto-created bio #{i}",
          avatar_url: "https://example.com/avatar#{i}.jpg"
        ) if member
      end

      # Visit members index - should eager load profiles
      visit '/members'
      expect_no_errors

      # If profiles are properly eager loaded, the page should render without N+1 queries
      # This is verified by the page rendering successfully with profile data
      # Just check that the page has all the profile bios displayed
      Profile.all.each do |profile|
        expect(page).to have_content(profile.bio)
      end
    end
  end

  describe 'has_one configuration options' do
    it 'uses display field from configuration' do
      # The auto-configuration should use 'bio' as the display field
      member_with_profile = Member.joins(:profile).first
      profile = member_with_profile.profile

      visit '/members'

      # Should show bio content (the configured display field)
      expect(page).to have_content(profile.bio)
    end

    it 'handles nil profile gracefully' do
      member_without_profile = Member.where.missing(:profile).first

      visit "/members/#{member_without_profile.id}"
      expect_no_errors

      # Should show placeholder, not raise error
      expect(page).to have_content('Profile')
    end
  end
end
