#! /bin/sh
sync_tables()
{
    while true; do
        echo "Please choose which servers do you want to sync.
                1) Developemnt=>linode1 
                2) Development=>linode2
                3) Development=>Production(Jaguar)
                4) Exit"
        read choise
        case $choise in
            1* )echo "Starting preview...";
                table_syncer -f dev -t linode1 -s scraping_rules,product_types,category_id_product_type_maps,headings,urls,features;;
            2* ) table_syncer -f dev -t linode2 -s scraping_rules,product_types,category_id_product_type_maps,headings,urls,features;;
            3* ) table_syncer -f dev -t prod -s scraping_rules,product_types,category_id_product_type_maps,headings,urls,features;;            
            4* ) exit;;
            * ) echo "Please select the number.";;
        esac
        echo "End preview";
        while true; do
            read -p "Do you wish to start the realy sync process?" tf
            case $tf in
                [Yy]* ) echo "Starting sync tables..."
                    case $choise in
                        1* )table_syncer -f dev -t linode1 -s scraping_rules,product_types,category_id_product_type_maps,headings,urls,features --commit;
                            break;;
                        2* )table_syncer -f dev -t linode2 -s scraping_rules,product_types,category_id_product_type_maps,headings,urls,features --commit;
                            break;;
                        3* )table_syncer -f dev -t prod -s scraping_rules,product_types,category_id_product_type_maps,headings,urls,features --commit;
                    esac
                    break;;
                [Nn]* ) exit;;
                * ) echo "Please answer yes or no.";;
            esac
        done
        exit;
    done
}
while true; do
    read -p "Do you wish to sync tables between development and production databases?" yn
    case $yn in
        [Yy]* ) sync_tables; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
