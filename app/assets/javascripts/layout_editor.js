
$('select#new_filter').live('change', function () {
  var selected_type = $('#new_filter option:selected').attr('value')
  alert(selected_type);
});