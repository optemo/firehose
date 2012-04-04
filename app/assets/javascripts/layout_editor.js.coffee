make_editable = ->  
  $('.edit-translation').each ->
    $(this).removeClass('edit-translation').editable ((value, settings) ->
      return(value)
    ),
      tooltip : 'click to edit'
      submit  : 'OK'
      onblur  : 'cancel'
      width   : '250px'

$(document).ready ->
  $(".sortable").sortable
    revert: true
  make_editable()
  $('.clear_order').each ->
    $(this).css({'display':'none'})

make_sortable = ->
  $(".sortable_cats").sortable
    revert: true

load_product_type_tree = ->
  $("#product_type_tree").jstree
    plugins: [ "themes", "html_data", "ui" ]
    themes:
      theme: "classic"
    core:
      animation: 0
  $("#product_type_tree").bind "open_node.jstree", (event, data) ->
    id = data.rslt.obj.attr("id")
    $.ajax
      url: "category_ids/new"
      data:
        id: id
      success: (data) ->
        $('#' + id).replaceWith(data)

$('#save_ordering').live "click", ->
  # collect the ordering of elements to pass to the controller
  ordered_values = new Array()
  $('.cat_option').each (index) ->
    dbname = $(this).attr('data-name')
    ordered_values[index] = dbname
  $.ajax
    type: 'PUT'
    url: window.location.pathname.split('/edit')[0]
    data:
      unset_flag: 0
      ordered_names: ordered_values
    success: (data) ->
      alert("Finished updating category ordering")
      window.location.href = window.location.pathname.match(/(.+\/layout_editor)/)[1]
    error: (jqXHR, textStatus, errorThrown) ->
      alert(jqXHR.statusText + " in updating category ordering")

$('#unset_ordering').live "click", ->
  $.ajax
    type: 'PUT'
    url: window.location.pathname.split('/edit')[0]
    data:
      unset_flag: 1
    success: (data) ->
      alert("Removed the category ordering")
      window.location.href = window.location.pathname.match(/(.+\/layout_editor)/)[1]
    error: (jqXHR, textStatus, errorThrown) ->
      alert(jqXHR.statusText + " in updating category ordering")

$('#reset_layout').live "click", ->
  locale = $(location).attr('search').split('=')[1]
  $.ajax
    type: 'POST'
    url: window.location.pathname
    data:
      locale: locale
      filter_set: null
      sorting_set: null
      compare_set: null
    success: (data) ->
      alert("Finished resetting layout")
      window.location.reload()
    error: (jqXHR, textStatus, errorThrown) ->
      alert(jqXHR.statusText + " in resetting layout")
  
$('#submit_layout').live "click", ->
  ordered_filters = collect_attributes('.filter_box')
  ordered_sorting = collect_attributes('.sortby_box')
  ordered_compare = collect_attributes('.show_box')
  locale = $(location).attr('search').split('=')[1]
  if erroneous(ordered_filters) or erroneous(ordered_sorting) or erroneous(ordered_compare)
    alert('Error: please save the values of all display fields before saving layout')
    return false
  else
    $.ajax
      type: 'POST'
      url: window.location.pathname
      data:
        locale: locale
        filter_set: ordered_filters
        sorting_set: ordered_sorting
        compare_set: ordered_compare
      success: (data) ->
        alert("Finished saving layout")
      error: (jqXHR, textStatus, errorThrown) ->
        alert(jqXHR.statusText + " in saving layout")



erroneous = (input_set) ->
  for tuple in input_set
    if (tuple[2].match(/\/form/) != null) 
      return true
  return false

$('.remove_facet').live "click",->
  facet_element = $(this).parent()
  facet_element.remove()
  return false

$('select#new_filter').live 'change', ->
  selected_type = $('#new_filter option:selected').attr('value')
  if selected_type is "none"
    return false
  else if jQuery.inArray(selected_type, collect_names('.filter_box')) > -1 
    alert('Element already exists in the layout')
  else 
    $.ajax
      url: window.location.pathname + "/new"
      data: 
        name: selected_type
        used_for: 'filter'
      success: (data) ->
        $('#filters_body').append(data)
        make_editable()
      error: (jqXHR, textStatus, errorThrown) ->
        alert(jqXHR.statusText + " in adding facet")  
  return false

$('select#new_sorting').live 'change', ->
  selected_type = $('#new_sorting option:selected').attr('value')
  if selected_type is "none"
    return false
  $.ajax
    url: window.location.pathname + "/new"
    data:
      name: selected_type
      used_for: 'sortby'
    success: (data) ->
      $('#sorting_body').append(data)
      make_editable()
    error: (jqXHR, textStatus, errorThrown) ->
      alert(jqXHR.statusText + " in adding facet")
  return false

$('select#new_compare').live 'change', ->
  selected_type = $('#new_compare option:selected').attr('value')
  if selected_type is "none"
    return false
  # check that the name is not already present in the page
  if jQuery.inArray(selected_type, collect_names('.show_box')) > -1
    alert('Element already exists in the layout')
  else
    $.ajax
      url: window.location.pathname + "/new"
      data:
        name: selected_type
        used_for: 'show'
      success: (data) ->
        $('#compare_body').append(data)
        make_editable()
      error: (jqXHR, textStatus, errorThrown) ->
        alert(jqXHR.statusText + " in adding facet")
  return false

$('#add_header').live "click", ->
  $.ajax
    url: window.location.pathname + "/new"
    data:
      type: 'Heading'
      used_for: 'filter'
    success: (data) ->
      $('#filters_body').append(data)
      make_editable()
    error: (jqXHR, textStatus, errorThrown) ->
      alert(jqXHR.statusText)
  return false

$('#add_spacer').live "click", ->
  $.ajax
    url: window.location.pathname + "/new"
    data:
      type: 'Spacer'
      used_for: 'filter'
    success: (data) ->
      $('#filters_body').append(data)
    error: (jqXHR, textStatus, errorThrown) ->
      alert(jqXHR.statusText)
  return false

$('.clear_order').live "click", ->
  list_node = $(this).closest(".filter_box").children().filter((index) ->
    this.id.match /_list/
  )
  
  
$('.edit_categories').live "click", ->
  facet = $(this).closest($("div").filter(->
    @className.match /box/
  ))
  $(this).removeClass('edit_categories').addClass('save_categories')
  $(this).html('Hide ordering')
  $(this).parent().children('.clear_order').css({'display':'inline'})
  db_name = facet.attr('data-name')
  list_node = $(this).closest(".filter_box").children().filter((index) ->
    this.id.match /_list/
  )
  if list_node.css('display') == 'none'
    list_node.css({'display':'block'})
  else 
    $.ajax
      url: window.location.pathname + '/' + db_name + "/edit"
      data:
        id: db_name
      success: (data) ->
        $('#'+db_name + '_list').append(data)
        make_sortable()
        if db_name == 'product_type'
          load_product_type_tree()
      error: (jqXHR, textStatus, errorThrown) ->
        alert(jqXHR.statusText)
  return false

$('.save_categories').live "click", ->
  list_node = $(this).closest(".filter_box").children().filter((index) ->
    this.id.match /_list/
  )
  list_node.css({'display':'none'})
  $(this).parent().children('.clear_order').css({'display':'none'})
  $(this).removeClass('save_categories').addClass('edit_categories')
  $(this).html('Edit order of categories')
  return false

collect_attributes = (element_class) ->
  ordered_facets = new Array()
  $(element_class).each (index) ->
    type = $(this).attr('data-type')
    dbname = $(this).attr('data-name')
    dbid = $(this).attr('data-id')
    unit = ""
    display = $(this).children().children('span').first().html()
    if display is null
      display = "" # not null so that it can be used in the ajax params
    styled = false
    ordered_cats = new Array()
    if (element_class) is '.filter_box'
      styled = $(this).find('input').is(':checked')
      $(this).find('.cat_option').each (index) ->
        ordered_cats[index] = $(this).attr('data-name')
    else if (element_class) is '.sortby_box'
      styled = $($(this).children()[2].children).val()
    if (element_class) is '.filter_box' or (element_class) is '.show_box'
      unit = $(this).children().children('span').last().html()
      if unit is null or unit.match(/Click to edit/)
        unit = ""
    result = [dbid,type,dbname,display,unit,styled]
    if (element_class) is '.filter_box'
      result = result.concat(ordered_cats)
    ordered_facets[index] = result
  return ordered_facets

collect_names = (element_class) ->
  ordered_results = []
  $(element_class).each (index) ->
    ordered_results.push($(this).attr('data-name'))
  return ordered_results
