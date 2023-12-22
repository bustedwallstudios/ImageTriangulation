extends Node

# Returns an array of triangles
func triangulation(points:Array, sideLength:float, shape:int=1) -> Array:
	var triangles = []
	
	var lengthVec := Vector2(sideLength + 0.5, 0)
	
	for point in points:
		match shape:
			0:
				var tris = getTris(point, lengthVec)
				triangles.append_array(tris)
			
			1:
				var hex = getHex(point, lengthVec)
				
				triangles.append(hex)
	
	print("Done triangulating this segment!")
	
	get_tree().current_scene.drawPolygons(triangles)
	
	return triangles

func getTris(point:Vector2, lengthVec:Vector2):
	var t1v1 = point
	var t1v2 = point + lengthVec
	var t1v3 = point + lengthVec.rotated(TAU/6.0)
	var t1:Array = [t1v1, t1v2, t1v3]
	
	var t2v1 = point
	var t2v2 = point + lengthVec.rotated(TAU/6.0)
	var t2v3 = point + lengthVec.rotated((TAU/6.0) * 2)
	var t2:Array = [t2v1, t2v2, t2v3]
	
	return [t1, t2]

func getHex(point:Vector2, lengthVec:Vector2):
	var hex := []
	
	for i in range(0, 6):
		var deg:float = (TAU * (i/6.0)) + TAU/12.0
		var mag:float = (lengthVec.length() * sqrt(3))/3.0
		var p = point + lengthVec.normalized().rotated(deg) * mag
		
		hex.append(p)
	
	return hex
