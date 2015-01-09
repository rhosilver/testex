require 'rho/rhocontroller'
require 'helpers/browser_helper'

require 'time' # We need this to deal with time



class AssetController < Rho::RhoController
  include BrowserHelper

  ####################################
  # MAIN ASSET INDEX
  # GETS MODIFIED MULTIPLE TIMES
  # MAINLY DURING THE 'WIP CHECKBOX' and AJAX EXERCISES
  # GET /Asset
  ####################################
  def index
     
    q_conditions = {}
    @q_state = "off"

    # The 'q_state' and 'q_conditions' are added in the 'WIP Checkbox' exercise
    case @params['q_state']
      when "Pass"   then q_conditions = {:State => "Pass"}
      when "WIP"    then q_conditions = {{:name => :State, :op => "IN"} => ["Skip", "Fail"] }
                         @q_state = "on"
    end 
    
    @assets = Asset.find(:all, :conditions => q_conditions)

    # The 'partial' support is added  during AJAX exercises
    if @params['partial'] then  render :partial => "asset_list"
    else                        render :action => :index, :back => '/app'
    end

  end

  ####################################
  ### DEFAULTS, WE DON'T TOUCH THESE
  ####################################

  # GET /Asset/new
  def new
    @asset = Asset.new
    render :action => :new, :back => url_for(:action => :index)
  end

  # GET /Asset/{1}/edit
  def edit
    @asset = Asset.find(@params['id'])
    if @asset then render :action => :edit, :back => url_for(:action => :index)
    else           redirect :action => :index end
  end

  # POST /Asset/create
  def create
    @asset = Asset.create(@params['asset'])
    redirect :action => :index
  end

  # POST /Asset/{1}/delete
  def delete
    @asset = Asset.find(@params['id'])
    @asset.destroy if @asset
    redirect :action => :index  
  end

  # GET /Asset/{1}
  def show
    @asset = Asset.find(@params['id'])
    if @asset then render :action => :show, :back => url_for(:action => :index)
    else           redirect :action => :index  end
  end

  ####################################
  ### INSPECT AND EDIT SCREEN SUPPORT
  ####################################

  # This supports EDIT screen 'update' button
  # Generic 'update' method modified to do some extra date handling
  # POST /Asset/{1}/update
  def update
    @asset = Asset.find(@params['id'])
      
    if @asset
      # Assembled date from 3 separate select controls
      # Overwrites the old date, if the new one is different
      # This code can be compacted, and change can be made unconditional
      # Can also add time processing
      new_date_str = "#{@params['d-year']}-#{@params['d-month']}-#{@params['d-day']}"
      old_date_str = @asset.insp_date(:day)
      @params['asset']['Date'] = new_date_str if new_date_str != old_date_str

      @asset.update_attributes(@params['asset'])
    end
    
    redirect :action => :index
  end

  # This supports INSPECT screen (show.erb) 'inspect' button
  # It uses different business logic to update model data
  def inspect_update
    @asset = Asset.find(@params['id'])
      
    if @asset
      
      new_date = Time.now
      # Because Ruby doesn't require ';' to separate code lines, it's important to leave '+' hanging, when splitting the lines
      new_notes = "==[#{new_date.strftime('%Y-%m-%d, %H:%M:%S')} : #{@params['asset']['State']} : #{Login.login_fullname} ]==\n" + 
                  @params['asset']['Notes'] + "\n\n" + 
                  @asset.Notes

      @asset.update_attributes(@params['asset'])
      @asset.update_attributes(:Date => new_date, :Notes => new_notes) # could have directly inserted new values into @params['asset'] like in previous example, but want to demonstrate a different approach
    end
    
    redirect :action => :index
  end

  ####################################
  ### THE 'WIP CHECKBOX' EXERCISE
  ### ALSO SEE THE AJAX SECTION BELOW
  ### ALL THESE ARE EVENTUALLY ROLLED INTO OTHER CODE AND LEFT UNUSED
  ####################################

  # Shows Passed objects
  # Later rolled into index_param
  def index_pass
    @assets = Asset.find(:all, :conditions => {:State => "Pass"})
    render :action => :index, :back => '/app'
  end

  # Shows WIP objects
  # Later rolled into index_param
  def index_wip
    @assets = Asset.find(:all, :conditions => { {:name => :State, :op => "IN"} => ["Skip", "Fail"] })
    render :action => :index, :back => '/app'
  end

  # Shows Passed, WIP or All objects
  # Later rolled into 'main' index method
  def index_param 
    q_conditions = {}

    case @params['q_state']
      when "Pass"   then q_conditions = {:State => "Pass"}                                   
      when "WIP"    then q_conditions = {{:name => :State, :op => "IN"} => ["Skip", "Fail"] }
      else               q_conditions = {}
    end 

    @assets = Asset.find(:all, :conditions => q_conditions)
    render :action => :index, :back => '/app'
  end

  ####################################
  ### AJAX (XHR) EXERCISES
  ### Also look at the index method, as it has AJAX support built it as part of the exercise
  ####################################

  # This one is later rolled into the main 'index'
  def index_ajax
    @assets = Asset.find(:all)
    render :back => '/app'
  end

  def request_details
    @asset = Asset.find(@params['id'])
      
  # Initially we use the below commented line 
  # ...and then 'fix' it with the right (uncommented) line with 'partial'
    #render :action => "notes_ajax"
    render :partial => "notes_ajax"
  end

  ####################################
  ### ADVANCED RENDERING EXAMPLES
  ### (STRING, JSON)
  ### FOR SELF-STUDY
  #####################################

  # Returns string, normally called via XHR
  def render_string
    str = "42"
    render :string => str, :layout => false
  end

  # Returns JSON array, normally called via XHR
  def render_json
    hash = { :val1 => :param1, :val2 => :param2,
             :inner_hash => {:inner_val1 => :etc}
    }
    render :string => hash.to_json, :layout => false,
           :content_type => "application/json"
  end

  # Typical way of returning model data via XHR
  # This one returns entire record, can be made to return a particular field.
  def find_asset_json
    res = Asset.find(@params['id'])
    render :string => res.to_json, :content_type => "application/json", :layout => false
  end


  ####################################
  ### CAMERA HANDLING
  ####################################
  
  def get_a_pic
    if (Rho::System.isRhoSimulator)  # We only care about RhoSim. Native emulators will have their own means to emulate camera
          Camera::choose_picture(url_for :action => :camera_callback)
    else  Camera::take_picture  (url_for :action => :camera_callback)
    end
  end  


  def camera_callback
    if (@params['status'] == "ok") && @params['image_uri']
        # convert URI to a file path, Update the View
        puts "XXXX URI: " + @params['image_uri']
        pictureURI = Rho::Application.expandDatabaseBlobFilePath(@params['image_uri'])
        pictureSRC = pictureURI.sub(Rho::Application.bundleFolder,'') 
        puts "XXXX URI: " + pictureURI
        puts "XXXX SRC: " + pictureSRC
        WebView.execute_js("update_pic('#{pictureURI}','/#{pictureSRC}')")
    elsif @params['status'] == "cancel"
      Alert.show_popup("User cancelled action!")
    end
  end

  ####################################
  ### BARCODE HANDLING
  ### MOST OF BARCODE HANDLING IS JS
  ### CHECK THE VIEW FILES FOR JS CODE
  ####################################
  
  # This looks object via scanned barcode 
  # First, check for Inv# match, the Serial# match
  # We could use "OR" operation: Inv# == param OR SN == param
  # But we want to ensure Inv# gets priority
  # We could have also modified the standard 'show' method, just as we've done with 'index' method
  def show_by_param

    @asset = nil;
    @asset = Asset.find(:first, :conditions => {:InvN => @params['param']}) if @params['param']
    @asset = Asset.find(:first, :conditions => {:SN   => @params['param']}) unless @asset
      
    if @asset 
      # Since this is XHR, we cannot use redirect
      Rho::WebView.navigate ( url_for :action => :show, :id => @asset.object )
    else
      Rho::Notification.showStatus("show_by_param", "Error: nothing found", "OK")
    end

  end
end
