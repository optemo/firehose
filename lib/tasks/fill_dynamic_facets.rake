task :fill_dyn_facets => :environment do
  dynamic_facets = []
  
  # Hash of names -> facet_ids (change as needed)
  ids = {
    :dataBuffer => 16368,
    :rotations => 16370,
    :driveSize => 16372,
    :internalExternal => 16374
  }
  
# If interface is ever needed as a dynamic facet:
#    :interface => 20108,                                    # Headings
#    :USB3 => 20110, :USB2 => 20112, :USB => 20114,          # USB
#    :FireWire800 => 20116, :FireWire400 => 20118,           # FireWire
#    :SATA3 => 20120, :SATA2 => 20122, :SATA => 20124,       # Serial ATA
#    :PATA => 20126, :eSATA => 20128,                        # Other ATA
#    :Ethernet => 20130, :WiFi => 20132                      # Internet

  
  # Hash of drive types to relevant facets
  drive_types = {
    "B20237" => [:driveSize, :rotations, :dataBuffer],      # External HD
    "B20239" => [:driveSize, :rotations, :dataBuffer],      # Internal HD
    "B30442" => [:internalExternal],                        # SSD
    "B20236" => [:internalExternal]                         # Optical Drives
  }
  
  # Go through each drive_type, creating the necessary dynamic facet entries
  drive_types.each_pair do |type, facets|
    facets.each do |facet|
      dynamic_facets << DynamicFacet.new(:facet_id => ids[facet], :category => type)
    end
  end
  
  DynamicFacet.import dynamic_facets, :on_duplicate_key_update=>[:facet_id, :category] # Haven't found another way to avoid duplicates
end