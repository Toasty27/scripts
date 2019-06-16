////
// USER VARIABLES
////

// Set badge sizes
var badgeSizes = [72, 36, 18];


///
// SCRIPT VARIABLES
////

var doc = app.activeDocument

// Get a reference to our current history state
var originState = doc.activeHistoryState

// Set units to Pixels
var originalRulerUnits = app.preferences.rulerUnits
app.preferences.rulerUnits = Units.PIXELS

var docPath = doc.path
//alert ("Document Path: " + docPath)


////
// FUNCTIONS
////

function resizeBadges(docRef, size) {
	docRef.resizeImage(size,size)
}

// Saves each layer as PNG individually
function saveBadges(docRef, size)
{
	for (var layerIndex = 0; layerIndex < docRef.artLayers.length; layerIndex++)
	{
		var eachLayer = docRef.artLayers[layerIndex]
		eachLayer.visible = true

		// Export as PNG
		fileName = eachLayer.name
		pngFile = new File( docPath + "/" + fileName + "_" + size + ".png" )
		pngSaveOptions = new PNGSaveOptions()
		pngSaveOptions.compression = 0
		pngSaveOptions.interlaced = false
		doc.saveAs(pngFile, pngSaveOptions, true, Extension.LOWERCASE)

		eachLayer.visible = false
	}
}


////
// MAIN
////
function main() {
	// Set all layers invisible
	for (var layerIndex = 0; layerIndex < doc.artLayers.length; layerIndex++)
	{
		var eachLayer = doc.artLayers[layerIndex]
		eachLayer.visible = false
	}

	// Save state so we can revert to full size for each pass
	var savedState = doc.activeHistoryState

	// Make badges for all sizes
	for (var i = 0; i < badgeSizes.length; i++) 
	{
		var badgeSize = badgeSizes[i]
		resizeBadges(doc, badgeSize)
		saveBadges(doc, badgeSize)

		doc.activeHistoryState = savedState
	}
}

main()

// Restore ruler preferences
app.preferences.rulerUnits = originalRulerUnits

// Restore document to pre-script state
doc.activeHistoryState = originState