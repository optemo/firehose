
$('#submit_type').live("click",function(){
  if ($('#product_type_name').valid()) {
    var name = $('#product_type_name').attr('value');
    var categories = get_selected();
    $.ajax({
      type: 'POST',
      url: "/product_types",
      data: {name: name, categories: categories},
      success: function(data) {
        $('body').html(data);
      },
      error: function(jqXHR, textStatus, errorThrown) {
        alert(jqXHR.statusText + " in submitting");
      }
    });
  }
});

$('#save_type').live("click",function(){
  var pid = $('#top_type').attr('data-id');
  var categories = get_selected();
  $.ajax({
    type: 'PUT',
    url: "/product_types/" + pid,
    data: {categories: categories, id: pid},
    success: function(data) {
      $('body').html(data);
    },
    error: function(jqXHR, textStatus, errorThrown) {
      alert(jqXHR.statusText + " in submitting");
    }
  });
});

// $(function () {
//   load_tree();
// });

function get_selected(){
  var selected = [];
  $(':checked').each (function (index) {
      if ($(this).hasClass('category_selection')) {
        var id = $(this).parent().attr('id');
        var name = $(this).parent().attr('data-name');
        selected.push([id, name]);
      }
  });
  return selected;
}