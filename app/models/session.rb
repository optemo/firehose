class Session
  # products.yml gets parsed below, initializing these variables.
  cattr_accessor :id, :search  # Basic individual data. These are not set in initialization.
  cattr_accessor :directLayout, :mobileView  # View choice (Assist vs. Direct, mobile view vs. computer view)
  cattr_accessor :dragAndDropEnabled, :relativeDescriptions, :numGroups, :extendednav  # These flags should probably be stripped back out of the code eventually
  cattr_accessor :product_type, :product_type_id # Product type (camera_us, etc.), used everywhere
  cattr_accessor :piwikSiteId # Piwik Site ID, as configured in the currently-running Piwik install.
  cattr_accessor :ab_testing_type # Categorizes new users for AB testing
  cattr_accessor :category_id
  cattr_accessor :rails_category_id # This is passed in from ajaxsend and the logic for determining the category ID is from the javascript side rather than from the Rails side. Useful for embedding.
  cattr_accessor :features # Gets out the features which include utility, comparison, filter, cluster, sortby, show

  def initialize (p_type_id = nil, request_url = nil)
    # This parameter controls whether the interface features drag-and-drop comparison or not.
    self.dragAndDropEnabled = true
    # Relative descriptions, in comparison to absolute descriptions, have been the standard since late 2009, and now we use Boostexter labels also.
    # As of August 2010, setting this to false might breaks the application. - ZAT
    self.relativeDescriptions = true
    # At one time, this parameter controlled how many clusters were shown.
    self.numGroups = 9
    self.extendednav = false
    self.features = Hash.new{|h,k| h[k] = []} # Features include utility, comparison, filter, cluster, sortby, show

    # 2 is hard-coded to cameras at the moment and is the default
    # Check the product_types table for details
    p_type = ProductType.find((p_type_id.blank? || p_type_id == "undefined") ? 2 : p_type_id)
    self.product_type = p_type.name
    self.product_type_id = p_type.id
    
    self.category_id = p_type.category_id_product_type_maps.map{|x|x.category_id}
    
    # directLayout controls the presented view: Optemo Assist vs. Optemo Direct. 
    # Direct needs no clustering, showing all products in browseable pages and offering "group by" buttons.
    # mobileView controls screen vs. mobile view (Optemo Mobile)
    # Default is false
    self.directLayout = p_type.layout.include?("direct")
    self.mobileView = p_type.layout.include?("mobileview")

    # Check for what Piwik site ID to put down in the optemo.html.erb layout
    # These site ids MUST match what's in the piwik database.
    p_url = nil  # Initialize variable out here for locality
    p_type.urls.each do |u|
      p_url = u if request_url && request_url[u.url] 
    end
    p_url ||= p_type.urls.first
    self.piwikSiteId = p_url.piwik_id || 10 # This is a catch-all for testing sites.
    Session.set_features #In Firehose there are no dynamic features
  end
  
  def self.set_features(categories = [])
    #if an array of categories is given, dynamic features which apply only to those categories are shown
    dynamically_excluded = []
    # initialize features
    self.features = Facet.where(product_type_id: product_type_id, active: true).includes(:dynamic_facets).order(:value).select do |f|
      #These are the subcategories for which this feature is only used for
      subcategories = f.dynamic_facets.map{|x|x.category}
      subcategories.empty? || #We don't store subcategories for features which are always used
      subcategories.any?{|e| categories.include? e} ||
      (dynamically_excluded << f && false) #If a feature is not selected, we need to note this
    end.group_by(&:used_for)
    # Some filters of last search need to be removed when dynamic filters removed
    unless categories.empty?
      dynamically_excluded.each do |f|
        selection = case f.feature_type
          when "Continuous" then self.search.userdataconts
          when "Categorical" then self.search.userdatacats
          when "Binary" then self.search.userdatabins
        end
        Maybe(selection.select{|ud|ud.name == f.name}.first).destroy
      end
    end
  end
end
