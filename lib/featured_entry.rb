require 'mysql'
require 'ruby-debug'


cf = ['10154869', '10164409', '10166499', '10164927', '10163408', '10164959', '10162371', '10162518', '10168313']
ch = 'B9001976'

hdf= ['10166034', '10167002','10155405', '10163156', '10157665', '10154954','10173203','10143877','10160772','10169523','10174031','10152255']
hdh= '10172122' 
 
con = Mysql.new('jaguar', 'maryam', 'sCbub3675NWnNZK2', 'firehose_development')
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

rs1 = con.query("select id from products where sku=\'#{ch}\'")
rs1.each_hash{|h| id_hdh<<h['id']}


id_cf.each do |i|
    rs2 = con.query("INSERT INTO bin_specs (product_id, name, value, product_type) values (#{i}, \'featured\', 1, \'camera_bestbuy\')")
end

rs2 = con.query("INSERT INTO bin_specs (product_id, name, value, product_type) values (#{id_ch[0]}, \'hero\', 1, \'camera_bestbuy\')")

id_hdf.each do |i|
    rs2 = con.query("INSERT INTO bin_specs (product_id, name, value, product_type) values (#{i}, \'featured\', 1, \'drive_bestbuy\')")
end    

rs2 = con.query("INSERT INTO bin_specs (product_id, name, value, product_type) values (#{id_hdh[0]}, \'hero\', 1, \'drive_bestbuy\')")