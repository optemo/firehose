require 'mysql'
require 'ruby-debug'


cf = ['10162371', '10164923', '10164936', '10160766', '10162369', '10168309', '10164435', '10164978', '10164837']
ch = '10164375'

hdf= ['10134121','10174568','10158177','10159259','10143419','10154954','10155407','10160772','10160775']
hdh= '10172122' 
 
con = Mysql.new('jaguar', 'maryam', 'sCbub3675NWnNZK2', 'firehose_production')
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