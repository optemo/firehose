class Session
  # products.yml gets parsed below, initializing these variables.
  cattr_accessor :id, :search  # Basic individual data. These are not set in initialization.
  cattr_accessor :directLayout, :mobileView  # View choice (Assist vs. Direct, mobile view vs. computer view)
  cattr_accessor :continuous, :binary, :categorical, :binarygroup, :prefered, :utility  # Caching of features' names
  cattr_accessor :prefDirection, :maximum, :minimum, :utility_weights, :cluster_weights  # Stores which preferences are 'lower is better' vs. normal; used in sorting, plus some attribute globals
  cattr_accessor :dragAndDropEnabled, :relativeDescriptions, :numGroups  # These flags should probably be stripped back out of the code eventually
  cattr_accessor :product_type # Product type (camera_us, etc.), used everywhere
  cattr_accessor :piwikSiteId # Piwik Site ID, as configured in the currently-running Piwik install.
  cattr_accessor :ab_testing_type # Categorizes new users for AB testing
  cattr_accessor :category_id

  def initialize (url = nil)
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
    self.binarygroup = Hash.new{|h,k| h[k] = []}
    self.prefered = Hash.new{|h,k| h[k] = []}
    self.utility = Hash.new{|h,k| h[k] = []} 
    self.utility_weights = Hash.new(1)
    self.cluster_weights = Hash.new(1)
    
    p_url = nil

    unless url.nil?
      Url.find_each do |u|
        if u.url==url
          p_url = u
          break
        end
      end
    end

    p_type = p_url.nil?? ProductType.find_all_by_name('camera_bestbuy').first : p_url.product_type
    
    self.product_type = p_type.name

    

    self.category_id = p_type.category_id_product_type_maps.map{ |x| x.category_id }
    
    # directLayout controls the presented view: Optemo Assist vs. Optemo Direct. 
    # Direct needs no clustering, showing all products in browseable pages and offering "group by" buttons.
    # mobileView controls screen vs. mobile view (Optemo Mobile)
    # Default is false

    self.directLayout = p_type.layout.include?("direct")
    self.mobileView = p_type.layout.include?("mobileview")

    # Check for what Piwik site ID to put down in the optemo.html.erb layout
    # These site ids MUST match what's in the piwik database.

    p_url ||= p_type.urls.first
    self.piwikSiteId = p_url.piwik_id || 10 # This is a catch-all for testing sites.
    
    # This block gets out the continuous, binary, and categorical features
    p_headings = Heading.find_all_by_product_type_id(p_type.id, :include => :features) # eager loading headings and features to reduce the queries.
    p_headings.each do |heading|
      heading.features.each do |feature|
        used_fors = feature.used_for.split(',').map { |uf| uf.strip }
        case feature.feature_type
        when "Continuous"
            used_fors.each{|flag| self.continuous[flag] << feature.name}
          self.continuous["all"] << feature.name #Keep track of all features
          self.prefDirection[feature.name] = feature.larger_is_better ? 1 : -1
          self.maximum[feature] = feature.max if feature.max > 0
          self.minimum[feature] = feature.min if feature.min > 0
        when "Binary"
          used_fors.each{|flag| self.binary[flag] << feature.name; self.binarygroup[heading.name] << feature.name if flag == "filter"}
          self.binary["all"] << feature.name #Keep track of all features
          self.prefered[feature.name] = feature.prefered if !feature.prefered.nil? && !feature.prefered.empty?
        when "Categorical"
          used_fors.each{|flag| self.categorical[flag] << feature.name}
          self.categorical["all"] << feature.name #Keep track of all features
          self.prefered[feature.name] = feature.prefered if !feature.prefered.nil? && !feature.prefered.empty?
        end
         self.utility_weights[feature.name] = feature.utility_weight if feature.utility_weight > 1
         self.utility["all"] << feature.name if feature.utility_weight > 1
         self.cluster_weights[feature.name] = feature.cluster_weight if feature.cluster_weight > 1
      end
    end
  end
end
