class Session
  # products.yml gets parsed below, initializing these variables.
  cattr_accessor :directLayout, :mobileView  # View choice (Assist vs. Direct, mobile view vs. computer view)
  cattr_accessor :continuous, :binary, :categorical  # Caching of features' names
  cattr_accessor :prefDirection, :maximum, :minimum  # Stores which preferences are 'lower is better' vs. normal; used in sorting, plus some attribute globals
  cattr_accessor :dragAndDropEnabled, :relativeDescriptions, :numGroups  # These flags should probably be stripped back out of the code eventually
  cattr_accessor :product_type # Product type (camera_us, etc.), used everywhere
  cattr_accessor :piwikSiteId # Piwik Site ID, as configured in the currently-running Piwik install.
  cattr_accessor :category_id

  def initialize (url = nil)
    defaultSite = 'bestbuy'
    # This parameter controls whether the interface features drag-and-drop comparison or not.
    self.dragAndDropEnabled = true
    # Relative descriptions, in comparison to absolute descriptions, have been the standard since late 2009, and now we use Boostexter labels also.
    # As of August 2010, I highly suspect that setting this to false breaks the application.
    self.relativeDescriptions = true
    # At one time, this parameter controlled how many clusters were shown.
    self.numGroups = 9
    self.prefDirection = Hash.new(1) # Set 1 i.e. Up as the default value for direction
    self.maximum = Hash.new
    self.minimum = Hash.new
    self.continuous = Hash.new{|h,k| h[k] = []}
    self.binary = Hash.new{|h,k| h[k] = []}
    self.categorical = Hash.new{|h,k| h[k] = []}
    file = YAML::load(File.open("#{Rails.root}/config/products.yml"))
    if url && file[url].blank? # If no www.laserprinterhub.com, try laserprinterhub.com
      split_url = url.split(".")[-2..-1]
      url = split_url.join(".") if split_url
    end
    url = defaultSite if file[url].blank?
    
    product_yml = file[url]
    self.product_type = product_yml["product_type"]
    self.category_id = product_yml["category_id"]
    # directLayout controls the presented view: Optemo Assist vs. Optemo Direct. 
    # Direct needs no clustering, showing all products in browseable pages and offering "group by" buttons.
    # mobileView controls screen vs. mobile view (Optemo Mobile)
    # Default is false
    self.directLayout = product_yml["layout"] == "direct"
    self.mobileView = product_yml["layout"] == "mobileview"

    # Check for what Piwik site ID to put down in the optemo.html.erb layout
    # These site ids MUST match what's in the piwik database.
    self.piwikSiteId = product_yml["site_id"] || 10 # This is a catch-all for testing sites.

    # This block gets out the continuous, binary, and categorical features
    product_yml.each do |feature,atts|
      next if atts.class == Fixnum # This is for the site_id entry
      case atts["feature_type"]
      when "Continuous"
        atts["used_for"].each{|flag| self.continuous[flag] << feature}
        self.continuous["all"] << feature #Keep track of all features
        self.prefDirection[feature] = atts["prefdir"] if atts["prefdir"]
        self.maximum[feature] = atts["max"] if atts["max"]
        self.minimum[feature] = atts["min"] if atts["min"]
      when "Binary"
        atts["used_for"].each{|flag| self.binary[flag] << feature}
        self.binary["all"] << feature #Keep track of all features
      when "Categorical"
        atts["used_for"].each{|flag| self.categorical[flag] << feature}
        self.categorical["all"] << feature #Keep track of all features
      end
    end
	end
end
