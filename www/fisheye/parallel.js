// function to establish a connection from this iframe to the parent (shiny app)
// and call a function back in this iframe
// this ensures the iframe has loaded completely before the parent calls an iframe function

// if there is country selected from the dropdown then draw the fisheye
if(true){
console.log('iframe: before parent.tunnel')
parent.tunnel(initial);
console.log('iframe: AFTER parent.tunnel')
}
// Load the data and visualization
//d3.csv("fisheye/LouTest2.csv", function(raw_data) {
//Shiny.addCustomMessageHandler("sendFishEyeData", function(raw_data) {
function initial(cluster_aves, is_ctrl=1) { 
  var cluster_data = JSON.parse(cluster_aves); 
  // read from csv file the data passed from the server.R, ui.R
  d3.csv("data/acct_data.csv", function(raw_data) {
      // reset the svg element- the whole parallel coords chart
      d3.selectAll('svg > g > *').remove();
      d3.select('#sorted-by > .data-row').remove(); // clears the one selection in the sorted-by div
      
      var width = document.body.clientWidth,
      height = d3.max([document.body.clientHeight-370, 240]);
      
      var m = [90, 0, 10, 0],
      w = width - m[1] - m[3],
      h = height - m[0] - m[2],
      xscale = d3.scale.ordinal().rangePoints([0, w], 1),
      yscale = {},
      dragging = {},
      line = d3.svg.line(),
      axis = d3.svg.axis().orient("left").ticks(1+height/50),
      fisheye = d3.fisheye.scale(d3.scale.identity).domain([0,w]).focus(0).distortion(4),
      selected_lines = [],
      cnt_select = 0,
      data,
      foreground,
      background,
      highlighted,
      dimensions,                           
      legend,
      render_speed = 300,
      brush_count = 0,
      excluded_groups = [],
      //is_ctrl=1,  

      log_scale_dims = ['Wallet last4FY Tot avg' , 'Wallet FY17 Tot', 'BIC Oppty FY17 Tot', 'Stat Oppty FY17 Tot', 
      //'Wallet FY18 Tot', 'BIC Oppty FY18 Tot', 'Stat Oppty FY18 Tot', 
      'Contacts_All', 'ExpBkgs_EntNet', 'ExpBkgs_DC', 'ExpBkgs_Secur', 
      'ExpBkgs_Collab', 'ExpBkgs_Svcs', 'ExpBkgs_SPtech', 'ExpBkgs_Others',
      'SFDC Opened$ QtrlyMean 4Qs', 'SFDC Booked$ QtrlyMean 4Qs', 'SFDC Lost$ QtrlyMean 4Qs'
      ];           

          

      //log_scale_dims = ['Wal4FYs_Total', 'WalFY17_Total', 'BICFY17_Total', 'StatFY17_Total', 'Contacts_All'];      
      // log_scale_dims = ['BP_Security','Contacts_All'];
    
      // good colors (hsl format)
      //  60, 100%, 50% - yellow
      //  48, 100%, 50% - light brown
      //  30, 100%, 50% - orange
      //  336, 100%, 50% - bright fuchsya
      //  300, 100%, 70% - bluish pink
      //  216, 100%, 50% - mid blue
      //  192, 100%, 50% - teal
      //  180, 100%, 70% - light blue
      //  156, 100%, 50% - bright green
      //  120, 60%, 45% - mid green
      //  0, 100%, 90% - salmon  
      //  60, 20%, 75% - light olive
      //  0, 100%, 50% - bright red
      //  "UNKN": [185,80,45]
      //};
      
      
      // HSL format: hue(1-360), saturation(0-100) and lightness(0-100)
      var colors = {
        "cluster01": [249,55,86],  // "soap" 
        "cluster02": [120,100,70], // light green 
        "cluster03": [30,100,50],  // orange 
        "cluster04": [216,100,50], // mid blue
        "cluster05": [0,100,50],   // bright red
        "cluster06": [192,100,50], // teal 
        "cluster07": [120,60,35],  // mid green 
        "cluster08": [48,100,50],  // light brown 
        "cluster09": [300,100,70],   // bluish pink   
        "cluster10": [0,0,60]    // light olive
      };
      
      
      // Scale chart and canvas height
      d3.select("#chart")
      .style("height", (h + m[0] + m[2]) + "px")
      
      d3.selectAll("canvas")
      .attr("width", w)
      .attr("height", h)
      .style("padding", m.join("px ") + "px");
      
      
      // Foreground canvas for primary view
      foreground = document.getElementById('foreground').getContext('2d');
      foreground.globalCompositeOperation = "destination-over";
      foreground.strokeStyle = "rgba(0,100,160,0.1)";
      foreground.lineWidth = 1.7;
      foreground.fillText("Loading...",w/2,h/2);
      
      // Highlight canvas for temporary interactions
      highlighted = document.getElementById('highlight').getContext('2d');
      highlighted.strokeStyle = "rgba(0,100,160,1)";
      highlighted.lineWidth = 4;
      
      // Background canvas
      background = document.getElementById('background').getContext('2d');
      background.strokeStyle = "rgba(0,100,160,0.1)";
      background.lineWidth = 1.7;
      
      
      
      // SVG for ticks, labels, and interactions
      var svg = d3.select("svg")
      .attr("width", w + m[1] + m[3])
      .attr("height", h + m[0] + m[2])
      .append("svg:g")
      .attr("transform", "translate(" + m[3] + "," + m[0] + ")");

      // Convert quantitative scales to floats
      data = raw_data.map(function(d) {
        for (var k in d) {
          if (!_.isNaN(raw_data[0][k] - 0) && k != 'id'){
            // if parseFloat fails, then make the value for that row 0
            d[k] = parseFloat(d[k]) || 0;
          }
        }
        return d;
      });
      
      
      
      // Extract the list of numerical and ordinal dimensions and create a scale for each.
      // This is also the place where DIMENSIONS are assigned
      xscale.domain(dimensions = d3.keys(data[0]).filter(function(k) {
        
        // don't include these dimensions in the visualization but name is still used in the search bar
        if(k =='name'|| k =='SAVID'){
          return(false);
        }
        
        // if dimension is string then make sure y scale is ordinal
        if(_.isString(data[0][k])){
          yscale[k] = d3.scale.ordinal()
          .domain(data.map( function(d) { return d[k]; }))
          //.domain(d3.extent(data, function(d) { return d[k]; }))
          .rangePoints([h, 0],1);   
        }
        else if ( _.contains(log_scale_dims, k)){ // make sure no 0 values in csv for log columns
          
          minv = d3.min(data, function(d) { return +d[k]; })
          //minv = 1
          maxv = d3.max(data, function(d) { return +d[k]; })
          
          yscale[k] = d3.scale.log()
          .domain([minv, maxv])
          .range([h, 0]);
        }
        else{
          range_extent = d3.extent(data, function(d) { return +d[k]; });
          //if the max is 0, set to 1
          if(range_extent[1] == 0){
            range_extent[1] = 1;
          }
          
          yscale[k] = d3.scale.linear()
          .domain(range_extent)
          .range([h, 0]);
        }
        return true;
        
      }));
      //}).sort()); // this is to sort dimensions in alphabetical order
      
      // Add a group element for each dimension.
      var g = svg.selectAll(".dimension")
      .data(dimensions)
      .enter().append("svg:g")
      .attr("class", "dimension")
      .attr("transform", function(d) { return "translate(" + fisheye(xscale(d)) + ")"; })
      .call(d3.behavior.drag()
            .on("dragstart", function(d) {
              dragging[d] = this.__origin__ = fisheye(xscale(d));
              this.__dragged__ = false;
              d3.select("#foreground").style("opacity", "0.35");
            })
            .on("drag", function(d) {
              dragging[d] = Math.min(w, Math.max(0, this.__origin__ += d3.event.dx));
              dimensions.sort(function(a, b) { return position(a) - position(b); });
              xscale.domain(dimensions);
              g.attr("transform", function(d) { return "translate(" + position(d) + ")"; });
              brush_count++;
              this.__dragged__ = true;
              
              // Feedback for axis deletion if dropped
              if (dragging[d] < 12 || dragging[d] > w-12) {
                d3.select(this).select(".background").style("fill", "#b00");
              } else {
                d3.select(this).select(".background").style("fill", null);
              }
            })
            .on("dragend", function(d) {
              if (!this.__dragged__) {
                // no movement, invert axis
                var extent = invert_axis(d);
                
              } else {
                // reorder axes
                d3.select(this).transition().attr("transform", "translate(" + fisheye(xscale(d)) + ")");
                
                var extent = yscale[d].brush.extent();
              }
              
              // remove axis if dragged all the way left
              if (dragging[d] < 12 || dragging[d] > w-12) {
                remove_axis(d,g);
              }
              
              // TODO required to avoid a bug
              xscale.domain(dimensions);
              update_ticks(d, extent);
              
              // rerender
              d3.select("#foreground").style("opacity", null);
              brush();
              delete this.__dragged__;
              delete this.__origin__;
              delete dragging[d];
            }))
      
      // Add an axis and title.
      g.append("svg:g")
      .attr("class", "axis")
      .attr("transform", "translate(0,0)")
      .each(function(d) { d3.select(this).call(axis.scale(yscale[d])); })
      .append("svg:text")
      .attr("text-anchor", "left")
      .attr("y", 0)
      .attr("transform", "rotate(-30) translate(-6,-8)")
      .attr("x", 0)
      .attr("class", "label")
      .text(String)
      .append("title")
      .text("Click to invert. Drag to reorder");
      
      // Add and store a brush for each axis.
      g.append("svg:g")
      .attr("class", "brush")
      .each(function(d) { d3.select(this).call(yscale[d].brush = d3.svg.brush().y(yscale[d]).on("brush", brush)); })
      .selectAll("rect")
      .style("visibility", null)
      .attr("x", -15)
      .attr("width", 30)
      .append("title")
      .text("Drag up or down to brush along this axis");
      
      g.selectAll(".extent")
      .append("title")
      .text("Drag or resize this filter");
      
      
      legend = create_legend(colors,brush);
      
      // Render full foreground
      brush();
      
      // Update fisheye effect with mouse move.
      d3.select("#chart").on("mousemove", function() {
        
        // CTRL key pressed 
        if (is_ctrl & event.ctrlKey != 1) return;
        
        // Reorder event
        if (d3.keys(dragging).length > 0) return;
        
        fisheye.focus(d3.mouse(this)[0]);
        
        brush();
        g.attr("transform", function(d) { return "translate(" + fisheye(xscale(d)) + ")"; });
      });
      
      // Fisheye value togle
      d3.select("#distortion").on("keyup", function() {
        fisheye.distortion(d3.select(this)[0][0].value);
        brush();
        g.attr("transform", function(d) { return "translate(" + fisheye(xscale(d)) + ")"; });
      });
      
    // copy one canvas to another, grayscale
    function gray_copy(source, target) {
      var pixels = source.getImageData(0,0,w,h);
      target.putImageData(grayscale(pixels),0,0);
    }
    
    // http://www.html5rocks.com/en/tutorials/canvas/imagefilters/
      function grayscale(pixels, args) {
        var d = pixels.data;
        for (var i=0; i<d.length; i+=4) {
          var r = d[i];
          var g = d[i+1];
          var b = d[i+2];
          // CIE luminance for the RGB
          // The human eye is bad at seeing red and blue, so we de-emphasize them.
          var v = 0.2126*r + 0.7152*g + 0.0722*b;
          d[i] = d[i+1] = d[i+2] = v
        }
        return pixels;
      };
    
    function create_legend(colors,brush) {
      // create legend
      var legend_data = d3.select("#legend")
      .html("")
      .selectAll(".row")
      .data( _.keys(colors).sort() )
      
      // filter by group
      var legend = legend_data
      .enter().append("div")
      .attr("title", "Hide group")
      .on("click", function(d) { 
        // toggle cluster groups; excluded groups is actually the difference between all clusters and the selected cluster
        //if dimension is in excluded groups list( hidden), then remove alls dimension except that one
        if (_.contains(excluded_groups, d)) {
          excluded_groups = _.difference(excluded_groups,[d]);
          brush();
        } else {
          excluded_groups.push(d);
          brush();
        } 
      });
      
      legend
      .append("span")
      .style("background", function(d,i) { return color(d,0.85)})
      .attr("class", "color-bar");
      
      legend
      .append("span")
      .attr("class", "tally")
      .text(function(d,i) { return 0});  
      
      legend
      .append("span")
      .text(function(d,i) { return " " + d});  
      
      return legend;
    }
    
    // render polylines i to i+render_speed 
    function render_range(selection, i, max, opacity) {
        selection.slice(i,max).forEach(function(d) {
          path(d, foreground, color(d.group,opacity));
        });
    };
    
    // draws 2 datatables: 1) sample 50 2) the bottom big data table
    function data_table_clusters(sample_all) {
     
     sample_50= sample_all.slice(0,50);
     sample_all= sample_all.slice(0,1000);
      // sort by first column
      var sample = sample_50.sort(function(a,b) {
        var col = d3.keys(a)[0];
        return a[col] < b[col] ? -1 : 1;
      });
      // Code for the sample 50 table
      var table = d3.select("#food-list")
      .html("")
      .selectAll(".row")
      .data(sample)
      .enter().append("div")
      .attr("class", "data-row")
      .on("mouseover", highlight)
      .on("mouseout", unhighlight)
      .on("click", function(d) {
        document.getElementById("sorted-by").innerHTML = "<h5>Dimensions sorted by</h5>";
        document.getElementById("sorted-by")
        .appendChild(this)
        unhighlight();
        dimensions = _(dimensions).sortBy(function(key) {
          return yscale[key](d[key]);
        });
        xscale.domain(dimensions);
        svg.selectAll(".dimension").transition().duration(2000).attr("transform", function(p) { return "translate(" + position(p) + ")"; });
        brush();
      });
      
      table
      .append("span")
      .attr("class", "color-block")
      .style("background", function(d) { return color(d.group,0.85) })
      
      table
      .append("span")
      .text(function(d) { return d.name; })
      
      // Code for the Bottom Data Table
      // remove the old grid elements before creating a new data table
      d3.selectAll('#gene_table_wrapper').remove();
      d3.selectAll('#gene_table').remove();
      
      var table_plot = makeTable()
                      .datum(sample_all)
                      //.sortBy('name', true);
                      //.filterCols(['col', 'x', 'y']);

      d3.select('#grid').call(table_plot);
      // highlight the appropriate cluster group and line in fisheye when selected from data table
      table_plot.on('highlight', function(data, on_off){
        if(on_off){//if the data is highlighted
          // need to match the data returned from the table with the sample input data because of reformatation
          var actual_row = sample_all.filter(function (entry) { 
                  return (entry.name === data.name && entry.group == data.group); 
          });
          
          highlight_grid(actual_row[0])
        }else{
          unhighlight()
        }
      });
    }
    
    // simple data table that handles the sample 50 table and the Big data table at the bottom of the page
    function data_table(sample_all, totals) {
      // load only 1000 companies but show the totals for the selected
      sample_all= sample_all.slice(0,1000);
      sample_50= sample_all.slice(0,50); // get 50 for the small sample table
     
      // Code to draw the small sample table of 50 random accts
      var sample = sample_50.sort(function(a,b) {
        var col = d3.keys(a)[0];
        return a[col] < b[col] ? -1 : 1;
      });
      // Code for the sample 50 table
      var table = d3.select("#food-list")
      .html("")
      .selectAll(".row")
      .data(sample)
      .enter().append("div")
      .attr("class", "data-row")
      .on("mouseover", highlight)
      .on("mouseout", unhighlight)
      .on("click", function(d) {
        document.getElementById("sorted-by").innerHTML = "<h5>Dimensions sorted by</h5>";
        document.getElementById("sorted-by")
        .appendChild(this)
        unhighlight();
        dimensions = _(dimensions).sortBy(function(key) {
          return yscale[key](d[key]);
        });
        xscale.domain(dimensions);
        svg.selectAll(".dimension").transition().duration(2000).attr("transform", function(p) { return "translate(" + position(p) + ")"; });
        brush();
      });
      
      table
      .append("span")
      .attr("class", "color-block")
      .style("background", function(d) { return color(d.group,0.85) })
      
      table
      .append("span")
      .text(function(d) { return d.name; })
     
      // remove the old grid elements before creating a new data table
      d3.selectAll('#gene_table_wrapper').remove();
      d3.selectAll('#gene_table').remove();
      var table_plot = makeTable2(totals)
                      .datum(sample_all)
                      

      d3.select('#grid').call(table_plot);
      // highlight the appropriate cluster group and line in fisheye when selected from data table
      table_plot.on('select', function(data, on_off){
        if(on_off){//if the data is highlighted
          cnt_select +=1;
          //store the selected line's data
          selected_lines.push(data);
          // if selected, increment the cnt_select
          highlight_grid(data, hg = 1)
        }
        else{
          cnt_select -=1; //toggle off or decrement the cnt_select by one
          // else unhighlight all
          unhighlight();
          // toggled select off
          // if there is another row selected, just unhighlight the data row selected to turn off
            tmp_array = [];
            first_key = Object.keys(data)[0];
    
            // search for that data object in the array of selected_lines
            selected_lines.forEach(function(ob) {
                  // store all objects not equal to the selected one in a tmp array
                  if(data[first_key] != ob[first_key]){
                      tmp_array.push(ob);
                      // redraw that line
                      highlight_grid(ob, hg = 1);
                  }
            });
            // update the selected_lines array t
            selected_lines = tmp_array;
        }
      });
    }
    
    // Adjusts rendering speed 
    function optimize(timer) {
      var delta = (new Date()).getTime() - timer;
      render_speed = Math.max(Math.ceil(render_speed * 30 / delta), 8);
      render_speed = Math.min(render_speed, 300);
      return (new Date()).getTime();
    }
    
    // Feedback on rendering progress
    function render_stats(i,n,render_speed) {
      d3.select("#rendered-count").text(i);
      d3.select("#rendered-bar")
      .style("width", (100*i/n) + "%");
      d3.select("#render-speed").text(render_speed);
    }
    
    // Feedback on selection
    function selection_stats(opacity, n, total) {
      d3.select("#data-count").text(total);
      d3.select("#selected-count").text(n);
      d3.select("#selected-bar").style("width", (100*n/total) + "%");
      d3.select("#opacity").text((""+(opacity*100)).slice(0,4) + "%");
    }
    
    // Highlight from the data grid single polyline in the fisheye and highlight the cluster group
    function highlight_grid(d) {
  
      d3.select("#foreground").style("opacity", "0.25");
      // this selects the cluster row that matches 
      d3.selectAll(".row")
      .style("font-weight", function(p) { return (d.group == p) ? "bold" : null})
      .style("opacity", function(p) { return (d.group == p) ? null : "0.3" });
      
      path(d, highlighted, color(d.group,1));
    }
    
    // Highlight single polyline 
    function highlight(d) {
      d3.select("#foreground").style("opacity", "0.25");
      d3.selectAll(".row")
      .style("font-weight", function(p) { return (d.group == p) ? "bold" : null})
      .style("opacity", function(p) { 
      return (d.group == p) ? null : "0.3" });
      
      path(d, highlighted, color(d.group,1));
    }
    
    // Remove highlight
    function unhighlight() {
      d3.select("#foreground").style("opacity", null);
      d3.selectAll(".row").style("font-weight", null).style("opacity", null);
      highlighted.clearRect(0,0,w,h);
    }
    
    //function called when ylabel is clicked, d is the dimension name
    function invert_axis(d) {
      // save extent before inverting
      
      if (!yscale[d].brush.empty()) {
        var extent = yscale[d].brush.extent();  // extent is the max and min of the range or domain
      }
      if (yscale[d].inverted == true) {
        if(_.isString(data[0][d])){
          yscale[d].rangePoints([h, 0],1);   
        }else{
          yscale[d].range([h, 0]);
        }
        d3.selectAll('.label')
        .filter(function(p) { return p == d; })
        .style("text-decoration", null);
        yscale[d].inverted = false;
      } 
      else {
        
        //if the dimension is a string, then make sure you invert the axis but keep the scale ordinal
        if(_.isString(data[0][d])){
          yscale[d].rangePoints([0, h],1);   
        }else{
          yscale[d].range([0, h]);
        }
        
        d3.selectAll('.label')
        .filter(function(p) { return p == d; })
        .style("text-decoration", "underline");
        yscale[d].inverted = true;
      }
      return extent;
    }
    
    // Draw a single polyline using a bezier curve which adds "smoothness""
/*    function path(d, ctx, color) {
      if (color) ctx.strokeStyle = color;
      var x = fisheye(xscale(0));
          y = yscale[dimensions[0]](d[dimensions[0]]);   // left edge
    
      x_orig = -1
      smoothness = 1; // if you increase this value, the curvier the plots.
      ctx.beginPath();
      for (i = 0; i < dimensions.length; i++) {
        p = dimensions[i];
        x = fisheye(xscale(p));
        y = yscale[p](d[p]);
    
        if (x_orig != -1) {
          ctx.bezierCurveTo(x_orig + smoothness, y_orig, x - smoothness,y, x, y); 
        } 
        else {
          ctx.moveTo(x, y);
        }
        x_orig = x;
        y_orig = y;
      };
      ctx.stroke();
    }
*/

  
  // Draw a single polyline
      function path(d, ctx, color, dash =0) {
      
       if (color) ctx.strokeStyle = color;
        if(dash==1){
            ctx.setLineDash([5, 3]);/*dashes are 5px and spaces are 3px and are for cluster mean lines*/
        }
        else{
            ctx.setLineDash([]);
        }
        var x = fisheye(xscale(0)-15);
        y = yscale[dimensions[0]](d[dimensions[0]]);   // left edge
        ctx.beginPath();
        ctx.moveTo(x,y);
        dimensions.map(function(p,i) {
          x = fisheye(xscale(p)),
          y = yscale[p](d[p]);
          ctx.lineTo(x, y);
        });
        ctx.lineTo(x+15, y);                               // right edge
        ctx.stroke();
      }
  
    
    function color(d,a) {
        var c = colors[d];
        return ["hsla(",c[0],",",c[1],"%,",c[2],"%,",a,")"].join("");
      }
    
    function position(d) {
      var v = dragging[d];
      return v == null ? fisheye(xscale(d)) : v;
    }
    
    // Handles a brush event, toggling the display of foreground lines.
    // TODO refactor
    function brush() {
      brush_count++;
      var actives = dimensions.filter(function(p) { return !yscale[p].brush.empty(); }),
      extents = actives.map(function(p) { return yscale[p].brush.extent(); });
      
      // hack to hide ticks beyond extent
      var b = d3.selectAll('.dimension')[0]
      .forEach(function(element, i) {
        
        var dimension = d3.select(element).data()[0];
        if (_.include(actives, dimension)) {
          var extent = extents[actives.indexOf(dimension)];
          d3.select(element)
          .selectAll('text')
          .style('font-weight', 'bold')
          .style('font-size', '11px')
          .style('display', function() { 
            var value = d3.select(this).data();
            return extent[0] <= value && value <= extent[1] ? null : "none"
          });
        } else {
          d3.select(element)
          .selectAll('text')
          .style('font-size', null)
          .style('font-weight', null)
          .style('display', null);
        }
        d3.select(element)
        .selectAll('.label')
        .style('display', null);
      });
      ;
      
      // bold dimensions with label
      d3.selectAll('.label')
      .style("font-weight", function(dimension) {
        if (_.include(actives, dimension)) return "bold";
        return null;
      });
      
      // Get lines within extents
      var selected = [];
      data
      .filter(function(d) {
        return !_.contains(excluded_groups, d.group);
      })
      .map(function(d) {
        return actives.every(function(p, dimension) {
          var p_new = (yscale[p].ticks)?d[p]:yscale[p](d[p]); //convert to pixel range if ordinal, ordinal ticks will be undefined
          return extents[dimension][0] <= p_new && p_new <= extents[dimension][1];
          
          
        }) ? selected.push(d) : null;
      });
      
      
      // free text search
      var query = d3.select("#search")[0][0].value;
      if (query.length > 0) {
        selected = search(selected, query);
      }
      
      if (selected.length < data.length && selected.length > 0) {
        d3.select("#keep-data").attr("disabled", null);
        d3.select("#exclude-data").attr("disabled", null);
      } else {
        d3.select("#keep-data").attr("disabled", "disabled");
        d3.select("#exclude-data").attr("disabled", "disabled");
      };
      
      // total by food group
      var tallies = _(selected)
      .groupBy(function(d) { return d.group; })
      
      // include empty groups
      _(colors).each(function(v,k) { tallies[k] = tallies[k] || []; });
      
      legend
      .style("text-decoration", function(d) { return _.contains(excluded_groups,d) ? "line-through" : null; })
      .attr("class", function(d) {
        return (tallies[d].length > 0)
        ? "row"
        : "row off";
      });
      
      legend.selectAll(".color-bar")
      .style("width", function(d) {
        return Math.ceil(500*tallies[d].length/data.length) + "px"
      });
      
      legend.selectAll(".tally")
      .text(function(d,i) { return tallies[d].length });  
      
      // Render selected lines
      paths(selected, foreground, brush_count, true);
    }
    
    // render a set of polylines on a canvas that are selected by the brush or the cluster groups
    function paths(selected, ctx, count) {
      var n = selected.length,
      i = 0,
      opacity = d3.min([2/Math.pow(n,0.3),1]),
      timer = (new Date()).getTime();
      
      selection_stats(opacity, n, data.length)
      
      // calculate the Total averages and pass to data_table()
      colnames = d3.keys(data[0]); // this is the first data row
      
      // add a secondary table header that contains the ave of all the columns if numeric and use mode (as an ave) if string
	    totals = {}; // collects the averages
	    totals_sum = {}; // collects the sums for each acct row
	    // for each data row
	    selected.forEach(function(d) {
	        // for each column in the row
	        // reserve the 1st and 2nd column of the data to write the Total Ave/Mode labels for this row
          colnames.forEach(function(k) {
            if( k == colnames[0]){
                totals[k] = "Total: " + n + " selected rows"
            }
            else if(k ==colnames[1]){
                totals[k] = "Sum: Mean or Mode "
            }
            else if (! _.isString(selected[1][k])) {
                if (k in totals) {
                    totals[k] += d[k]/n;
                    // if colname doesnt contains a % then get the sum of the values for this column
                    if(! k.includes("%")){
                        totals_sum[k] += d[k];
                    }
                } else { // new entry of that column in the totals dictionary; this happens for the first row
                    totals[k] = d[k]/n;
                    if(! k.includes("%")){
                        totals_sum[k] = d[k];
                    }
                }
            }else{ // this is a string column that is not in the totals dictionary
                if (! (k in totals)) {
                    var collect = selected.map(function(a) {return a[k];});
                    most_common = _.chain(collect).countBy().pairs().max(_.last).head().value();
                    totals[k] = most_common;
                } 
            }
           });
      });
      
      console.log("Totalss SUM")
      console.log(totals_sum)
      // order the dictionary in the name order as the colnames
      var parse = d3.format(".0s");
      ave_array = [];
      colnames.forEach(function(k) {
        if (! _.isString(totals[k])) { // need to append the string sum/mean to the ave_array, which will be displayed in the Big data table header
            // if there is no sum available for that column, then just store  
            if(isNaN(totals_sum[k])){
                sum_mean_str = parse(totals[k])
            }else{
                sum_mean_str = parse(totals_sum[k]) + ": "+ parse(totals[k])
            }
            ave_array.push(sum_mean_str);
        }else{
          // this is a string column, so we store the MODE int the ave_array
          ave_array.push(totals[k]);
        }
      });
      // if no rows are selected, then display the cluster data
      if( n==0) {
          data_table_clusters(cluster_data); // cluster_data is being passed from server.r 
          
      }
      else{
          shuffled_data = _.shuffle(selected);
          // data_table creates the list of names and also the grid table at the bottom of page
          data_table(shuffled_data, ave_array);
      }
      ctx.clearRect(0,0,w+1,h+1);
      
      // render all lines until finished or a new brush event
      function animloop(){
        
        
        if (i >= n || count < brush_count) return true;
        var max = d3.min([i+render_speed, n]);
        render_range(shuffled_data, i, max, opacity); // this calls the path()
        render_stats(max,n,render_speed);
        i = max;
        timer = optimize(timer);  // adjusts render_speed
      };
      // if no brush selection, then draw means
      if(n==0){
          cluster_data.forEach(function(d) {
              path(d, foreground, color(d.group,opacity), dash=1);
          });
          
      }else{
          d3.timer(animloop);
      }
    }
    
    // transition ticks for reordering, rescaling and inverting
    function update_ticks(d, extent) {
      // update brushes
      if (d) {
        var brush_el = d3.selectAll(".brush")
        .filter(function(key) { return key == d; });
        // single tick
        if (extent) {
          // restore previous extent
          brush_el.call(yscale[d].brush = d3.svg.brush().y(yscale[d]).extent(extent).on("brush", brush));
        } else {
          brush_el.call(yscale[d].brush = d3.svg.brush().y(yscale[d]).on("brush", brush));
        }
      } else {
        // all ticks
        d3.selectAll(".brush")
        .each(function(d) { d3.select(this).call(yscale[d].brush = d3.svg.brush().y(yscale[d]).on("brush", brush)); })
      }
      
      brush_count++;
      
      // update axes
      d3.selectAll(".axis")
      .each(function(d,i) {
        // hide lines for better performance
        d3.select(this).selectAll('line').style("display", "none");
        
        // transition axis numbers
        d3.select(this)
        .transition()
        .duration(720)
        .call(axis.scale(yscale[d]));
        
        // bring lines back
        d3.select(this).selectAll('line').transition().delay(800).style("display", null);
        
        d3.select(this)
        .selectAll('text')
        .style('font-weight', null)
        .style('font-size', null)
        .style('display', null);
      });
    }
  
    // Rescale to new dataset domain when you click Keep or Exclude
    function rescale() {
      // reset yscales, preserving inverted state
      dimensions.forEach(function(d,i) {
        //if scale is inverted, then apply either an ordinal or linear scale
        if (yscale[d].inverted) {
          // if dimension is string then make sure y scale is ordinal
          if(_.isString(data[0][d])){
            yscale[d] = d3.scale.ordinal()
            .domain(data.map( function(p) { return p[d]; }))
            //.domain(d3.extent(data, function(d) { return d[k]; }))
            .rangePoints([h, 0],1);   
          }
          else{
            yscale[d] = d3.scale.linear()
            .domain(d3.extent(data, function(p) { return +p[d]; }))
            .range([h, 0]);
          }
          yscale[d].inverted = true;
          
        } else { // not inverted dimension
          // if dimension is string then make sure y scale is ordinal
          if(_.isString(data[0][d])){
            yscale[d] = d3.scale.ordinal()
            .domain(data.map( function(p) { return p[d]; }))
            //.domain(d3.extent(data, function(d) { return d[k]; }))
            .rangePoints([h, 0],1);   
          }
          else{
            yscale[d] = d3.scale.linear()
            .domain(d3.extent(data, function(p) { return +p[d]; }))
            .range([h, 0]);
          }
        }
      });
      
      update_ticks();
      
      // Render selected data
      paths(data, foreground, brush_count);
    }
    
    // Get polylines within extents
    function actives() {
      var actives = dimensions.filter(function(p) { return !yscale[p].brush.empty(); }),
      extents = actives.map(function(p) { return yscale[p].brush.extent(); });
      
      // filter extents and excluded groups
      var selected = [];
      data
      .filter(function(d) {
        return !_.contains(excluded_groups, d.group);
      })
      .map(function(d) {
        return actives.every(function(p, i) {
          return extents[i][0] <= d[p] && d[p] <= extents[i][1];
        }) ? selected.push(d) : null;
      });
      
      // free text search
      var query = d3.select("#search")[0][0].value;
      if (query > 0) {
        selected = search(selected, query);
      }
      
      return selected;
    }
    
    // Export data
    function export_csv() {
      var keys = d3.keys(data[0]);
      var rows = actives().map(function(row) {
        return keys.map(function(k) { return row[k]; })
      });
      var csv = d3.csv.format([keys].concat(rows)).replace(/\n/g,"<br/>\n");
      var styles = "<style>body { font-family: sans-serif; font-size: 12px; }</style>";
      window.open("text/csv").document.write(styles + csv);
    }
    
    // scale to window size
    window.onresize = function() {
      width = document.body.clientWidth,
      height = d3.max([document.body.clientHeight-370, 220]);
      
      w = width - m[1] - m[3],
      h = height - m[0] - m[2];
      
      fisheye.domain([0,w]);
      
      d3.select("#chart")
      .style("height", (h + m[0] + m[2]) + "px")
      
      d3.selectAll("canvas")
      .attr("width", w)
      .attr("height", h)
      .style("padding", m.join("px ") + "px");
      
      d3.select("svg")
      .attr("width", w + m[1] + m[3])
      .attr("height", h + m[0] + m[2])
      .select("g")
      .attr("transform", "translate(" + m[3] + "," + m[0] + ")");
      
      xscale = d3.scale.ordinal().rangePoints([0, w], 1).domain(dimensions);
      dimensions.forEach(function(d) {
        if(_.isString(data[0][d])){
          yscale[d].rangePoints([h, 0],1);   
        }else{
          yscale[d].range([h, 0]);
        }
      });
      
      d3.selectAll(".dimension")
      .attr("transform", function(d) { return "translate(" + fisheye(xscale(d)) + ")"; })
      // update brush placement
      d3.selectAll(".brush")
      .each(function(d) { d3.select(this).call(yscale[d].brush = d3.svg.brush().y(yscale[d]).on("brush", brush)); })
      brush_count++;
      
      // update axis placement
      axis = axis.ticks(1+height/50),
      d3.selectAll(".axis")
      .each(function(d) { d3.select(this).call(axis.scale(yscale[d])); });
      
      // render data
      brush();
    };
    
    // Remove all but selected from the dataset
    function keep_data() {
      new_data = actives();
      if (new_data.length == 0) {
        alert("I don't mean to be rude, but I can't let you remove all the data.\n\nTry removing some brushes to get your data back. Then click          'Keep' when you've selected data you want to look closer at.");
        return false;
      }
      data = new_data;
      rescale();
    }
    
    // function to reset the data to orig order
    function reset_order() {
      
      // reset the svg element- the whole parallel coords chart
      d3.selectAll('svg > g > *').remove();
      // reload page with the orig_data
      initial(cluster_aves, is_ctrl)
    }
    
    
    // function to toggle the CTRL scrolling for touch screens
    function toggle_scroll() {
      
      // toggle control 
      if(is_ctrl == 1){
          is_ctrl = 0;
        } else {
          is_ctrl = 1;
        }
    }
    
    // Exclude selected from the dataset
    function exclude_data() {
      new_data = _.difference(data, actives());
      if (new_data.length == 0) {
        alert("I don't mean to be rude, but I can't let you remove all the data.\n\nTry selecting just a few data points then clicking 'Exclude'         .");
        return false;
      }
      data = new_data;
      rescale();
    }
    
    function remove_axis(d,g) {
      dimensions = _.difference(dimensions, [d]);
      xscale.domain(dimensions);
      g.attr("transform", function(p) { return "translate(" + position(p) + ")"; });
      g.filter(function(p) { return p == d; }).remove(); 
      update_ticks();
    }
    
    d3.select("#keep-data").on("click", keep_data);
    d3.select("#exclude-data").on("click", exclude_data);
    d3.select("#export-data").on("click", export_csv);
    d3.select("#search").on("keyup", brush);
    d3.select("#orig_order").on("click", reset_order);
    d3.select("#control_scroll").on("click", toggle_scroll);
    d3.select("#unselect-all").on("click", unselectAll);
    d3.select("#select-all").on("click", selectAll);
    
    // Appearance toggles
    d3.select("#hide-ticks").on("click", hide_ticks);
    d3.select("#show-ticks").on("click", show_ticks);
    d3.select("#dark-theme").on("click", dark_theme);
    d3.select("#light-theme").on("click", light_theme);
    
    
    function unselectAll() {
      excluded_groups = _.keys(colors);
      d3.selectAll("#select-all").attr("style", "display:block");
      d3.selectAll("#unselect-all").attr("style", "display:none");
      brush();
    }
    
    function selectAll() {
      excluded_groups = [];
      d3.selectAll("#select-all").attr("style", "display:none");
      d3.selectAll("#unselect-all").attr("style", "display:block");
      brush();
    }
    
    
    
    function hide_ticks() {
      d3.selectAll(".axis g").style("display", "none");
      //d3.selectAll(".axis path").style("display", "none");
      d3.selectAll(".background").style("visibility", "hidden");
      d3.selectAll("#hide-ticks").attr("disabled", "disabled");
      d3.selectAll("#show-ticks").attr("disabled", null);
    };
    
    function show_ticks() {
      d3.selectAll(".axis g").style("display", "inline");
      //d3.selectAll(".axis path").style("display", null);
      d3.selectAll(".background").style("visibility", null);
      d3.selectAll("#show-ticks").attr("disabled", "disabled");
      d3.selectAll("#hide-ticks").attr("disabled", null);
    };
    
    function dark_theme() {
      d3.select('#gene_table_filter').style('color', "#e3e3e3")
      d3.select("body").attr("class", "dark");
      d3.selectAll("#dark-theme").attr("disabled", "disabled");
      d3.selectAll("#light-theme").attr("disabled", null);
    }
    
    function light_theme() {
      d3.select('#gene_table_filter').style('color', "#404040")
      d3.select("body").attr("class", null);
      d3.selectAll("#light-theme").attr("disabled", "disabled");
      d3.selectAll("#dark-theme").attr("disabled", null);
    }
    
    function search(selection,str) {
      pattern = new RegExp(str,"i")
      return _(selection).filter(function(d) { return pattern.exec(d.name); });
    }
  }) // end read csv
} //end initial()


