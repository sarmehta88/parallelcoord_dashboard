function makeTable2(totals) {
  
	var data, sort_by, filter_cols; // Customizable variables
	
	var table; // A reference to the main DataTable object
	
	// This is a custom event dispatcher.
	var dispatcher = d3.dispatch('select');
	
	// Main function, where the actual plotting takes place.
	function _table(targetDiv) {
	  
	  // Create and select table skeleton
	  var tableSelect = targetDiv.append("table")
	    .attr("class", "display compact")
			// Generally, hard-coding Ids is wrong, because then 
			// you can't have 2 table plots in one page (both will have the same id).
			// I will leave it for now for simplicity. TODO: remove hard-coded id.
	    .attr("id", "gene_table")
	    .style("visibility", "hidden"); // Hide table until style loads;
			
	  if(data[0] == null){
	      return _table;
	  }
	  var colnames = d3.keys(data[0]);
		// Here I initialize the table and head only. 
		// I will let DataTables handle the table body.
	  var headSelect = tableSelect.append("thead");
	                   headSelect.append("tr")
                	   .selectAll('td')
                	   .data(colnames).enter()
                		 .append('td')
                		 .html(function(d) { return d; });
   

		if(typeof sort_by !== 'undefined'){
			// if we have a sort_by column, format it according to datatables.
			sort_by[0] = colnames.indexOf(sort_by[0]); //colname to col idx
			sort_by = [sort_by]; //wrap it in an array
		}
		
	  // Apply DataTable formatting: https://www.datatables.net/
	  $(document).ready(function() {
	    // if table is init then destroy before creating a new one
      if ($.fn.DataTable.isDataTable("#gene_table")) {
            $('#gene_table').DataTable().clear().destroy();
      }
      var parse = d3.format(".0s");	
      i = 0
      num_columns = []
      // Collect the columns with quantitative scales 
      colnames.forEach(function(k) {
        if(! _.isString(data[1][k]) && k!= "SAVID"){
            num_columns.push(i);
        }
        i +=1
      });  
      
	    table = $('#gene_table').DataTable({
				// Here, I am supplying DataTable with the data to fill the table.
				// This is more efficient than supplying an already contructed table.
				// Refer to http://datatables.net/manual/data#Objects for details.
	      data: data, 
	      columns: colnames.map(function(e) { return {data: e}; }),
	      "aoColumnDefs": [{
            "mRender": function (num, type, row) {
                    //return Math.round(num * 100) / 100;
                    return num;
              },
            "aTargets": num_columns,
            "fnCreatedCell": function (nTd, sData, oData, iRow, iCol) {
                // change the raw data numbers to rounded numbers with suffix like k,M,B
                var $dataCell = $(nTd);
                var rn = parse(parseFloat($dataCell.text()));
                $dataCell.text(rn);
            }
        }],
	      "scrollX": true,
	      "bLengthChange": false, // Disable page size change
	      "bDeferRender": true,
	      "searching": false,
	      "order": sort_by
	    });
	    
	     // this will have the sums/ave for the columns
	     headSelect.append("tr").style("font-weight", "bold").style("font-size", "9px")
                	   .selectAll('td')
                	   .data(totals).enter()
                		 .append('td')
                		 .html(function(d) { return d; });
                		 
	    $("#gene_table_wrapper").css("width","100%");
	    $('#gene_table_filter').css("float","left");
	    $('thead').css("visibility","visible");
	    
	    if( $('body').hasClass('dark') ) {
           d3.select('#gene_table_filter').style('color', "#e3e3e3")
      } else {
           d3.select('#gene_table_filter').style('color', "#404040")
      }
	   
	    tableSelect.style("visibility", "visible");
	    
	    $('#gene_table tbody')
        .on('click', 'tr', function () { select(this); });
      
	  });	// end on page load
	  
	} // end table function
  
	/**** Helper functions to highlight and select data **************/
	function highlight(row, on_off) {
		if(typeof on_off === 'undefined'){
			// if on_off is not provided, just toggle class.
			on_off = !d3.select(row).classed('highlight');
		}
		// Set the row's class as highlighted if on==true,
		// Otherwise remove the 'highlighted' class attribute.
		// In DataTables, this is handled automatically for us.
		d3.select(row).classed('highlight', on_off);
		
		// Fire a highlight event, with the data and highlight status.
		dispatcher.highlight(table.rows(row).data()[0], on_off);
	}
	function select(row, on_off) {
		// Similar to highlight function.
		if(typeof on_off === 'undefined'){
			on_off = !d3.select(row).classed('selected');
		}
		
		d3.select(row).classed('selected', on_off);	
		
		// Fire a select event, with the data and selected status.
		dispatcher.select(table.rows(row).data()[0], on_off);
	}
	
	/**** Setter / getters functions to customize the table plot *****/
	_table.datum = function(_){
	  
    if (!arguments.length) {return data;}
    data = _;
  
    return _table;
	};
	_table.filterCols = function(_){
    if (!arguments.length) {return filter_cols;}
    filter_cols = _;
    
    return _table;
	};
	_table.sortBy = function(colname, ascending){
    if (!arguments.length) {return sort_by;}
    
		sort_by = [];
		sort_by[0] = colname;
		sort_by[1] = ascending ? 'asc': 'desc';
    
    return _table;
	};
	
	
	// This allows other objects to 'listen' to events dispatched by the _table object.
	d3.rebind(_table, dispatcher, 'on');
	
	// This is the return of the main function 'makeTable'
	return _table;
} // end makeTable()
