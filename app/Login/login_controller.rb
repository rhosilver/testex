require 'rho'
require 'rho/rhocontroller'
require 'rho/rhoerror'
require 'helpers/browser_helper'

class LoginController < Rho::RhoController
  include BrowserHelper
  
  def index
    @msg = @params['msg']
    render
  end

    
  def do_login
    if Login.do_login(@params['login'], @params['password'])
      redirect Rho::Application.startURI
    else
      @msg = "Incorrect username or password"
      render :action => :index
    end 
  end
 
end
