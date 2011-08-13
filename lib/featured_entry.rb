require 'mysql'
require 'ruby-debug'


cf = ['10164923', '10164936', '10164978', '10164837', '10164965', '10163408', '10164960', '10164410', '10173488']
ch = 'B9002146'

hdf= ['10166034', '10172169', '10172168', '10174568', '10150284', '10167002', '10143880', '10143882', '10160772', '10171551', '10171542', '10155407']
hdh= '10170034' 
 
con = Mysql.new('slicehost', 'optemo', '***REMOVED***', 'firehose_production')
id_cf = []
id_ch = []
id_hdf = []
id_hdh = []
 
rs3 = con.query("delete from bin_specs where name=\'featured\' or name=\'hero\'");

cf.each do |s| 
    rs1 = con.query("select id from products where sku=\'#{s}\'")
    rs1.each_hash{|h| id_cf << h['id']} 
end 

rs1 = con.query("select id from products where sku=\'#{ch}\'")
rs1.each_hash{|h| id_ch<<h['id']}


hdf.each do |s| 
    rs1 = con.query("select id from products where sku=\'#{s}\'")
    rs1.each_hash{|h| id_hdf << h['id']} 
end 

rs1 = con.query("select id from products where sku=\'#{hdh}\'")
rs1.each_hash{|h| id_hdh<<h['id']}


id_cf.each do |i|
    rs2 = con.query("INSERT INTO bin_specs (product_id, name, value, product_type) values (#{i}, \'featured\', 1, \'camera_bestbuy\')")
end

rs2 = con.query("INSERT INTO bin_specs (product_id, name, value, product_type) values (#{id_ch[0]}, \'hero\', 1, \'camera_bestbuy\')")

id_hdf.each do |i|
    rs2 = con.query("INSERT INTO bin_specs (product_id, name, value, product_type) values (#{i}, \'featured\', 1, \'drive_bestbuy\')")
end    
rs2 = con.query("INSERT INTO bin_specs (product_id, name, value, product_type) values (#{id_hdh[0]}, \'hero\', 1, \'drive_bestbuy\')")