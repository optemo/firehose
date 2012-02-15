#def set_missing_ids ()
#  #finds largest id number, sets the new id to this+2
#  new_id = DailySpec.select(:id).max.id + 2
#  #only alters rows with id = 0
#  for i in DailySpec.find_all_by_id(0)
#    sku = i.sku
#    date = i.date
#    debugger
#    DailySpec.update_all(:id => new_id, :conditions => {:id => 0, :sku => sku, :date => date}, :limit => 1)
#    new_id += 2
#  end
#end

#def set_missing_ids ()
# #finds largest id number, sets the new id to this+2
# new_id = DailySpec.select(:id).max.id + 2
# #only alters rows with id = 0
# for i in DailySpec.find_all_by_id(0)
#   debugger  
#   ds = i
#   ds = DailySpec.new(i.attributes)
#   ds.id = new_id    #id is not being set! (works if only 1 zero row, not if multiple)
#   ds.save
#   new_id += 2
# end
#end

def set_missing_ids ()
 #possible fix at:  http://railsforum.com/viewtopic.php?id=14250  ?
end