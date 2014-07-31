<h2>Map of Open Tickets</h2>

{literal} 

<link rel="stylesheet" href="http://cdn.leafletjs.com/leaflet-0.7.3/leaflet.css" />
<script src="http://cdn.leafletjs.com/leaflet-0.7.3/leaflet.js"></script>
<script src="//cdnjs.cloudflare.com/ajax/libs/underscore.js/1.6.0/underscore-min.js"></script>
<script src="http://crypto-js.googlecode.com/svn/tags/3.0.2/build/rollups/md5.js"></script>

<div id="map" class="map" style="height:400px;width:800px;"></div>


<script language="JavaScript">
    // create a map in the "map" div, set the view to a given place and zoom
var map = L.map('map').setView([47.611171, -122.326182], 15);

    // add an OpenStreetMap tile layer
    L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png', {
        attribution: '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'
    }).addTo(map);

    var vtigerUrl = "/webservice.php"
	var sessionId;

    var callApi = function(type, operation, data, callback)
    {
        var params = data || {};
	    params.operation = operation;
        
        if(sessionId)
        {
        	params.sessionName = sessionId;
        }

        if(type === "GET")
        {

	        jQuery.ajax({
	                    url:vtigerUrl + "?"+ $.param(params),
	                    type:"GET",
	                    success:callback});
	    }
	    else
	    {
	    	params.operation = operation;
	    	jQuery.ajax({
	                    url:vtigerUrl,
	                    data:params,
	                    type:"POST",
	                    success:callback});
	    }
    };

    var renderedTickets = {};
    var lastModified;
    var renderedTicketMarkers = [];

    var checkForTickets = function(){

    	var query = "select * from HelpDesk";

    	if(lastModified)
    	{
    		query += " where modifiedtime > '" + lastModified + "'";
    	}
    	else
    	{
    		query += " where ticketstatus != 'closed'";
    	}

    	query += ";";

        callApi("GET", "query", {query:query}, function(resp){
            _.each(resp.result || [], function(ticket){
            	callApi("GET", "retrieve", {id: ticket.contact_id}, function (resp) {
	                console.log(resp);
	                var contact = resp.result;
	                var address = contact.mailingstreet + " " + contact.mailingcity + " " + contact.mailingstate + " " + contact.mailingzip;
	                
	                // for later comparison in case it changes
	                ticket.fullAddress = address;
	                var markerContent = contact.lastname + "," + contact.firstname + "<br/>" + ticket.ticket_title + " (" + ticket.ticketstatus + ")";

	                    
	                if(!_.has(renderedTickets,ticket.id) || renderedTickets[ticket.id].fullAddress !== address)
	                {
	                    jQuery.ajax(
	                            {url: "http://nominatim.openstreetmap.org/search?q=" + address + "&format=json",
	                                success: function (resp)
	                                {
	                                    if (resp && resp.length > 0)
	                                    {
	                                        console.log("Gepc", resp);
	                                        var marker = renderedTicketMarkers[ticket.id];
	                                        
	                                        if(marker)
	                                        {
	                                        	market.setLatLng([resp[0].lat, resp[0].lon]);
	                                        	marker.setPopupContent(markerContent);
	                                        }
	                                        else
	                                        {
	                                        	marker = L.marker([resp[0].lat, resp[0].lon]).addTo(map)
	                                        				.bindPopup(markerContent)
	                                        				.openPopup();
	                                        }

	                                        renderedTickets[ticket.id] = ticket;
	                                        renderedTicketMarkers[ticket.id] = marker;
	                                    }

	                                }
	                            }
	                    );
	                }
	                else
	                {
	                	// possible remove
	                	if(ticket.ticketstatus === "Closed")
	                	{
	                		map.removeLayer(renderedTicketMarkers[ticket.id]);
	                	}
	                	else
	                	{
	                		// could chang the color/icon/etc on status update
	                		renderedTicketMarkers[ticket.id].setPopupContent(markerContent);
	                	}
	                }

	                if(!lastModified || Date.parse(ticket.modifiedtime).getTime() > Date.parse(lastModified))
	                {
	                	lastModified = ticket.modifiedtime;
	                }
	            });
            });
        });
    };
    
    // extend the user's VTiger Session for webservices
    callApi("POST","extendsession",{},function(resp){
    	console.log("Extend session ", resp);
    	if(resp.result && resp.result.sessionName)
    	{
    		sessionId = resp.result.sessionName;
    		// being checking for tickets
	    	setInterval(function(){
		        checkForTickets();
		    }, 15000);

		    checkForTickets();
    	}
    	else{
	    	alert("unable to start webservice session:"+(result && result.error && result.error.message));
	    }
    });
	 
</script>

{/literal} 