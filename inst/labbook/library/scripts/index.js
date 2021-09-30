
function add_index_search(id, after) {

  $(id).children(".project").children("a").each(function(){
    this.original_text = this.innerHTML;
  });

  let nothing_found = $("<div>No matching results</div>")
  .attr("id", "index-search-no-matching")
  .hide();

  let index_search = $("<input placeholder='filter pages...'/>")
  .attr("id", "index-search")
  .on("keyup", function(e){
    
    let val = this.value.toLowerCase();

    if(val === "") $(id).children(".project").children("h4").show();
    else           $(id).children(".project").children("h4").hide();
    
    $(id).children(".project").children("a").not(".alt-page-version").each(function(){
      let index_match = this.original_text.toLowerCase().indexOf(val);
      if(index_match === -1){
        $(this).hide();
      } else {
        $(this).show();
        this.innerHTML = this.original_text.slice(0,index_match)
        +"<span style='color:#ff3399'>"
        + this.original_text.slice(index_match, index_match + val.length)
        +"</span>"
        + this.original_text.slice(index_match + val.length, this.original_text.length);
      };
    });

    var project_vis = 0;
    $(id).children(".project").each(function(){
      var vis = 0;
      $(this).children("a").each(function(){
        vis += $(this).css("display") != "none";
      });
      if(vis === 0){
        $(this).hide()
      } else {
        $(this).show()
        project_vis += 1;
      }
    });
    
    if(project_vis == 0){
      nothing_found.show();
    } else {
      nothing_found.hide();
    }
    
  });
  
  if(after === null){
    $(id)
    .prepend(nothing_found)
    .prepend(index_search);
  } else {
    $(id)
    .children(after)
    .after(nothing_found)
    .after(index_search);
  }

}

function write_project_list() {

  project_list = [];

  $("section#projects").children(".project").each(function(index, value){

    if(!$(this).hasClass("archived")){
          var project_name = $(this).children("h3").html();
          var project_id   = $(this).attr("id");
          var project_link = "<a href='#"+project_id+"'>"+project_name+"</a>";
          $("#project-index").append(project_link);
    }

  });

}

function write_pinned_list() {

  var pinned_projects = [];
  $(".pinned").each(function(index, value){

  });
  $(".pinned").each(function(index, value){
    $("#pinned_links").append(value);
  });

}

function process_page_versions() {

  // Add toggle to main page links
  $("section#projects a[version]").not(".alt-page-version").each(function(index, element){

    // Get the page title
    var pagetitle   = $(element).html();
    var pageversion = $(element).attr("version");

    // Add version 0 to unversioned
    var siblings = $(element).siblings().filter(function(){
      return(this.innerHTML === pagetitle);
    });

    // Create a toggle for the versions
    var toggle = $("<div/>").html(pageversion).addClass("page-version-major");

    toggle.on("click", function(e){
      e.stopPropagation();
      //siblings.slideToggle();
      siblings.fadeToggle();
      //siblings.next().slideToggle();
      return(false);
    });

    $(element).prepend(toggle);

  });

  // Add versions to other page links
  $("section#projects a[version].alt-page-version").each(function(index, element){

    var pageversion = $(element).attr("version");
    var toggle = $("<div/>").html(pageversion).addClass("page-version-minor");
    $(element).prepend(toggle);

  });

}


// function write_todos() {

//   $("section#projects").children(".project").each(function(index, value){

//     var tododiv = $(this).children(".todo");
//     if(tododiv.length > 0){

//       var todos = $(tododiv).children();

//       var todocounter = $("<div/>")
//       .addClass("todocounter")
//       .addClass("unselectable")
//       .html(todos.length);

//       $(this).prepend(todocounter);

//     }

//   });

// }


$( document ).ready(function(){
  write_project_list();
  write_pinned_list();
  process_page_versions();
  add_index_search("#projects", "#project-index");
  add_index_search("#archive", null);
  // write_todos();
});


