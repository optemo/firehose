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
        // Turn on overlay links for adding rules
        $('.title_link').live('click', function() {
            // Pop up the "rule adder" in the body
            var rule_adder_div = $('<div></div>');
            rule_adder_div.attr("id", "rule_adder_div");
            $('body').append(rule_adder_div);
            rule_adder_div.load("/scraping_rules/new");
			return false;
        });

        // Get the SKUs for each one from the category list
        $('.skus_to_fetch').each(function () {
            if (flag == 0) {
                var id = $(this).attr('data-id');
				$(this).load("/scrape/" + id, function(){
					$(this).find('.togglable').andSelf().each(function(){
						var closed = $(this).find("> a").click(function() {
							$(this).toggleClass("closed").toggleClass("open").next().toggle();
							return false;
						}).hasClass("closed");
						if (closed) {$(this).find("> div").hide();}
					});
				});
				
            }
            flag = 1;
        });  

      	
    });
});
