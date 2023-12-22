extends Node

func triangulation(points:PackedVector2Array):
	# The list of current triangles that are inside the polygon. Starts at zero,
	# and triangles are added and removed over the course of this algorithm.
	var triangles:Array = []
	
	# The bounding box of the polygon
	var boundingBox:Rect2 = getBoundingBox(points)
	
	# The smallest (but not with my algorithm) triangle that encompasses the
	# entire triangle.
	var superTriangle:Array = getSuperTriangle(boundingBox)
	triangles.append(superTriangle)
	
	# number of complete triangles
	#var completedPoints:int = 0
	#var totalPoints:int = len(points)
	#var progress:float = 0
	
	# One at a time, integrate all the points into the triangulation.
	for point in points:
		var badTriangles:Array = []
		
		for thisTriangle in triangles:
			#var thisTriPos:Vector2 = thisTriangle[0]
			#var distance:float     = thisTriPos.distance_to(point)
			
			# If the point is inside the circumcircle of this triangle, then it
			# is not a valid Delaunay Triangulation. Thus, this triangle is bad.
			if inCircumcircleOf(thisTriangle, point):
				
				badTriangles.append(thisTriangle)
		
		# The edges of the polygon that delineates the hole that will be created
		# by removing the bad triangles.
		var polygonEdges:Array = []
		
		# All of the edges in the bad triangles
		var badEdges:Array = []
		
		# Loop over all the bad triangles, and add each of their edges to the list.
		# This will contain all edges, and whichever ones are NOT duplicates 
		# are going to be added to the polygonEdges.
		for badTriangle in badTriangles:
			for edgeIdx in range(0, 3):
				var edge:Array = []
				
				edge.append(badTriangle[edgeIdx])
				edge.append(badTriangle[(edgeIdx+1)%3]) # For the last edge, use vertex 0 again.
				
				badEdges.append(edge)
			
			removeComponentFromArray(badTriangle, triangles)
		
		# Add all non-duplicate edges to the polygonEdges array.
		
		for wrongEdge in badEdges:
			# Count the number of time this edge shows up in the list. 
			var totalCount = 0
			totalCount += badEdges.count(wrongEdge)
			totalCount += badEdges.count([wrongEdge[1], wrongEdge[0]]) # VERY IMPORTANT! ALSO COUNT THE CASES WHERE THE EDGE IS "BACKWARDS" - THE ORDER MAY BE FLIPPED, BUT THE EDGE IS THE SAME!
			
			if totalCount == 1:
				polygonEdges.append(wrongEdge)
		
		for edge in polygonEdges:
			var newTriangle:Array = edge.duplicate()
			newTriangle.append(point)
			
			triangles.append(newTriangle)
		
	# Using the other one directly gets fucky, and doesn't finish iterating.
	var finalTrianglesArray = triangles.duplicate()
	
	# Loop over every triangle, and see if it shares any points with the super
	# triangle - if it does, remove it.
	for triangle in triangles:
		for vertex in superTriangle:
			if vertex in triangle:
				finalTrianglesArray.erase(triangle)
	
	#print(finalTrianglesArray)
	
	get_tree().current_scene.drawTriangles(finalTrianglesArray)

func mergeTriangulations(leftTriangulation: Array, rightTriangulation: Array) -> Array:
	var mergedTriangulation = []  # Initialize the merged triangulation
	
	# Find the lower common tangent between the two triangulations
	var lowerTangent = findLowerTangent(leftTriangulation, rightTriangulation)
	
	# Find the upper common tangent between the two triangulations
	var upperTangent = findUpperTangent(leftTriangulation, rightTriangulation)
	
	# Merge the triangulations using the common tangents
	var lIndex = leftTriangulation.find(lowerTangent[0])
	var rIndex = rightTriangulation.find(lowerTangent[1])
	
	while lIndex != leftTriangulation.find(upperTangent[0]):
		mergedTriangulation.append(leftTriangulation[lIndex])
		lIndex = (lIndex + 1) % len(leftTriangulation)
	
	mergedTriangulation.append(leftTriangulation[lIndex])
	
	while rIndex != rightTriangulation.find(upperTangent[1]):
		mergedTriangulation.append(rightTriangulation[rIndex])
		rIndex = (rIndex + 1) % len(rightTriangulation)
	
	mergedTriangulation.append(rightTriangulation[rIndex])
	
	return mergedTriangulation
	
func findLowerTangent(leftTriangulation: Array, rightTriangulation: Array) -> Array:
	var lIndex = 0
	var rIndex = 0
	var done = false
	
	while not done:
		done = true
		# Find the rightmost point of the left triangulation
		var lNext = (lIndex + 1) % len(leftTriangulation)
		
		# Find the leftmost point of the right triangulation
		var rNext = (len(rightTriangulation) + rIndex - 1) % len(rightTriangulation)
		 
		# Check if moving from lIndex to lNext makes a right turn towards rightTriangulation[rNext]
		if determinant_4x4([leftTriangulation[lNext], leftTriangulation[lIndex], rightTriangulation[rNext], leftTriangulation[lIndex]]) > 0:
			lIndex = lNext
			done = false
		 
		# Check if moving from rIndex to rNext makes a left turn towards leftTriangulation[lNext]
		if determinant_4x4([rightTriangulation[rIndex], rightTriangulation[rNext], leftTriangulation[lNext], rightTriangulation[rIndex]]) < 0:
			rIndex = rNext
			done = false

	return [leftTriangulation[lIndex], rightTriangulation[rIndex]]

func findUpperTangent(leftTriangulation: Array, rightTriangulation: Array) -> Array:
	var lIndex = 0
	var rIndex = 0
	var done = false

	while not done:
		done = true
		# Find the rightmost point of the left triangulation
		var lNext = (len(leftTriangulation) + lIndex - 1) % len(leftTriangulation)
		 
		# Find the leftmost point of the right triangulation
		var rNext = (rIndex + 1) % len(rightTriangulation)
		 
		# Check if moving from lIndex to lNext makes a left turn towards rightTriangulation[rNext]
		if determinant_4x4([leftTriangulation[lNext], leftTriangulation[lIndex], rightTriangulation[rNext], leftTriangulation[lIndex]]) < 0:
			lIndex = lNext
			done = false
		 
		# Check if moving from rIndex to rNext makes a right turn towards leftTriangulation[lNext]
		if determinant_4x4([rightTriangulation[rIndex], rightTriangulation[rNext], leftTriangulation[lNext], rightTriangulation[rIndex]]) > 0:
			rIndex = rNext
			done = false

	return [leftTriangulation[lIndex], rightTriangulation[rIndex]]

func dividePoints(points: Array) -> Array:
	# Sort the points based on their x-coordinate
	var sortedPoints:Array = points.duplicate()
	sortedPoints.sort_custom(func(a, b): return a.x < b.x)
	
	# Find the midpoint index
	var midpoint:int = int(len(sortedPoints) / 2.0)
	
	# Divide the points into left and right subsets
	var leftSubset  = sortedPoints.slice(0, midpoint)
	var rightSubset = sortedPoints.slice(midpoint, len(sortedPoints))
	
	return [leftSubset, rightSubset]

# ^ NEW FUNCTIONS FOR DIVIDE AND CONQUER APPROACH ^ ################################################

# Returns whether or not it found (and subsequently removed) the component
func removeComponentFromArray(componentArray:Array, outsideArray:Array) -> bool:
	var requiredMatches = len(componentArray)
	var matchesSeen = 0
	
	# Loop over all the triangles in the outside array
	for subArray in outsideArray:
		matchesSeen = 0
		
		# For each vector2 in the triangle, 
		for ov in subArray:
			# go over each vector2 in the OTHER triangle,
			for iv in componentArray:
				# and check if they're equal.
				if ov == iv:
					# If they are equal, then that's one match closer to being
					# in the outside array. If all of them are equal, it's there.
					matchesSeen += 1
					break # Stop checking this inside vector2. Further matches mean less than nothing.
		
		# If, after looping over every value in both sub arrays, all of them were
		# matches, they were the same!
		if matchesSeen == requiredMatches:
			outsideArray.erase(subArray)
			
			# Component was in the array
			return true
	
	# Component was not in the array
	return false

# Adjusted means that it will extend the bounding box by 10px in all directions,
# to add a little bit of wiggle room.
func getBoundingBox(points, adjusted:bool=true) -> Rect2:
	
	# Can't just initialize these as zero, in case the actual min/max is on
	# the wrong side of zero, and it would never find the actual extreme, and
	# would think that 0 is the extreme, where it could have been constrained more.
	var minX:float = points[0].x
	var minY:float = points[0].y
	var maxX:float = points[0].x
	var maxY:float = points[0].y
	
	# For each point, if any of its coordinates are outside the extremes of the
	# current bounding box, then move the bounding box to be that size.
	for point in points:
		minX = point.x if point.x < minX else minX
		minY = point.y if point.y < minY else minY
		
		maxX = point.x if point.x > maxX else maxX
		maxY = point.y if point.y > maxY else maxY
	
	# The width and height are equal to the difference between the end and the
	# beginning of the box.
	var w:float = maxX - minX
	var h:float = maxY - minY
	
	
	# Add a little bit to the size of the box, in pixels
	var tolerance:float = 5
	if adjusted:
		minX -= tolerance
		minY -= tolerance
		
		# Times two because it has to account for the -10 on the min side, and
		# also add 10 on the max side.
		w += tolerance*2
		h += tolerance*2
	
	var boundingBox:Rect2 = Rect2(minX, minY, w, h)
	
	return boundingBox

# A right triangle that starts at the top left corner of the bounding box, and
# extends twice the length and width.
func getSuperTriangle(box:Rect2) -> Array:
	
	var p1:Vector2 = box.position - Vector2(box.size.x*0.5, 0)
	var p2:Vector2 = box.position + Vector2(box.size.x*1.5, 0)
	var p3:Vector2 = box.position + Vector2(box.size.x*0.5, box.size.y*2)
	
	var superTriangle:Array = [p1, p2, p3]
	
	return superTriangle

# Written by ChatGPT4
func inCircumcircleOf(triangle:Array, P:Vector2):
	
	var matrix:Array = buildMatrixFromTriangleAndPoint(triangle, P)
	
	# Calculate the determinant
	var det = determinant_4x4(matrix)
	
	# Interpret the determinant
	# SO LONG AS THE TRIANGLE IS ORDERED COUNTERCLOCKWISE:
	# If determinant is positive, P is inside the circumcircle
	# If determinant is zero, P is on the circumcircle
	# If determinant is negative, P is outside the circumcircle
	if verifyCCW(triangle):
		return det > 0
	else:
		return det < 0

func buildMatrixFromTriangleAndPoint(triangle:Array, P:Vector2) -> Array:
	var A:Vector2 = triangle[0]
	var B:Vector2 = triangle[1]
	var C:Vector2 = triangle[2]
	
	# Construct the matrix
	var matrix:Array = [
		[A.x, A.y, A.x * A.x + A.y * A.y, 1],
		[B.x, B.y, B.x * B.x + B.y * B.y, 1],
		[C.x, C.y, C.x * C.x + C.y * C.y, 1],
		[P.x, P.y, P.x * P.x + P.y * P.y, 1]
	]
	
	return matrix

# Function to calculate the determinant of a 4x4 matrix
# Written by ChatGPT 4
func determinant_4x4(mat:Array) -> float:
	
	# Initialize the determinant to 0
	var det:float = 0.0
	
	# Loop over the first row
	for i in range(4):
		
		# Create a sub-matrix for the minor
		var sub_mat = []
		
		for j in range(1, 4):
			var row = []
			
			for k in range(4):
				if k != i:
					row.append(mat[j][k])
			
			sub_mat.append(row)
		
		# Calculate the minor
		var minor = determinant_3x3(sub_mat)
		
		# Calculate cofactor
		var cofactor = (-1 if i % 2 else 1) * minor
		
		# Add to the total determinant
		det += mat[0][i] * cofactor
	
	return det

# Function to calculate the determinant of a 3x3 matrix (helper function for the 4x4 version)
# Written by ChatGPT 4
func determinant_3x3(mat:Array) -> float:
	return mat[0][0] * (mat[1][1] * mat[2][2] - mat[1][2] * mat[2][1]) \
		 - mat[0][1] * (mat[1][0] * mat[2][2] - mat[1][2] * mat[2][0]) \
		 + mat[0][2] * (mat[1][0] * mat[2][1] - mat[1][1] * mat[2][0])

# Returns true if a triangle's points are (correctly) arranged in
# counterclockwise order.
func verifyCCW(triangle:Array) -> bool:
	var a = triangle[0]
	var b = triangle[1]
	var c = triangle[2]
	
	return (b.x - a.x) * (c.y - a.y) - (c.x - a.x) * (b.y - a.y) > 0
