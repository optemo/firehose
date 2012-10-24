task :switch_facet_ordering => :environment do
  existing_facets = Facet.where(used_for: "ordering")
  existing_facets.each do |f|
    f.used_for = f.feature_type
    f.feature_type = 'Ordering'
  end
  existing_facets.map(&:save)
end