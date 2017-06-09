function makeTable() {
  
	var data, sort_by, filter_cols; // Customizable variables
	
	var table; // A reference to the main DataTable object
	
	// This is a custom event dispatcher.
	var dispatcher = d3.dispatch('highlight');
	
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
	  
	  var colnames = ['name','Wallet Share last4FY Tot %','Wallet last4FY Tot avg','Wallet FY17 Tot',
             'Wallet Share last4FY EntNet %','Wallet Share last4FY DC %',
             'Wallet Share last4FY Secur %',
             'Wallet Share last4FY Collab %',
             'Wallet Share last4FY Svcs %','group'];
	  
		if(typeof filter_cols !== 'undefined'){
			// If we have filtered cols, remove them.
			colnames = colnames.filter(function (e) {
				// An index of -1 indicate an element is not in the array.
				// If the col_name can't be found in the filter_col array, retain it.
				return filter_cols.indexOf(e) < 0;
			});
		}
		
		
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

      var clonedData= JSON.parse(JSON.stringify(data));
      
      clonedData.forEach(function(p) {
            p['Wallet Share last4FY Tot %'] = parse(+p['Wallet Share last4FY Tot %']);
            p['Wallet last4FY Tot avg'] =  parse(parseFloat(p['Wallet last4FY Tot avg']));
            p['Wallet FY17 Tot'] =  parse(parseFloat(p['Wallet FY17 Tot'])); 
            p['Wallet Share last4FY EntNet %'] =  parse(parseFloat(p['Wallet Share last4FY EntNet %']));
            p['Wallet Share last4FY DC %'] =  parse(parseFloat(p['Wallet Share last4FY DC %']));
            p['Wallet Share last4FY Secur %'] =  parse(parseFloat(p['Wallet Share last4FY Secur %']));
            p['Wallet Share last4FY Collab %'] =  parse(parseFloat(p['Wallet Share last4FY Collab %']));
      });
      
      
	    table = $('#gene_table').DataTable({
				// Here, I am supplying DataTable with the data to fill the table.
				// This is more efficient than supplying an already contructed table.
				// Refer to http://datatables.net/manual/data#Objects for details.
	      data: clonedData, 
	      columns: colnames.map(function(e) { return {data: e}; }),
	      "bLengthChange": false, // Disable page size change
	      "bDeferRender": true,
	      //"bAutoWidth": false,
	      "order": sort_by
	    });
	    
	    $("#gene_table_wrapper").css("width","100%");
	    $('#gene_table_filter').css("float","left");
	    
	    if( $('body').hasClass('dark') ) {
           d3.select('#gene_table_filter').style('color', "#e3e3e3")
      } else {
           
           d3.select('#gene_table_filter').style('color', "#404040")
      }
	   
	    // add another header row to the table that included aggregate sums or means or both of the columns
	    var col2 = 0;
	    var col3 = 0;
	    var col4 = 0;
	    var col5 = 0;
	    var col6 = 0;
	    var col7 = 0;
	    var col8 = 0;
	    var col9 = 0;
	    col10 = [];
      data.map(function(p,i) {
             col2 +=  parseFloat(p['Wallet Share last4FY Tot %']);
             col3 +=  parseFloat(p['Wallet last4FY Tot avg']);
             col4 +=  parseFloat(p['Wallet FY17 Tot']);
             col5 +=  parseFloat(p['Wallet Share last4FY EntNet %']);
             col6 +=  parseFloat(p['Wallet Share last4FY DC %']);
             col7 +=  parseFloat(p['Wallet Share last4FY Secur %']);
             col8 +=  parseFloat(p['Wallet Share last4FY Collab %']);
             col9 +=  parseFloat(p['Wallet Share last4FY Svcs %']);
             col10.push(p['group'])
             
      });
	    // some of the columns are averages especially if a percent
	    dl = data.length;
	    col2 = col2/dl;
	    col5 = col5/dl;
	    col6 = col6/dl;
	    col7 = col7/dl;
	    col8 = col8/dl;
	    col9 = col9/dl;
	    var col3_ave = parse(col3/dl); // this is the sum for col3
	    var col4_ave = parse(col4/dl); // this is the sum for col4
	    // get the most common group: the mode
	    function length(a) { return a.length; }
	    groups = _.groupBy(col10)
      max_group = _.max(groups, length)
	    
	    mode_grp = max_group[0]
	    
	    colnames2 = ['Total Sum/Mean','/'+parse(col2), parse(col3)+'/'+ col3_ave, parse(col4)+'/'+col4_ave, '/'+parse(col5)
	                ,'/'+parse(col6),'/'+ parse(col7), '/'+ parse(col8), '/'+parse(col9),'Mode:'+mode_grp]
	    
	    // this will have the sums/ave for the columns
	    headSelect.append("tr").style("font-weight", "bold")
                	   .selectAll('td')
                	   .data(colnames2).enter()
                		 .append('td')
                		 .html(function(d) { return d; });
	    
	
	    tableSelect.style("visibility", "visible");
	    $('#gene_table tbody')
        .on( 'mouseover', 'tr', function () { highlight(this, true); } )
        .on( 'mouseleave', 'tr', function () { highlight(this, false); } );
      
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
