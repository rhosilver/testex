# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'time'
class Asset
  include Rhom::PropertyBag

# Uncomment the following line to enable sync with Asset.
# enable :sync

##########################
### MODEL DEFINITION
##########################
# This lists attrbutes used, so we can keep track of them in one place
# No real code is required
#
# Attributes: Name, Descr, Notes, Instr, State, Date, Picture
# Special Attributes: 
#     Date    - Should be handled as Time class, not text string
#     State   - Valid states are Pass, Fail, Skip. Evertyhing else should result in "Bad" state
#               Should also provide some visualization information
#     Picture - [Added later] Should optionally provide placeholder image, when no real pic present.


##########################
### ERROR HANDLING
##########################
# Our views are expecting data in certain format.
# But we're using property bag: what if the record just doesn't have the value?
# (Plus, everything is stored as text)
# This could cause a crash in the view (for example, parsing non-existent date)
# We can either have lots of safety checks in the views/controllers... 
# ...Or we could implement everything in the model, thus having a single point of control
# This decision is just one of many ways to solve this problem
#
# Here, we're just ensuring we're getting a string, even if it's an empty string (nil.to_s)
def Instr()   return @vars[:Instr].to_s               end
def Notes()   return @vars[:Notes].to_s               end


# SELF STUDY: Or you could go Ruby ninja and do this. Google it.
# [:Name, :Descr, :Notes, :Instr].each do |prop|
#   define_method(prop.to_s) do return @vars[prop].to_s end
# end    

# Valid states are Pass, Fail, Skip. Evertyhing else should result in "Bad" state
# We want to keep this as class variable and expose it to outside world
@@valid_states = ["Pass", "Fail", "Skip"]
@@BAD_STATE = "N/A"

def State()   return @@valid_states.include?(@vars[:State]) ? @vars[:State] : @@BAD_STATE end
# Some support functions for the outside world
def self.valid_states()   return @@valid_states.clone       end   # Without 'clone' will return a pointer to the original array. We want a 'real' copy.
def self.BAD_STATE()      return @@BAD_STATE                end
def self.valid_state?(s)  return @@valid_states.include?(s) end

##########################
### DATE HANDLING
##########################
# We want Date to be Date (Time class), not string
# We need to check that the date is valid (i.e. parseable)
# If not - either return a 'magic' date or empty string
@@BAD_TIME = Time.parse("-0001-01-01")

# Ensure Date returns either a 'magic'date or a string (just like other methods)
def Date(placeholder = nil)
  return Time.parse(@vars[:Date]) rescue (placeholder)? @@BAD_TIME : ""
end  

# This function is for Display purposes. It always returns string.
# Do not use it in calculations, as it may return a non-date string. Or implement extra safety checks
def insp_date (opt = :full)

  d = self.Date(:placeholder)
  return "N/A" if d == @@BAD_TIME
  
  case opt
    when :day     then return d.strftime('%Y-%m-%d')
    when :time    then return d.strftime('%H-%M-%S')
    when :full    then return d.strftime('%Y-%m-%d, %H:%M:%S')
    else          return d.to_s
  end  
end

# Expose BAD_TIME to the outside world
# So external logic in views and controllers can use it as well
# Because this is CLASS method (self.), BAD_TIME has to be CLASS variable (@@)
def self.BAD_TIME()  return @@BAD_TIME   end 

###############################################
### PICTURE/PHOTO HANDLING (FOR CAMERA, ETC)
###############################################
# If asset has no picture - optionally return placeholder
# "No picture" means empty  field (nil) or empty string ('')
# Luckily, nil.to_s == '' in Ruby, so we can combine both checks in one
def Picture(placeholder = false)
  p = (placeholder) ? "/public/images/_img_placeholder.jpg" : ""
  return @vars[:Picture].to_s.empty? ? p : "/"+@vars[:Picture].sub(Rho::Application.bundleFolder,'')
end

###############################################
# HOMEWORK
###############################################
# Every time Camera API takes or chooses a picture, it's saved in app's db/db-files folder
# These images are not deleted automatically, so the folder may grow incredibly large very quickly
# We choose to overload the standard model method 'update_attributes' to delete the image file when the picture has changed or was deleted (i.e. also 'changed' in a way)
# We still want to call the original method. Thankfully, Ruby has power to do so using alias_method to 'preserve' the original method handler
# Writing this in C would require tons of *s :)
alias_method :update_attributes_orig, :update_attributes
def update_attributes(update_hash)
  
  if update_hash['Picture']
    # This is equivalent to: old_url = @vars[:Picture] ? @vars[:Picture] : ''
    old_url = @vars[:Picture] || ''
    File.delete(old_url) if File.exists?(old_url) && update_hash['Picture'] != old_url
  end

  update_attributes_orig(update_hash)
end
  
end
