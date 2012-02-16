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
  $("#draggable").draggable
    connectToSortable: "#sortable"
    helper: "original"
    revert: "invalid"
  make_editable()

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
    if (element_class) is '.filter_box'
      kids = $(this).children()
      if kids
        styled = kids.children('input').is(':checked')
    else if (element_class) is '.sortby_box'
      styled = $($(this).children()[2].children).val()
    if (element_class) is '.filter_box' or (element_class) is '.show_box'
      unit = $(this).children().children('span').last().html()
      if unit is null or unit.match(/Click to edit/)
        unit = ""
    ordered_facets[index] = [dbid,type,dbname,display,unit,styled]
  return ordered_facets

collect_names = (element_class) ->
  ordered_results = []
  $(element_class).each (index) ->
    ordered_results.push($(this).attr('data-name'))
  return ordered_results
