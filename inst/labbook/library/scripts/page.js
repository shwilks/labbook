
// Morph shape class
class MorphShape {

  constructor(paths){

    this.paths = paths;
    this.keyTimes = [0];
    for(var i=1; i<paths.length; i++){
      this.keyTimes.push(this.keyTimes[i-1] + 1/(paths.length-1));
    }
    this.keySplines = Array(paths.length - 1).fill(".5,0,1,1");

    var svg = `
    <svg width="100%" viewbox="0 0 417 417">
      <path style="fill:currentColor" d='`+paths[0]+`'>
      </path>
    </svg>
    `;

    this.div = document.createElement("div");
    this.div.style.display = "inline-block";
    this.div.innerHTML = svg;

  }

  toggle(){

    this.div.innerHTML = `
      <svg width="100%" viewbox="0 0 417 417">
        <path style="fill:currentColor" d='`+this.paths[0]+`'>
        <animate
          attributeName="d"
          dur="600ms"
          repeatCount=1
          keyTimes="`+this.keyTimes.join(';')+`"
          calcMode="spline"
          keySplines="`+this.keySplines.join(';')+`"
          values="`+this.paths.join(';')+`"
          fill="freeze"
          />
      </svg>
    `;
    this.paths.reverse();

  }

}


function linkToOnlinePage(){

  var page_breadcrumb = $("#page-link");
  var local_path = window.location.href;

  var online_path = local_path.replace(
    "file:///Users/samwilks/Dropbox/labbook",
    "https://notebooks.antigenic-cartography.org/samwilks"
  );

  var online_path = online_path.replace(
    "file:///Users/samwilks/Dropbox/LabBook",
    "https://notebooks.antigenic-cartography.org/samwilks"
  );

  page_breadcrumb.attr("href", online_path);
  page_breadcrumb.addClass("outdated-link");

  var page_id = $("#page-id").html();
  var page_id_png_path = online_path.replace(/\.html$/, "_files")+"/"+page_id+".png";
  var page_id_png = $("<img>").attr("src", page_id_png_path);
  page_id_png.on("load", f => {
    page_breadcrumb.removeClass("outdated-link");
    page_breadcrumb.addClass("online-link");
  });
  // page_breadcrumb.addClass("online-link");

  // if(local_path.substr(0, 7) == "file://"){

  //   // Check if file exists
  //   $.ajax({
  //       url: online_path,
  //       type:'HEAD',
  //       success: function() {
  //           page_breadcrumb.attr("href", online_path);
  //           page_breadcrumb.addClass("online-link");
  //       },
  //       error: function() {
  //           page_breadcrumb.addClass("outdated-link");
  //       }
  //   });

  // }

}



// Code toggle function
function addCodeToggle(){

  // Add code show hide options
  $("#codetoggle").html("Show inline code");
  $("#codetoggle").click(function(){

    var code_chunks = document.getElementsByClassName("code-output");
    for(var i=0; i<code_chunks.length; i++){
      if(code_chunks[i].style.display == "block"){
        code_chunks[i].style.display = "none";
        $("#codetoggle").html("Show inline code");
      } else {
        code_chunks[i].style.display = "block";
        $("#codetoggle").html("Hide inline code");
      }
    }

  });

}


function activateCollapsibleDivs(){

  $(".collapsible-div").each(function(i, el){

    var content = $(this);
    var toggle = $('<div/>');
    toggle.addClass('collapsible-div-toggle');
    toggle.insertBefore(content);

    var label = $('<div>'+$(this).attr('label')+'</div>');
    label.addClass('collapsible-div-pill');
    label.addClass('unselectable');
    toggle.append(label);

    var arrow = new MorphShape([
      "M119.737,34.247c103.61,64.534 149.507,93.96 217.21,136.654c28.173,17.766 25.899,33.985 26.013,37.432c0.128,3.84 0.525,20.059 -22.939,34.987c-116.092,73.855 -144.27,91.455 -222.621,140.599c-33.677,21.123 -59.655,-8.89 -59.148,-30.911c0.915,-39.743 0.191,-104.921 0.191,-144.675c0,-39.753 -0.041,-104.877 -0.191,-144.63c-0.101,-26.902 27.742,-50.474 61.485,-29.456Z",
      "M208.333,104.985c27.41,0 53.697,10.889 73.078,30.27c19.382,19.382 30.27,45.669 30.27,73.078c0,27.41 -10.888,53.697 -30.27,73.078c-19.381,19.382 -45.668,30.27 -73.078,30.27c-27.409,0 -53.696,-10.888 -73.078,-30.27c-19.381,-19.381 -30.27,-45.668 -30.27,-73.078c0,-27.409 10.889,-53.696 30.27,-73.078c19.382,-19.381 45.669,-30.27 73.078,-30.27Z",
      "M208.333,63.257c39.754,0 107.15,0.128 146.903,0c22.141,-0.072 50.231,25.712 32.086,56.55c-57.429,97.602 -94.805,152.079 -148.703,235.604c-6.937,10.75 -26.166,12.48 -28.013,12.554c-2.009,0.08 -22.175,-2.017 -30.827,-15.815c-52.725,-84.081 -93.322,-146.976 -147.512,-235.587c-9.171,-14.996 -0.317,-53.308 33.709,-53.306c64.299,0.003 102.604,0 142.357,0Z"
    ]);
    arrow.div.classList.add("collapsible-div-arrow");
    toggle.append(arrow.div);

    $(toggle).click(function(){
      arrow.toggle();
      content.delay(600).fadeToggle(800);
    });

  });

}


function linkImages(){

  $("img").each(function(){
    var src = $(this).attr("src");
    $(this).wrap('<a href="'+src+'"></a>');
  });

}

// Linking code files
function linkCodeFiles(){

  // Set pattern for filename and record for any files found
  var pattern = /.\.[^\s\/]+$/;
  var filesused = document.createElement("div");
  filesused.id = "filesused";
  $("#code-download-link").after(filesused);

  // Loop through strings
  $(".page-code").find(".hljs-string").each(function(i, el){

    var string = el.innerHTML;
    if(pattern.test(string)){
      var stringstart   = string.substring(0, 1);
      var stringend     = string.substring(string.length-1, string.length);
      var stringcontent = string.substring(1, string.length - 1);
      var path = "../"+stringcontent;

      // Check if file exists
      $.ajax({
          url: path,
          type:'HEAD',
          success: function() {

              // Insert a link
              // el.innerHTML = stringstart
              //                + "<a href='" + path + "'>"
              //                + stringcontent
              //                + "</a>" + stringend;
              //
              // el.classList.add("linked-string");

              // Add to the files used div
              var filediv  = document.createElement("div");
              var pattern  = /[^\/\s]+\.[^\/\s]+$/;
              var filename = pattern.exec(stringcontent);
              filediv.innerHTML = "<a href='" + path + "'>"
                                  + stringcontent
                                  + "</a>";
              filediv.classList.add("fileused");

              filesused.appendChild(filediv);

          }
      });
    }

  });

}


function linkPlotly(){

  $(".js-plotly-plot").each(function(i, el){

    Plotly.toImage(
      this,
      {format: 'svg', width: el.offsetWidth, height: el.offsetHeight, scale:2}
    ).then(function(img){
      $(el).wrap('<a href="'+img+'"></a>');
    });

  });

}

function activateTabsets(){

  $(".tabset-div").each(function(tabseti, tabset){

    // Add the tabset tabs
    var tabs = $('<div></div>');
    tabs.addClass('tab-panel');
    tabs.insertBefore($(tabset));

    $(tabset.children).each(function(tabi, tabcontent){
      var label = $(tabcontent).attr("label");
      var tab = $('<div></div>').html(label).addClass("tabset-tab");
      tab.addClass("unselectable");
      tabs.append(tab);
      if(tabi > 0) $(tabcontent).hide();
      else         tab.addClass("active");
      tab.click(function(){
        $(tabcontent).siblings().hide();
        $(this).siblings().removeClass("active");
        $(tabcontent).show();
        $(this).addClass("active");
      });

    });

  });

  // Add a keyup event listener to the window
  $(window).keyup(function(e){

  	var key = e.originalEvent.key;
  	if(e.originalEvent.shiftKey && (key == "ArrowRight" || key == "ArrowLeft")){

	  	$(".tabset-div").each(function(tabseti, tabset){

	  		// Get tab visibility
	  		var numTabs    = $(tabset).children().length;
	  		var visibleTab;

	  		$(tabset).children().each(function(i){
	  			if($(this).is(':visible')){
	  				visibleTab = i;
	  			}
	  		});

	  		// Decide next visible
	  		if(key == "ArrowRight"){
		  		if(visibleTab == numTabs - 1) return(null);
		  		else                          var nextTab = visibleTab + 1;
	  		} else {
	  			if(visibleTab == 0)           return(null)
		  		else                          var nextTab = visibleTab - 1;
	  		}

	  		// Trigger click on the next tab
	  		var tabpanel = $(tabset).prev();
	  		tabpanel.children().eq(nextTab).trigger("click");

	  	});

    }

  });

}


function linkTags() {

    if ($(".page-tag").length > 0) {

        var taglinks = $("<div id='tag-links'/>");
        taglinks.hide();
        taglinks.insertAfter("#page-tags");

        var tagcancel = $("<div id='tag-cancel'/>").html("&otimes;");
        $("#page-tags").prepend(tagcancel);
        tagcancel.click(e => {
            taglinks.hide();
        });

        $(".page-tag").each(function() {

            $(this).click(e => {

                taglinks.hide();
                var shared_tags = tags[this.innerHTML];
                taglinks.empty();
                shared_tags.forEach(
                    function(tag) {
                        taglinks.append(
                            $("<a/>")
                            .addClass("tag-link")
                            .attr("href", "../../../"+tag.link)
                            .html(tag.title)
                        );
                    }
                );
                taglinks.show();

            });
        });

    } else {
        $("#page-tags").hide();
    }

}


// Upon loading the DOM
$( document ).ready(function() {

    // Add the code toggle option
    addCodeToggle();

    // Make collapsible divs
    activateCollapsibleDivs();

    // Activate the tabsets feature
    activateTabsets();

});
