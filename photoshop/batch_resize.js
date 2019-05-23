// docRef = app.activeDocument

// Set badge sizes
var badgeSizes = [72, 36, 18];

// Set units to Pixels
var originalRulerUnits = app.preferences.rulerUnits
app.preferences.rulerUnits = Units.PIXELS

// Set all layers invisible
for (var layerIndex = 0; layerIndex < app.activeDocument.artLayers.length; layerIndex++)
{
	var eachLayer = app.activeDocument.artLayers[layerIndex]
	eachLayer.visible = false
}

// Make badges for all sizes
for (var i = 0; i < badgeSizes.length; i++) 
{
	var badgeSize = badgeSizes[i]
	makeBadge(app.activeDocument, badgeSize)
}

function makeBadge(docRef, size) {
	docRef.resizeImage(size,size)
	saveEachLayer(docRef)
}

// Saves each layer as PNG individually
function saveEachLayer(docRef)
{
	for (var layerIndex = 0; layerIndex < docRef.artLayers.length; layerIndex++)
	{

		var eachLayer = docRef.artLayers[layerIndex]
		eachLayer.visible = true

		// Export as PNG
		pngFile = new File( "/Users/daniel/Temp" + layerIndex + ".png" )
		pngSaveOptions = new PNGSaveOptions()
		pngSaveOptions.compression = 0
		pngSaveOptions.interlaced = false
		app.activeDocument.saveAs(pngFile, pngSaveOptions, true, Extension.LOWERCASE)

		eachLayer.visible = false

	}
}

// Restore ruler preferences
app.preferences.rulerUnits = originalRulerUnits