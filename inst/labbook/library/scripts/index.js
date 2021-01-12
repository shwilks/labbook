
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
    var siblings = $(element).siblings(":contains("+pagetitle+")");

    // Create a toggle for the versions
    var toggle = $("<div/>").html("v"+pageversion).addClass("page-version-major");

    toggle.click(function(){
      //siblings.slideToggle();
      siblings.fadeToggle();
      //siblings.next().slideToggle();
      siblings.next().fadeToggle();
    });

    $(element).wrap("<div style='position:relative'/>");
    $(element).parent().append(toggle);

  });

  // Add versions to other page links
  $("section#projects a[version].alt-page-version").each(function(index, element){

    var pageversion = $(element).attr("version");
    var toggle = $("<div/>").html("v"+pageversion).addClass("page-version-minor");
    $(element).wrap("<div style='position:relative'/>");
    $(element).parent().append(toggle);

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
  // write_todos();
});


