
function highlight_by_content_match(args){

	var matches = args.matches;
	var search_value = args.search_value;
	var content = args.content;
	var div;

	if(matches.length > 0){
		div = $("<div>");
		$("<span>")
		.text(content.substring(0, matches[0]))
		.appendTo(div);
		for(i=0; i<matches.length; i++){
			$("<span>")
			.css({ color : "red" })
			.text(content.substring(matches[i], matches[i]+search_value.length))
			.appendTo(div);
			if(i == matches.length - 1){
				$("<span>")
				.text(content.substring(matches[0]+search_value.length, content.length))
				.appendTo(div);
			} else {
				$("<span>")
				.text(content.substring(matches[i]+search_value.length, matches[i+1]))
				.appendTo(div);
			}
		}
	} else {
		div = $("<div>").text(content);
	}

	return(div);

}

function init_pagesearch(){

	var index = JSON.parse(pageindex);

	var pageresults = $("<div id='page-search-results'></div>");
	var pagesearch = $("<input placeholder='search pages...'/>")
	  .attr("id", "page-search")
	  .on("keyup", function(e){

		var content_match;
		var page_match;
		var index_matches;
		var search_value   = this.value.toLowerCase();
		var search_results = [];
		var code_search;

		// Determine if code is being searched
		code_search = search_value.charAt(0) == ":";
		if(code_search){
			search_value = search_value.substring(1);
			// pagesearch.css({ "font-family" : "monospace" });
		} else {
			// pagesearch.css({ "font-family" : "" });
		}

		if(search_value == ""){
			pageresults.hide();

		} else {
			pageresults.show();

			// Cycle through project records
			index.map(function(proj_record){

				// Cycle through project pages
				proj_record.pages.map(function(pg_record){

					// Cycle through page content
					page_match = [];
					if(!code_search){
						pg_record.content.map(function(content){

							content_match = content.toLowerCase().indexOf(search_value);
				            while(content_match != -1){

				            	// Record any matches
				            	var content_pre = content.substring(content_match - 50, content_match);
				            	if(content_match - 50 > 0) content_pre = "..."+content_pre
								page_match.push({
									content_pre: content_pre,
									content: content.substring(content_match, content_match + search_value.length),
									content_post: content.substring(content_match + search_value.length, content_match + 500)
								});

								// Continue searching the record
				                content_match = content.toLowerCase().indexOf(
				                	search_value, 
				                	content_match+1
				                );

				  			}

						});
					}

					// Cycle through code content
					code_match = [];
					if(code_search){
						pg_record.code.map(function(content){

							content_match = content.toLowerCase().indexOf(search_value);
				            while(content_match != -1){

				            	// Record any matches
				            	var content_pre = content.substring(content_match - 50, content_match);
				            	if(content_match - 50 > 0) content_pre = "..."+content_pre
								code_match.push({
									content_pre: content_pre,
									content: content.substring(content_match, content_match + search_value.length),
									content_post: content.substring(content_match + search_value.length, content_match + 500)
								});

								// Continue searching the record
				                content_match = content.toLowerCase().indexOf(
				                	search_value, 
				                	content_match+1
				                );

				  			}

						});
					}

					// Record page title matches
					title_matches = [];
					if(!code_search){
						var page_title = pg_record.page_title.toLowerCase();
						var page_title_match = page_title.indexOf(search_value);
						while(page_title_match != -1){
							title_matches.push(page_title_match);
							page_title_match = page_title.indexOf(
								search_value,
								page_title_match+1
							);
						}
					}

					// Record the page matches
					if(page_match.length > 0 || title_matches.length > 0 || code_match.length > 0){
						search_results.push({
							project_title : proj_record.project_title,
							project_path : proj_record.project_path,
							page_title : pg_record.page_title,
							page_path : pg_record.page_path,
							content_matches : page_match,
							code_matches : code_match,
							title_matches : title_matches
						});
					}

				});

			});

			// Work out number of matches
			var num_content_matches = search_results.map(p => p.content_matches.length);
			var num_code_matches    = search_results.map(p => p.code_matches.length);
			var num_title_matches   = search_results.map(p => p.title_matches.length);
			var search_results_index = [...Array(search_results.length).keys()];
			search_results_index.sort(function(a, b){  
				if(num_title_matches[b] != num_title_matches[a]){
					return(num_title_matches[b] - num_title_matches[a]);
				} else {
			        return(num_content_matches[b] - num_content_matches[a]);
				};
			});

			// Clear results
			var results_div = $("#page-search-results");
			results_div.html("");

			// Show or hide results div
			if(search_results_index.length == 0){
				results_div.append(
					$("<div>").html("No matches found").addClass("page-search-results-unfound")
				);
			} else {
				results_div.append(
					$("<div>").html("Page matches").addClass("page-search-results-found")
				);
			}

			// Cycle through most to fewest matches
			search_results_index.slice(0,20).map(i => {

				var page_result = search_results[i];
				var page_result_div = $("<div>")
				.addClass("page-search-results-page");
				
				// Highlight title div content
				var title_div_content = highlight_by_content_match({
					matches : page_result.title_matches,
					search_value : search_value,
					content : page_result.page_title
				});

				// Add the page link
				var page_link = $("<a>")
				.addClass("page-search-results-page-link")
				.attr("href", "projects/"+page_result.project_path+"/pages/"+page_result.page_path)
				.appendTo(page_result_div);

				// Add the title div
				var page_title_div = $("<div>")
				.append(title_div_content)
				.addClass("page-search-results-page-title")
				.appendTo(page_link);

				// Add page path
				var project_title_div = $("<div>")
				.text(page_result.project_title+" / "+page_result.page_path)
				.addClass("page-search-results-page-path")				
				.appendTo(page_link);

				// Add page results
				var page_result_content_div = $("<div>")
				.addClass("page-search-results-page-content-container")
				.appendTo(page_result_div);

				// var matches_shown = page_result.content_matches.slice(0,3);
				if(code_search) var matches_shown = page_result.code_matches;
				else            var matches_shown = page_result.content_matches;
				var matchnum = 1;
				matches_shown.map(match => {
					
					var match_div = $("<div>")
					.addClass("page-search-results-page-content")
					.appendTo(page_result_content_div);
					if(code_search) match_div.addClass("page-search-results-page-code");

					var match_pre = $("<span>")
					.text("["+matchnum+"] "+match.content_pre)
					.appendTo(match_div);

					var match_content = $("<span>")
					.text(match.content)
					.css({ color : "red" })
					.appendTo(match_div);

					var match_post = $("<span>")
					.text(match.content_post)
					.appendTo(match_div);

					matchnum++;

				});
				results_div.append(page_result_div);

			});

		}

	});

	$(".project").first().after(pagesearch);

	var pageresultsholder = $("<div>")
	.attr("id", "page-results-holder")
	.insertAfter(pagesearch)
	.append(pageresults);
	
}

// Load a script asynchronously
function loadScript( url, callback ) {
  var script = document.createElement( "script" );
  script.type = "text/javascript";
  script.onload = function() {
    callback();
  };

  // Add a random number for cache busting
  var vnum = Math.floor((Math.random() * 1000000) + 1);
  script.src = url+"?v="+vnum;
  var head = document.getElementsByTagName( "head" )[0];
  head.appendChild( script );
}

// Load the page search code
$( document ).ready(function(){


	loadScript("library/docs/pageindex.js", init_pagesearch);
	

});

