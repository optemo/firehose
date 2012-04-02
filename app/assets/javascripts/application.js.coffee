#= require_self
#= require layout_editor
#= require jquery.jeditable.min
#= require jquery_ujs
#= require jquery.validate.min
#= require jstree

# The ajax handler takes data from the ajax call and inserts the data into the #main part and then the #filtering part. 
ajaxhandler = (data) ->
  if rdr = /\[REDIRECT\](.*)/.exec(data)
    window.location.replace(rdr[1])
  else 
    parts = data.split('[BRK]')
    if parts.length is 2 
      $('#ajaxfilter').empty().append(parts[1])
      $('#main').html(parts[0])
      my.whenDOMready()
      return 0

removeSilkScreen = -> 
  $('#rule_adder_div').remove() #css({'display' : 'none'})
  # $('#rule_adder_div').unbind('click')
  $('#silkscreen').css(
    'display' : 'none'
    'top' : ''
    'left' : ''
    'width' : ''
  ).fadeTo(0, 0).hide()
  # outsidecontainer in the other project is the pop-up window. its rule_adder_div in this project

applySilkScreen= -> 
  # This is used to get the document height for doing layout properly. 
  # http://james.padolsey.com/javascript/get-document-height-cross-browser/
  current_height = (->
    D = document
    return Math.max(
      Math.max(D.body.scrollHeight, D.documentElement.scrollHeight)
      Math.max(D.body.offsetHeight, D.documentElement.offsetHeight)
      Math.max(D.body.clientHeight, D.documentElement.clientHeight))
  )
  $('#silkscreen').css({'height' : current_height+'px', 'display' : 'inline'}).fadeTo(0, 0.5)

$(document).ready ->

  # Turn on overlay links for adding rules
  $('.title_link, .new_rule').live 'click', ->
    # Pop up the "rule adder" in the body
    rule_adder_div = $('<div></div>')
    rule_adder_div.attr("id", "rule_adder_div")
    $('body').append(rule_adder_div)
    rule_adder_div.css("top", $(window).scrollTop() + 100)
    applySilkScreen()
    myparams = []
    params =
      "rule[remote_featurename]" : $(this).attr('data-rf')
      "rule[local_featurename]" : $(this).attr('data-lf')
      "raw" : $(this).attr('data-spec')
    for i of params
      if params[i] isnt undefined 
        myparams.push(escape(i)+"="+escape(params[i]))
    myurl = ($(this).attr('data-url') or window.location + "/new") + "?" + myparams.join('&')
    rule_adder_div.load myurl, (->
      # The actual validation rules are according to the defaults from the jquery validation plugin, in conjunction with
      # html attribute triggers written out in views/scraping_rules/new.html.erb.
      $(this).find('form').validate rules:
          regexp: "regexp"
          ifcont: "ifcont"
    )
    return false
        
  dropdown_function = ->
    t = $(this)
    el_to_insert_after = t.next() # The "destroy" link
    $.ajax
      url: t.attr('href')
      success: (data) ->
        # Insert the editing fields directly below
        el_to_insert_after.after(data)
      error: ->
        alert_substitute("There is an error in fetching the form")
    t.text('Hide Rule').unbind('click').click ->
      t.text('Edit Rule')
      el_to_insert_after.next().remove()
      t.unbind('click').click(dropdown_function)
      return false
    return false

  dropdown_categories = ->
    dropdown_div = $('#tree_categories')
    nodes = []
    nodes_path = $('#tree_categories').attr('data-path').split('"')
    for node, i in nodes_path
      nodes.push node.substr(1) if i % 2 == 1
    dropdown_div.load "category_ids", ->
      $("#product_type_menu").append dropdown_div
      setTimeout load_tree(nodes), 1000
      setTimeout load_nodes(nodes), 1500
    return false

  load_tree = (nodes) ->
    $("#tree_categories").jstree
      plugins: [ "themes", "html_data", "ui" ]
      themes:
        theme: "classic"
      core:
        animation: 0
    $("#tree_categories").bind "open_node.jstree", (event, data) ->
      id = data.rslt.obj.attr("id")
      product_type_id = $('#top_type').attr('data-id')
      $.ajax
        url: "category_ids/new"
        data:
          id: id
          product_type: product_type_id
        success: (data) ->
          $('#' + id).replaceWith(data)

  load_nodes = (nodes) ->
    setTimeout (->
      $("#tree_categories").jstree "set_focus"
    ), 500
    alert('jstree not loaded') unless $.jstree._reference("#tree_categories")?
    i = 0
    timeo = 0
    for nx, ix in nodes[0..nodes.length-2]
      timeo = timeo + 1000
      setTimeout (->
        to_open = "#" + nodes[i]
        #alert('opening' + to_open)
        $.jstree._reference("#tree_categories").open_node to_open
        i += 1
      ), timeo
      
    #$.jstree._reference("#tree_categories").open_node "#20001"
    setTimeout (->
      $.jstree._focused().select_node '#' + nodes[nodes.length-1]
    ), timeo + 1000

  $('.edit_rule_dropdown').click(dropdown_function)

  $('#open_category_tree').click(dropdown_categories)
    
  $('.raise_rule_priority').click ->
    t = $(this)
    category = document.getElementsByClassName('current_product_type')[0].innerHTML.match(/\s*(\w+)\s*/)[1]
    $.ajax
      url: "/#{category}/scraping_rules/raisepriority?id=" + t.parent().attr("data-id")
      data: ""
      type: "POST"
      success: ->
        alert_substitute("Rule priority raised.")
      error: ->
        alert_substitute("Error in processing the rule raise request.")
    return false
    
  $('.edit_scraping_rule').each ->
    $(this).validate
      rules: 
        regexp: "regexp"
      errorPlacement: (error, element) ->
        error.appendTo(element.parent())

  $('.expandable_sku').live "click", ->
  	$(this).load (window.location + "/" + $(this).attr('data-id')), ->
  		$(this).find('.togglable').each ->
  		  addtoggle($(this))
  		$(this).removeClass('bold').removeClass('expandable_sku')
  		return false
    
  # Scrape the first SKU from the category list
  $('.skus_to_fetch').first().click()

  addtoggle = (item) ->
    closed = item.hasClass("closed")
    if closed
      item.siblings('div').hide()

  $('.togglable').each ->
    addtoggle($(this))

  $('.togglable').live 'click', ->
    $(this).toggleClass("closed").toggleClass("open").siblings('div').toggle()
    return false

  $('#silkscreen').live "click", ->
    removeSilkScreen()

  $('.scraping_rule_submit, .correction_submit').live "click", ->
    t = $(this)
    form = t.parents("form")
    value = t.attr('Value')
    if form.validate().valid()  # Make sure the form is valid.
      $.ajax
        url: form.attr("action")
        data: form.serialize()
        type: "POST"
        success: (data) ->
          switch value
            when "Correct"
              removeSilkScreen()
              alert_substitute ("Correction Processed")
            when "Update Rule"
              removeSilkScreen()
              alert_substitute ("Rule Updated")
              ajaxhandler (data)
            else
              ajaxhandler (data)
              alert_substitute ("Rule Created")
              removeSilkScreen()
        error: ->
          removeSilkScreen()
          alert_substitute("Error in adding rule")
    return false

  alert_substitute = (msg) ->
    div_to_add = $("<div class='global_popup'>" + msg + "</div>")
    $("body").append(div_to_add)
    div_to_add.delay(2000).fadeOut(1000)

  $("a").live 'click', ->
  	t = $(this)
  	form = t.parents("form")
  	if t.hasClass('category_id-delete') or t.hasClass('delete_scraping_rule') 
  	  t.parent().remove()
  	  alert_substitute("Item has been removed.")
  	  return false
  	else if t.hasClass('remove_category')
  	  t.closest('.cat_option').remove()
  	  return false
    else if t.hasClass("catnav")
      cat_id = $.trim($('.current_product_type').html())[0] + t.closest('li').attr("id")
      tree = t.closest('.tree').attr('id')
      if tree == 'product_type_tree'
        #$.get "_category_order.html", (data) ->
        # $("#facet_order").append data
        data="<div class='draggable_cats'><div class='cat_option' data-name='#{cat_id}'><div>#{cat_id} <a class='remove_category' href='#'>x</a></div></div></div>"
        $("#facet_order").append data
      else
        parts = $(location).attr("href").split("/")
        parts[3] = cat_id
        address = parts.join("/")
        window.location = address
        return false
  	else if t.attr('data-method') is "delete"
  	  if confirm("Are you sure you want to delete this item?") 
  		  $.ajax
  				url: t.attr("href")
  				data: form.serialize()
  				type: "DELETE"
  				success: (data) ->
				    if t.hasClass('feature-delete') or t.hasClass('spec-delete') or t.hasClass('url-delete')
					    t.parent().remove()
  				error: ->
  					alert_substitute("Error in processing the request for delete.")
      return false
  	else
  		return true

  $('.correction').live "click", ->
  	myparams = []
  	t = $(this)
  	if t.html() is "Update Correction"
  		myurl = ($("h3").attr("data-correctionsurl") + "/" + t.siblings(".parsed").attr("data-sc") + "/edit")
  	else 
  		elem = t.parents(".contentholder").siblings(".edit_rule_dropdown") #Single rule definition
  		if not elem.length > 0 
  			#Combined for all rules, chooses the first one as id
  			elem = t.parents(".contentholder").parent().find(".edit_rule_dropdown")
  		params =
  		  "sc[product_id]" : t.siblings(".expandable_sku").attr('data-id')
  			"sc[raw]" : t.siblings(".raw").attr("data-rawhash") or t.siblings(".raw").html()
  			"sc[scraping_rule_id]" : elem.attr("data-id")
  		for arg,i in params
  			if arg isnt undefined
  			  myparams.push(escape(i)+"="+escape(arg))
      myurl = $("h3").attr("data-correctionsurl") + "/new?" + myparams.join('&')
    t.toggle().siblings(".parsed").load(myurl)
  	return false

  # Editable, use jeditable to edit inline. Document is jquery jeditable
  editableVar =
    method: 'PUT'
    indicator : 'Saving...'
    tooltip : 'Click to edit...'
    cancel : 'Cancel'
    submit : 'Ok'
    submitdata : (value, settings) ->
      pName = $(this).data("name")
      dId = $(this).data("id")
      origin = ''
      orgElement = ''
      if $(this).hasClass('stream')
        orgElement = $(this).data("origin")
        return { name : pName, dId : dId, orgElement : orgElement }
      return { name : pName, dId : dId }
    callback : (value, settings) ->
      console.log(this)
      console.log(value)
      console.log(settings)
      if $(this).hasClass('stream')
        if value is ''
          $(this).prev('span.comma').remove()
          $(this).remove()
        else
          arr = value.split(',')
          $(this).data('origin', arr[0])
          $(this).text(arr[0])
          arr.splice(0,1)
          for arg in arr 
            spanElem = $("<span class='comma'>,</span>")
            spanNewVal = $("<span class='" +$(this).attr("class") + "' data-origin='" + arg + "' data-id='" + $(this).data("id") + "' data-name='" + $(this).data("name") + "'>" + arg + "</span>")
            spanNewVal.editable('/product_types/1', editableVar)
            $(this).parent().append(spanElem)
            $(this).parent().append(spanNewVal)
          #	$(this).data('origin', value)

  $('a.show-hide').live 'click', ->
    if $(this).hasClass("not-all") 
      $(this).parent().nextUntil('dt', 'dd.invisible').show()
      $(this).text ("Hide No Value Attributes")
      $(this).removeClass("not-all")
    else
      $(this).parent().nextUntil('dt', 'dd.invisible').hide()
      $(this).text ("Show All Attributes")
      $(this).addClass("not-all")
    return false

  $('.coverage_submit').live 'click', ->
    $(this).parent().submit()

  $('.fetch_candidates').live 'click', ->
    contentbox = $(this).siblings('div')
    if contentbox.html() is "Processing..."
      $.get window.location.pathname+"/"+$(this).parent().attr('data-id'), (data) ->
        contentbox.html(data)

  $(".custom_regex").live 'click', ->
    reg = $(this).parent().prev() # children('.scraping_rule_regex')
    reg_option = $(this).prev().prev().prev() # prev('.scraping_rule_regex_option')

    if reg.is(":visible")
      reg.hide()
      reg_option.show()
      reg.attr('name', 'scraping_rule_option[regex]')
      reg_option.attr('name', 'scraping_rule[regex]')
    else
      reg.show()
      reg_option.hide()
      reg.attr('name', 'scraping_rule[regex]')
      reg_option.attr('name', 'scraping_rule_option[regex]')
