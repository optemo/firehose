// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

var script = document.createElement("script");
script.setAttribute("type", "text/javascript");
if (script.readyState) { 
    script.onreadystatechange = function() { if (script.readyState == "loaded" || script.readyState == "complete") { script.onreadystatechange = null; js_activator() }};
} else { 
    script.onload = function(){ js_activator() }; 
}
script.setAttribute("src", 'http://ajax.googleapis.com/ajax/libs/jquery/1.4.4/jquery.min.js');
document.getElementsByTagName("head")[0].appendChild(script);

var js_activator = (function() {
    $(document).ready(function(){
        flag = 0;
        $('.skus_to_fetch').each(function () {
            if (flag == 0) {
                var result_div = $('<div></div>'), id = $(this).attr('data-id');
                result_div.load("/scrape/" + id);
                $(this).append(result_div);
            }
            flag = 1;
        });
    });
});
