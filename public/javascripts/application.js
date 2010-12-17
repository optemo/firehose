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
            applySilkScreen();
            rule_adder_div.load("/scraping_rules/new?rule=" + escape($(this).attr('data-location') + " -- " + $(this).attr('data-spec')));
            return false;
        });

        // Get the SKUs for each one from the category list
        $('.skus_to_fetch').each(function () {
            if (flag == 0) {
                var id = $(this).attr('data-id');
				$(this).load("/scrape/" + id, function(){
					$(this).find('.togglable').andSelf().each(function(){addtoggle($(this));});
				});
				
            }
            flag = 1;
        });

        function addtoggle(item){
			var closed = item.find("> a").click(function() {
				$(this).toggleClass("closed").toggleClass("open").siblings('div').toggle();
				return false;
			}).hasClass("closed");
			if (closed) {item.find("> div").hide();}
		}
		$('.togglable').each(function(){addtoggle($(this));});
        $('#silkscreen').click(function () {removeSilkScreen();});
    });
});

function removeSilkScreen() {
    $('#silkscreen').css({'display' : 'none', 'top' : '', 'left' : '', 'width' : ''}).fadeTo(0, 0).hide();
    // outsidecontainer in the other project is the pop-up window. it's rule_adder_div in this project
    $('#rule_adder_div').remove(); //css({'display' : 'none'});
//    $('#rule_adder_div').unbind('click');
}

function applySilkScreen() {
    /* This is used to get the document height for doing layout properly. */
    /*http://james.padolsey.com/javascript/get-document-height-cross-browser/*/
    current_height = (function() {
        var D = document;
        return Math.max(
            Math.max(D.body.scrollHeight, D.documentElement.scrollHeight),
            Math.max(D.body.offsetHeight, D.documentElement.offsetHeight),
            Math.max(D.body.clientHeight, D.documentElement.clientHeight)
        );
    })();
        	
	$('#silkscreen').css({'height' : current_height+'px', 'display' : 'inline'}).fadeTo(0, 0.5);
}
