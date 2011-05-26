//Lightweight JSONP fetcher - www.nonobtrusive.com
OPT_REMOTE = 'http://192.168.5.100:3000';
var JSONP=(function(){var a=0,c,f,b,d=this;function e(j){var i=document.createElement("script"),h=false;i.src=j;i.async=true;i.onload=i.onreadystatechange=function(){if(!h&&(!this.readyState||this.readyState==="loaded"||this.readyState==="complete")){h=true;i.onload=i.onreadystatechange=null;if(i&&i.parentNode){i.parentNode.removeChild(i)}}};if(!c){c=document.getElementsByTagName("head")[0]}c.appendChild(i)}function g(h,j,k){f="?";j=j||{};for(b in j){if(j.hasOwnProperty(b)){f+=encodeURIComponent(b)+"="+encodeURIComponent(j[b])+"&"}}var i="json"+(++a);d[i]=function(l){k(opt_parse_data_by_pattern(l, "<img[^>]+>", (function(mystring){return mystring.replace(/(\/images\/[^?]+)/, OPT_REMOTE + "$1");})));d[i]=null;try{delete d[i]}catch(m){}};e(h+f+"callback="+i);return i}return{get:g}}());
//Function for executing code at DOMReady
//function opt_s(f){/in/.test(document.readyState)?setTimeout('opt_s('+f+')',9):f()}
function opt_insert(d) {
    var opt_t = document.getElementById("optemo_embedder");
    if (opt_t) {
        var se = document.createElement("div");
        se.id = "opt_new";
        se.innerHTML = d;
        opt_t.appendChild(se);
        if (typeof optemo_module != "undefined") {
            optemo_module.domready();
        }
    } else
        setTimeout(function(){opt_insert(d);d=null;},10);
}
//Load the correct history on reload
var opt_history = location.hash.replace(/^#/, '');
if (opt_history.length > 0)
    var opt_options = {embedding:'true',hist:opt_history};
else
    var opt_options = {embedding:'true'};
JSONP.get(OPT_REMOTE, opt_options, function(data){
    var regexp_pattern, data_to_add, data_to_append, scripts, headID = document.getElementsByTagName("head")[0], script_nodes_to_append, i, images;
    // Take out all the scripts, load them on the client (consumer) page in the HEAD tag, and put the data back together
    regexp_pattern = (/<script[^>]+>/g);
    scripts = data.match(regexp_pattern);
    data_to_add = data.split(regexp_pattern);
    script_nodes_to_append = Array();
    for (i = 0; i < scripts.length; i++)
    {
        srcs = scripts[i].match(/javascripts[^"]+/); // We might want to make a check for src instead.
        if (srcs == null) {
            scripts[i] = '<script type="text/javascript">';
        } else if (typeof(srcs) == "object" && srcs[0] && srcs[0].match(/easyXDM/)){
			 scripts[i] = ''; // so it will get taken out completely later
		} else {
            script_nodes_to_append.push(OPT_REMOTE + "/" + srcs);
            scripts[i] = '';
        }
    // When zipping stuff back up, we want to take out the /script tag *unless* there was a null response.
    }

	//Zipping data back up
    data_to_append = new Array();
    // This is basically a do-while loop in disguise. Put the zeroth element on first, go from there.
    data_to_append.push(data_to_add[0])
    for (i = 0; i < scripts.length; i++) {
        // Either put back the <script> tag that is required for inline scripts, or else take out the < /script> part from the start of data_to_add[i+1].
        // Each time, look at scripts[i]. If empty, we need to take out the /script part that starts the next block.
        if (scripts[i] == '') { // If empty, take out the "/script" part and push the next piece. Also, if it's the XDM script itself
            data_to_append.push(data_to_add[i+1].replace(/<\/script>/,''));
        } else { // If not empty, we need to put the <script> back in
			data_to_append.push(scripts[i]);
            data_to_append.push(data_to_add[i+1]);
        }
    }
    // Now, we want to join all the data 
    data_to_append = data_to_append.join("\n");
    
    opt_insert(data_to_append);

	// We have to load all scripts in order, but using labJS is too heavy. So, we do a recursive serial loader function.
	// Although serial should == slow, the javascript we're loading should only be one file in production.
	// The purpose of having this multiple-script functionality is for development mode.    				
	(function lazyloader(i) {
	    // attach current script, using closure-scoped variable
		var script = document.createElement("script");
        script.setAttribute("type", "text/javascript");
	    // when finished loading, call lazyloader again on next script, if there is one.
        if ((i + 1) < script_nodes_to_append.length) {
            if (script.readyState){  //IE
                script.onreadystatechange = function(){
                    if (script.readyState == "loaded" ||
                            script.readyState == "complete"){
                        script.onreadystatechange = null;
                        lazyloader(i + 1);
                    }
                };
            } else {  //Others
                script.onload = function(){
                    lazyloader(i + 1);
                };
            }    
        } else {
       		if (script.readyState){  //IE
                script.onreadystatechange = function(){
                    if (script.readyState == "loaded" ||
                            script.readyState == "complete"){
                        script.onreadystatechange = null;
                        finish_loading();
                    }
                };
            } else {  //Others
                script.onload = function(){
                    finish_loading();
                };
            }
        }		    
        script.setAttribute("src", script_nodes_to_append[i]);
        document.getElementsByTagName("head")[0].appendChild(script);
    })(0);
    function finish_loading() {
        
    }
});
// Private function for the register_remote socket. Takes data, splits according to rules, does replace() according to rules.
function opt_parse_data_by_pattern(mydata, split_pattern_string, replacement_function) {
	var data_to_add, data_to_append, split_regexp = new RegExp(split_pattern_string, "gi");
    images = mydata.match(split_regexp);
    data_to_add = mydata.split(split_regexp);
    data_to_append = new Array();
    data_to_append.push(data_to_add[0]);
    for (i = 0; i < images.length; i++) {
        if (images[i].match(new RegExp("http:\/\/"))) 
            data_to_append.push(images[i]);
        else
            data_to_append.push(replacement_function(images[i]));
        data_to_append.push(data_to_add[i+1]);
    }
    return data_to_append.join("\n");
}