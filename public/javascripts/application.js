/***
 * Excerpted from "Advanced Rails Recipes",
 * published by The Pragmatic Bookshelf.
 * Copyrights apply to this code. It may not be used to create training material, 
 * courses, books, articles, and the like. Contact us if you are in doubt.
 * We make no guarantees that this code is fit for any purpose. 
 * Visit http://www.pragmaticprogrammer.com/titles/fr_arr for more book information.
***/
function initialize() { 
  if (GBrowserIsCompatible() && typeof vendors != 'undefined') {
    var map = new GMap2(document.getElementById("map"));
    map.setCenter(new GLatLng(37.4419, -122.1419), 13);
    map.addControl(new GLargeMapControl());
  
    // Clicking the marker will hide it
    function createMarker(latlng, vendor) {
      var marker = new GMarker(latlng);
      var html="<strong>"+vendor.name+"</strong><br />"+vendor.address;
      GEvent.addListener(marker,"click", function() {
        map.openInfoWindowHtml(latlng, html);
      });
      return marker;
    }

    var bounds = new GLatLngBounds;
    for (var i = 0; i < vendors.length; i++) {
      var latlng=new GLatLng(vendors[i].lat,vendors[i].lng)
      bounds.extend(latlng);
      map.addOverlay(createMarker(latlng, vendors[i]));
    }
    map.setCenter(bounds.getCenter(),map.getBoundsZoomLevel(bounds));
  }
}  
window.onload=initialize;
window.onunload=GUnload;