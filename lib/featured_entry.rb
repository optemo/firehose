require 'mysql'
require 'ruby-debug'


cf = ['10164410', '10164409', '10156023', '10168417', '10174719', 'B9002011', 'B9002017', 'B9002014', 'B9002026' ]
ch = 'B9002045'

hdf= ['10167002','10150284','10137885','10163156','10155745','10170034','10174027','10150896','10174947']
hdh= '10172169' 
 
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
debugger
rs2 = con.query("INSERT INTO bin_specs (product_id, name, value, product_type) values (#{id_hdh[0]}, \'hero\', 1, \'drive_bestbuy\')")