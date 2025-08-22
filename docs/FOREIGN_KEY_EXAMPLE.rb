# Example: Meeting Controller with Foreign Key Support
# 
# This example shows how ElaineCrud automatically handles foreign key relationships
# for a Meeting model that belongs_to a MeetingRoom.
#
# Models (example structure):
#
# class Meeting < ApplicationRecord
#   belongs_to :meeting_room
#   
#   validates :title, presence: true
#   validates :start_time, presence: true
# end
#
# class MeetingRoom < ApplicationRecord
#   has_many :meetings
#   
#   validates :name, presence: true
# end

class MeetingsController < ElaineCrud::BaseController
  # Set the model - this automatically detects belongs_to relationships
  model Meeting
  
  # Specify the fields you want to permit for forms
  # Foreign keys (meeting_room_id) are automatically included
  permit_params :title, :description, :start_time, :end_time
  
  # Optional: Customize foreign key display and behavior
  field :meeting_room_id do
    title "Meeting Room"
    foreign_key(
      model: MeetingRoom,
      display: :name,  # Show the 'name' field from MeetingRoom
      null_option: "Choose a room",
      scope: -> { MeetingRoom.available }  # Optional: only show available rooms
    )
  end
  
  # Optional: Customize other fields
  field :title do
    title "Meeting Title"
    description "Enter a descriptive title for the meeting"
  end
  
  field :start_time do
    title "Start Time"
    description "When the meeting begins"
  end
  
  field :end_time do
    title "End Time" 
    description "When the meeting ends"
  end
  
  # Optional: Hide certain fields from display
  field :description do
    visible false  # Won't show in index listing
  end
  
  # Optional: Make fields readonly
  field :created_at do
    visible true
    readonly true
    title "Created"
  end
end

# What happens automatically:
#
# 1. ElaineCrud detects that Meeting belongs_to :meeting_room
# 2. It automatically configures meeting_room_id as a foreign key field
# 3. In the index view, instead of showing "1, 2, 3" for meeting_room_id,
#    it shows the related MeetingRoom's display field (usually name, title, etc.)
# 4. In edit forms, meeting_room_id becomes a dropdown with all MeetingRoom options
# 5. The foreign key is automatically included in permitted_params
# 6. Database queries are optimized with includes() to avoid N+1 queries
#
# Manual configuration options:
#
# field :meeting_room_id do
#   foreign_key(
#     model: MeetingRoom,           # Required: the related model class
#     display: :name,               # Field to show (default: auto-detected)
#     scope: -> { MeetingRoom.active }, # Optional: filter available options
#     null_option: "Select room"    # Optional: placeholder text
#   )
# end
#
# Alternative display options:
#
# field :meeting_room_id do
#   foreign_key(
#     model: MeetingRoom,
#     display: ->(room) { "#{room.name} (#{room.capacity} seats)" }  # Proc for complex display
#   )
# end

# Routes (add to your routes.rb):
# resources :meetings