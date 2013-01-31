$(document).ready ->     

    #hide if broken image link
    $("img").error ->
      $(this).hide()
      $(this).parent(".accessory").hide()
        
    $('#enter_sku_search').live 'click', ->
      window.location.href += '/' + $('.sku_search').val() + "?cat="
      
    $('#ipad_search').live 'click', ->
      $('.sku_search').val("59812")
      
    $('#blackberry_search').live 'click', ->
      $('.sku_search').val("60114")
      
    $('#dslr_search').live 'click', ->
      $('.sku_search').val("38346")
      
    #futureshop
    $('#ipad_Fsearch').live 'click', ->
      $('.sku_search').val("41718")
      
    $('#blackberry_Fsearch').live 'click', ->
      $('.sku_search').val("41850")
      
    $('#dslr_Fsearch').live 'click', ->
      $('.sku_search').val("38778")
