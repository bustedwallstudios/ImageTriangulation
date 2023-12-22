extends Node

# Returns an array of triangles
func triangulation(points:Array) -> Array:
	var triangles = []
	var rowCount = int(sqrt(points.size()))  # Assuming a square grid
	
	for y in range(rowCount - 1):
		for x in range(rowCount - 1):
			var baseIndex = y * rowCount + x
			
			# Define the vertices of the two triangles in each grid cell
			var v1 = points[baseIndex]
			var v2 = points[baseIndex + 1]
			var v3 = points[baseIndex + rowCount]
			
			var v4 = points[baseIndex + 1]
			var v5 = points[baseIndex + rowCount]
			var v6 = points[baseIndex + rowCount + 1]
			
			# Append triangles to the list
			triangles.append([v1, v2, v3])
			triangles.append([v4, v5, v6])
	
	return triangles
