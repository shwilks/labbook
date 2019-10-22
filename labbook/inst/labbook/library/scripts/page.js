

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



// Upon loading the DOM
$( document ).ready(function() {
    
    // Add the code toggle option
    addCodeToggle();
    
    // Make collapsible divs
    activateCollapsibleDivs();

});



