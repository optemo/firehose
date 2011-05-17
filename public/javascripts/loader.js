function opt_r(f){!!document.body?f():setTimeout('opt_r('+f+')',9)}
function opt_s(f){/in/.test(document.readyState)?setTimeout('opt_s('+f+')',9):f()}
var REMOTE = "http://192.168.5.100:3000";
//Check for IE6/7
if(true || document.compatMode && document.all && typeof XDomainRequest == "undefined") {
    var se = document.createElement("script");
    se.setAttribute("type", "text/javascript");
    se.setAttribute("src", REMOTE+'/javascripts/optemo_embedder.js');
    document.getElementsByTagName("head")[0].appendChild(se);
    se = document.createElement("link");
    se.rel = "stylesheet";
    se.type = "text/css";
    se.charset = "utf-8";
    se.href = REMOTE + "/stylesheets/assist_packaged.css";
    document.getElementsByTagName("head")[0].appendChild(se);
} else {
    opt_r(function(){
    var ef = document.createElement("iframe");
    //Check for History
    var history = location.hash.replace(/^#/, '');
    if (history.length > 0)
        ef.src = REMOTE+"?onestage=true&hist="+history;
    else
        ef.src = REMOTE+"?onestage=true";
    ef.id = "optemo_iframe";
    ef.width = "754px";
    ef.height = "1170px";
    ef.frameBorder = "no";
    var width = Math.max(document.body.clientWidth, document.documentElement.clientWidth)-920;
    if(navigator.userAgent.match(/MSIE [8,9,1]/))
        ef.style.setAttribute("left",Math.max(width/2,0)+"px");
    else
        ef.setAttribute("style","left:"+Math.max((width-15)/2,0)+"px");

    document.body.insertBefore(ef,document.body.firstChild);
    });
    opt_s(function(){
    	var pos = $('#optemo_embedder').offset();
    	$('#optemo_iframe').css({'left': pos.left, 'top': pos.top}).show();
    });
}