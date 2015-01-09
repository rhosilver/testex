### LOGIN ENHANCED

class Login
  include Rhom::PropertyBag

  # Uncomment the following line to enable sync with Login.
  # enable :sync
  @logged_in = false;
  @logon_account = "";
  
  def self.do_login(l_user, l_token)
    res = find(:first, :conditions => {:login => l_user, :password => l_token}, :op => "AND") 
    if (res) then 
      @logon_account = res
      @logged_in = true
      return res.login 
    end
    #Will return nil otherwise
  end

  #Will return nil otherwise
  def self.logged_in?
    return @logged_in
  end

  def self.login_name
    return @logon_account.login if @logged_in
  end

  def self.login_fullname
    return @logon_account.first.to_s + " " + @logon_account.last.to_s if @logged_in
  end

  def self.is_admin?
    return @logged_in && (@logon_account.is_admin == "true")
  end

  def self.initialize_sample_db
    res = Login.find(:first, :conditions => {:login => "admin"})
    res.destroy if res

    res = Login.find(:first, :conditions => {:login => "user"})
    res.destroy if res    

    create(:login => 'admin', :password => 'admin', :first => "Cool" , :last => "Admin", :is_admin => :true )
    create(:login => 'user' , :password => 'user' , :first => "Smart", :last => "User" , :is_admin => :false)
  end

end