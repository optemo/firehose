require 'mysql'
require 'ruby-debug'


cf = ['10164834', '10164836'. '10164921', '10164923', '10164924', '10164935', '10164936', '10160866', '10160871', '10160895', '10164976', '10164980', '10164978', '10164837', '10164839', '10169571', '10169572', '10169573', '10168351', '10168353', '10168354', 'B9002211', 'B8002209', 'B8002210', '10173486', '10173487', '10154265']
ch = 'B9002214'

hdf= ['10167001', '10166034', '10155405', '10143419', '10166997', '10154954', '10174027', '10176410', '10176197', '10171551', '10171542', '10169523']
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