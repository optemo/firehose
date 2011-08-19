require 'mysql'
require 'ruby-debug'


cf = ['10162518', '10162519', '10162508', '10168312', '10168313', '10164435', '10148290', 'B9002186', 'B9002187', 'B9002188', 'B9002189', 'B9002190', 'B9002191', 'B9002192', 'B9002193', 'B9002195', '10164936', '10164411', '10164410', '10164404', '10169791', '10164408', '10164409', '10154869']
ch = '10162368'

hdf= ['10155406', '10172169', '10172168', '10129706', '10150284', '10167002', '10143880', '10143882', '10176197', '10171542', '10167617', '10151715']
hdh= '10174568' 
 
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