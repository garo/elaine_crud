# frozen_string_literal: true

class BookCopiesController < ElaineCrud::BaseController
  layout 'application'

  model BookCopy
  permit_params :book_id, :library_id, :rfid, :available

end
