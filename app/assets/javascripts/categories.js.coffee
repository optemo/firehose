
$('#submit_type').live "click", ->
  if $('#product_type_name').valid()
    name = $('#product_type_name').attr('value')
    categories = get_selected()
    $.ajax
      type: 'POST'
      url: "/product_types"
      data:
        name: name
        categories: categories
      success: (data) ->
        $('body').html(data)
      error: (jqXHR, textStatus, errorThrown) ->
        alert(jqXHR.statusText + " in submitting")

$('#save_type').live "click",->
  pid = $('#top_type').attr('data-id')
  categories = get_selected()
  $.ajax
    type: 'PUT'
    url: "/product_types/" + pid
    data:
      categories: categories
      id: pid
    success: (data) ->
      $('body').html(data)
    error: (jqXHR, textStatus, errorThrown) ->
      alert(jqXHR.statusText + " in submitting")
      
# $(->
#   load_tree()
# )
          
get_selected = ->
  selected = []
  $(':checked').each (index) ->
    if $(this).hasClass('category_selection') 
      id = $(this).parent().attr('id')
      name = $(this).parent().attr('data-name')
      selected.push([id, name])
  return selected