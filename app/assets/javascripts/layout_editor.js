$(document).ready(function(){
  $(".sortable").sortable({
  	revert: true
  });
  $("#draggable").draggable({
    connectToSortable: "#sortable",
  	helper: "original",
  	revert: "invalid"
  });
  
  make_editable();
});

$('#submit_layout').live("click",function(){
  ordered_filters = collect_attributes('.filter_box');
  ordered_sorting = collect_attributes('.sortby_box');
  ordered_compare = collect_attributes('.show_box');
  locale = $(location).attr('search').split('=')[1];
  if (erroneous(ordered_filters) || erroneous(ordered_sorting) || erroneous(ordered_compare)) {
    alert('Error: please save the values of all display fields before saving layout');
    return false;
  }
  else {
    $.ajax({
      type: 'POST',
      url: "/layout_editor",
      data: {locale: locale, filter_set: ordered_filters, sorting_set: ordered_sorting, compare_set: ordered_compare},
      success: function(data) {
        alert("Finished saving layout");
      },
      error: function(jqXHR, textStatus, errorThrown) {
        alert(jqXHR.statusText + " in saving layout");
      }
    });
  }
});

function make_editable() {
  $('.edit-translation').each(function(){
    $(this).removeClass('edit-translation').editable(function(value, settings) {
      return(value);
    },{
      tooltip : 'click to edit',
      submit  : 'OK',
      onblur  : 'cancel',
      width   : '250px'
    });
  });
}

function erroneous(input_set) {
  for (i in input_set) {
    tuple = input_set[i];
    if (tuple[2].match(/\/form/) != null) {
      return true;
    }
  }
  return false;
}

$('.remove_facet').live("click",function(){
  var facet_element = $(this).parent();
  facet_element.remove();
  return false;
});

$('select#new_filter').live('change', function () {
  var selected_type = $('#new_filter option:selected').attr('value');
  // check that the name is not already present in the page
  if (jQuery.inArray(selected_type, collect_names('.filter_box')) > -1) {
    alert('Element already exists in the layout');
  }
  else {
    $.ajax({
      url: "/facet/new",
      data: {name: selected_type, used_for: 'filter'},
      success: function(data) {
        $('#filters_body').append(data);
        make_editable();
      },
      error: function(jqXHR, textStatus, errorThrown) {
        alert(jqXHR.statusText + " in adding facet");
      }
    });
  }
  return false;
});

$('select#new_sorting').live('change', function () {
  var selected_type = $('#new_sorting option:selected').attr('value');
  $.ajax({
    url: "/facet/new",
    data: {name: selected_type, used_for: 'sortby'},
    success: function(data) {
      $('#sorting_body').append(data);
      make_editable();
    },
    error: function(jqXHR, textStatus, errorThrown) {
      alert(jqXHR.statusText + " in adding facet");
    }
  });
  return false;
});

$('select#new_compare').live('change', function () {
  var selected_type = $('#new_compare option:selected').attr('value');
  // check that the name is not already present in the page
  if (jQuery.inArray(selected_type, collect_names('.show_box')) > -1) {
    alert('Element already exists in the layout');
  }
  else {
    $.ajax({
      url: "/facet/new",
      data: {name: selected_type, used_for: 'show'},
      success: function(data) {
        $('#compare_body').append(data);
        make_editable();
      },
      error: function(jqXHR, textStatus, errorThrown) {
        alert(jqXHR.statusText + " in adding facet");
      }
    });
  }
  return false;
});

$('#add_header').live("click",function() {
  $.ajax({
    url: "/facet/new",
    data: {type: 'Heading', used_for: 'filter'},
    success: function(data) {
      $('#filters_body').append(data);
      make_editable();
    },
    error: function(jqXHR, textStatus, errorThrown) {
      alert(jqXHR.statusText);
    }
  });
  return false;
});
$('#add_spacer').live("click",function() {
  $.ajax({
    url: "/facet/new",
    data: {type: 'Spacer', used_for: 'filter'},
    success: function(data) {
      $('#filters_body').append(data);
    },
    error: function(jqXHR, textStatus, errorThrown) {
      alert(jqXHR.statusText);
    }
  });
  return false;
});

function collect_attributes(element_class) {
  var ordered_facets = new Array();
  $(element_class).each (function (index) {
    var type = $(this).attr('data-type');
    var dbname = $(this).attr('data-id');
    var unit = "";
    var display = $(this).children().children('span').first().html();
    if (display == null) {
      display = ""; // not null so that it can be used in the ajax params
    }
    var styled = false;
    if (element_class == '.filter_box') {
      var kids = $(this).children();
      if (kids) {
        styled = kids.children('input').is(':checked');
      }
    }
    else if (element_class == '.sortby_box') {
      styled = $($(this).children()[2].children).val();
    }
    if (element_class == '.filter_box' || element_class == '.show_box') {
      unit = $(this).children().children('span').last().html();
      if (unit == null || unit.match(/Click to edit/)) {
        unit = "";
      }
    }
    ordered_facets[index] = [type,dbname,display,unit,styled];
  });
  return ordered_facets;
}

function collect_names(element_class) {
  var ordered_results = [];
  $(element_class).each (function (index) {
    ordered_results.push($(this).attr('data-id'));
  });
  return ordered_results;
}