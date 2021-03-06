d3.divgrid = function(config) {
  var columns = [];

  var dg = function(selection) {
    
    selection_data = selection.data()[0];
    
    // filter the selection data to get the columns to output in the table
    list_dimensions = d3.keys(selection.data()[0][0]).slice(1,5)
    list_dimensions.push('group') //add group so that cluster can be highlighted
      
    if (columns.length == 0) columns = list_dimensions;

    // header
    selection.selectAll(".header")
        .data([true])
      .enter().append("div")
        .attr("class", "header")

    var header = selection.select(".header")
      .selectAll(".cell")
      .data(columns);

    header.enter().append("div")
      .attr("class", function(d,i) { return "col-" + i; })
      .classed("cell", true)

    selection.selectAll(".header .cell")
      .text(function(d) { return d; });

    header.exit().remove();

    // rows
    var rows = selection.selectAll(".row-grid")
        .data(function(d) { return d; })

  console.log("divgrid rows")
  console.log(rows)

    rows.enter().append("div")
        .attr("class", "row-grid")

    rows.exit().remove();

    var cells = selection.selectAll(".row-grid").selectAll(".cell")
        .data(function(d) { return columns.map(function(col){return d[col];}) })

    // cells
    cells.enter().append("div")
      .attr("class", function(d,i) { return "col-" + i; })
      .classed("cell", true)

    cells.exit().remove();

    selection.selectAll(".cell")
      .text(function(d) { return d; });

    return dg;
  };

  dg.columns = function(_) {
    if (!arguments.length) return columns;
    columns = _;
    return this;
  };

  return dg;
};