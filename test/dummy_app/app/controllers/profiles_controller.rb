# frozen_string_literal: true

class ProfilesController < ElaineCrud::BaseController
  layout 'application'

  model Profile
  permit_params :bio, :avatar_url
end
