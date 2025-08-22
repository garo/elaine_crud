# ElaineCrud Troubleshooting Guide

## Form Changes Not Being Saved

If you're experiencing issues where form changes are not being saved when you click "Save Changes", here's how to diagnose and fix the problem:

### Step 1: Enable Debug Logging

The latest version of ElaineCrud includes detailed debug logging. Check your Rails development log after attempting to save changes. Look for lines starting with "ElaineCrud:".

### Step 2: Check Your Controller Configuration

Add this line to your controller's action (temporarily) to see the configuration:

```ruby
class MeetingsController < ElaineCrud::BaseController
  model Meeting
  permit_params :title, :start_time, :end_time
  
  def index
    debug_configuration  # Add this temporarily
    super
  end
end
```

This will output configuration details to your console.

### Step 3: Common Issues and Solutions

#### Issue 1: `permit_params` called before `model`
**Problem**: If you call `permit_params` before setting the model, foreign keys won't be auto-included.

**Wrong**:
```ruby
permit_params :title, :start_time
model Meeting  # Model set after permit_params
```

**Correct**:
```ruby
model Meeting
permit_params :title, :start_time  # Foreign keys auto-included
```

**Note**: Recent versions automatically handle this, but it's still best practice to call `model` first.

#### Issue 2: Missing permitted parameters
**Problem**: The field you're trying to update isn't in the permitted parameters list.

**Solution**: Add the field to `permit_params`:
```ruby
permit_params :title, :start_time, :end_time, :description
# Foreign keys like :meeting_room_id are automatically included
```

#### Issue 3: Validation errors
**Problem**: The model has validation errors that prevent saving.

**Check**: Look in your Rails log for lines like:
```
ElaineCrud: Record update failed with errors: ["Title can't be blank"]
```

**Solution**: Fix the validation errors or adjust your model validations.

#### Issue 4: Parameter namespace issues
**Problem**: Form parameters aren't being submitted under the correct model name.

**Check**: Look for log lines like:
```
ElaineCrud: Looking for params under key 'meeting'
ElaineCrud: Available param keys: ["utf8", "authenticity_token", "commit"]
ElaineCrud: No parameters found for model 'meeting'
```

**Solution**: This usually indicates a form submission issue. Check that your model name matches expectations.

### Step 4: Manual Debugging

If the automatic debugging isn't sufficient, you can add this to your controller:

```ruby
def update
  Rails.logger.info "Raw params: #{params.inspect}"
  Rails.logger.info "Record params: #{record_params.inspect}"
  Rails.logger.info "Permitted attributes: #{permitted_attributes.inspect}"
  super
end
```

### Step 5: Common Log Patterns and Their Meanings

#### Successful Update
```
ElaineCrud: Attempting to update with params: {:title=>"New Title", :meeting_room_id=>2}
ElaineCrud: Record updated successfully: {"id"=>1, "title"=>"New Title", "meeting_room_id"=>2}
```

#### Missing Parameters
```
ElaineCrud: Looking for params under key 'meeting'
ElaineCrud: No parameters found for model 'meeting'
ElaineCrud: Attempting to update with params: {}
```
**Fix**: Check form submission and parameter names.

#### Validation Errors
```
ElaineCrud: Record update failed with errors: ["Title can't be blank", "Meeting room must exist"]
```
**Fix**: Ensure required fields are filled and foreign key references are valid.

#### Permission Issues
```
ElaineCrud: Permitted attributes: [:title]
ElaineCrud: Attempting to update with params: {:title=>"New Title"}
```
**Fix**: Add missing fields to `permit_params` (foreign keys should be auto-included).

### Step 6: Browser Developer Tools

1. Open your browser's developer tools (F12)
2. Go to the Network tab
3. Attempt to save changes
4. Look for the POST request to your update action
5. Check the request payload to see what parameters are being sent

### Step 7: Test with Rails Console

You can test parameter handling directly:

```ruby
# In rails console
controller = YourController.new
controller.params = ActionController::Parameters.new({
  your_model_name: { title: "Test", meeting_room_id: 1 }
})
puts controller.send(:record_params).inspect
```

### Step 8: Minimal Test Case

Create a minimal controller to isolate the issue:

```ruby
class TestController < ElaineCrud::BaseController
  model YourModel  # Replace with your actual model
  permit_params :title  # Add your basic fields
  
  def index
    debug_configuration
    super
  end
end
```

Add a route and test with this minimal setup.

## Getting Help

If you're still experiencing issues:

1. **Check the logs**: Include relevant log output in your issue report
2. **Share your controller**: Include your controller code
3. **Share your model**: Include relevant model code (relationships, validations)
4. **Share the form**: Include the HTML form being submitted
5. **Browser network info**: Include details from browser developer tools

The debug logging should give you enough information to identify the root cause of the issue.